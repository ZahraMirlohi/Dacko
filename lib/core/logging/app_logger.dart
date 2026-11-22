// lib/core/logging/app_logger.dart
//
// سیستم لاگ مرکزی Dacko.
//  - سطح‌ها: verbose < debug < info < warn < error < fatal
//  - مقصدها (sink): کنسول (فقط دیباگ)، حافظه (حلقه‌ای)، فایل چرخشی JSONL، سرور (Supabase، فقط error به بالا)
//  - خودکار: خطاهای فلاتر، خطاهای async، همهٔ print های قدیمی، چرخهٔ حیات برنامه، کاربر/صفحهٔ جاری
//  - حریم خصوصی: ایمیل، توکن/JWT، شماره تلفن و کلیدهای حساس قبل از ثبت پاک می‌شوند
//    (متن پیام‌های چت را هرگز لاگ نکنید؛ فقط شناسه‌ها).
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum LogLevel { verbose, debug, info, warn, error, fatal }

extension LogLevelX on LogLevel {
  String get short => const ['V', 'D', 'I', 'W', 'E', 'F'][index];
}

const String kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

class LogRecord {
  final int seq;
  final DateTime time; // UTC
  final LogLevel level;
  final String tag;
  final String message;
  final Map<String, Object?>? fields;
  final String? error;
  final String? stack;
  final String sessionId;
  final String? userId;
  final String? screen;

  const LogRecord({
    required this.seq,
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.fields,
    this.error,
    this.stack,
    required this.sessionId,
    this.userId,
    this.screen,
  });

  Map<String, Object?> toJson() => {
        'n': seq,
        't': time.toIso8601String(),
        'lvl': level.name,
        'tag': tag,
        'msg': message,
        if (fields != null && fields!.isNotEmpty) 'f': fields,
        if (error != null) 'err': error,
        if (stack != null) 'st': stack,
        'sid': sessionId,
        if (userId != null) 'uid': userId,
        if (screen != null) 'scr': screen,
      };

  static LogRecord? fromJson(Map<String, dynamic> j) {
    try {
      return LogRecord(
        seq: (j['n'] as num?)?.toInt() ?? 0,
        time: DateTime.parse(j['t'] as String),
        level: LogLevel.values.firstWhere((l) => l.name == j['lvl'], orElse: () => LogLevel.info),
        tag: (j['tag'] as String?) ?? '',
        message: (j['msg'] as String?) ?? '',
        fields: (j['f'] as Map?)?.cast<String, Object?>(),
        error: j['err'] as String?,
        stack: j['st'] as String?,
        sessionId: (j['sid'] as String?) ?? '',
        userId: j['uid'] as String?,
        screen: j['scr'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// ردیف جدول app_logs (sql/17)
  Map<String, Object?> toRemote() => {
        'session_id': sessionId,
        'level': level.name,
        'tag': tag,
        'message': message,
        if (fields != null && fields!.isNotEmpty) 'fields': fields,
        'error': error,
        'stack': stack,
        'screen': screen,
        'app_version': kAppVersion,
        'platform': _platformLabel,
        'client_time': time.toIso8601String(),
        'seq': seq,
      };

  /// یک خط خوانا؛ خطا و استک در خط‌های بعدی
  String toLine() {
    final t = time.toLocal().toIso8601String().substring(11, 23);
    final f = (fields == null || fields!.isEmpty) ? '' : ' ${jsonEncode(fields)}';
    final scr = screen == null ? '' : ' @$screen';
    final b = StringBuffer('$t ${level.short}/$tag$scr  $message$f');
    if (error != null) b.write('\n    ↳ $error');
    if (stack != null) b.write('\n${stack!.split('\n').take(12).map((l) => '      $l').join('\n')}');
    return b.toString();
  }
}

final String _platformLabel =
    kIsWeb ? 'web' : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'.split('\n').first;

// ───────────────────────── پاک‌سازی دادهٔ حساس ─────────────────────────

final _reJwt = RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}');
final _reEmail = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
final _rePhone = RegExp(r'\+?\d[\d\s-]{9,}\d');
final _reKey = RegExp(r'pass|token|secret|authorization|apikey|api_key|anon|jwt|cookie|email|phone', caseSensitive: false);

String _scrub(String s) => s
    .replaceAll(_reJwt, '[jwt]')
    .replaceAll(_reEmail, '[email]')
    .replaceAll(_rePhone, '[phone]');

Object? _scrubValue(Object? v, [int depth = 0]) {
  if (v == null || v is num || v is bool) return v;
  if (v is String) return _scrub(v.length > 600 ? '${v.substring(0, 600)}…' : v);
  if (depth > 3) return '…';
  if (v is Map) {
    return {
      for (final e in v.entries)
        '${e.key}': _reKey.hasMatch('${e.key}') ? '***' : _scrubValue(e.value, depth + 1),
    };
  }
  if (v is Iterable) return v.take(30).map((e) => _scrubValue(e, depth + 1)).toList();
  return _scrub(v.toString());
}

// ───────────────────────── مقصدها ─────────────────────────

abstract class _Sink {
  LogLevel get min;
  void add(LogRecord r);
}

class _ConsoleSink implements _Sink {
  @override
  LogLevel get min => kDebugMode ? LogLevel.verbose : LogLevel.fatal;
  @override
  void add(LogRecord r) {
    if (!kDebugMode) return;
    // Zone.root.print: چاپ واقعی، بدون برگشتن به zone ما (جلوگیری از حلقه)
    Zone.root.print(r.toLine());
  }
}

class _MemorySink implements _Sink {
  final _buf = ListQueue<LogRecord>();
  static const _cap = 1500;
  final version = ValueNotifier<int>(0);
  @override
  LogLevel get min => kReleaseMode ? LogLevel.info : LogLevel.debug;
  @override
  void add(LogRecord r) {
    _buf.addLast(r);
    if (_buf.length > _cap) _buf.removeFirst();
    version.value++;
  }

  List<LogRecord> get all => _buf.toList(growable: false);
  void clear() {
    _buf.clear();
    version.value++;
  }
}

/// فایل چرخشی: dacko.log (فعلی) + dacko.1..3.log، هرکدام حداکثر ~۵۱۲KB
class _FileSink implements _Sink {
  static const _max = 512 * 1024;
  static const _keep = 3;
  Directory? _dir;
  int _size = 0;
  final _buf = StringBuffer();
  Timer? _timer;
  Future<void> _chain = Future.value();

  @override
  LogLevel get min => kReleaseMode ? LogLevel.info : LogLevel.debug;

  Directory? get dir => _dir;
  File _file([int i = 0]) => File('${_dir!.path}/${i == 0 ? 'dacko.log' : 'dacko.$i.log'}');

  Future<void> init() async {
    if (kIsWeb) return;
    final base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/logs');
    await _dir!.create(recursive: true);
    final f = _file();
    _size = await f.exists() ? await f.length() : 0;
  }

  @override
  void add(LogRecord r) {
    if (_dir == null) return;
    _buf.writeln(jsonEncode(r.toJson()));
    if (r.level.index >= LogLevel.error.index) {
      flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 2), flush);
    }
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_dir == null || _buf.isEmpty) return _chain;
    final s = _buf.toString();
    _buf.clear();
    return _chain = _chain.then((_) async {
      try {
        if (_size + s.length > _max) await _rotate();
        await _file().writeAsString(s, mode: FileMode.append);
        _size += s.length;
      } catch (_) {}
    });
  }

  Future<void> _rotate() async {
    try {
      final last = _file(_keep);
      if (await last.exists()) await last.delete();
      for (var i = _keep - 1; i >= 0; i--) {
        final f = _file(i);
        if (await f.exists()) await f.rename(_file(i + 1).path);
      }
    } catch (_) {}
    _size = 0;
  }

  Future<void> clear() async {
    _buf.clear();
    await _chain;
    if (_dir == null) return;
    for (var i = 0; i <= _keep; i++) {
      try {
        final f = _file(i);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _size = 0;
  }

  /// قدیمی → جدید
  Future<List<File>> files() async {
    if (_dir == null) return [];
    await flush();
    final out = <File>[];
    for (var i = _keep; i >= 0; i--) {
      final f = _file(i);
      if (await f.exists()) out.add(f);
    }
    return out;
  }
}

/// ارسال دسته‌ای error/fatal به جدول app_logs (فقط کاربر واردشده).
/// شکست شبکه بی‌صدا نگه داشته می‌شود و با عقب‌نشینی نمایی دوباره تلاش می‌شود.
class _RemoteSink implements _Sink {
  bool enabled = true;
  final _q = <Map<String, Object?>>[];
  Timer? _timer;
  bool _busy = false;
  int _fails = 0;

  @override
  LogLevel get min => enabled ? LogLevel.error : LogLevel.fatal;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void add(LogRecord r) {
    if (!enabled || r.level.index < LogLevel.error.index) return;
    _q.add(r.toRemote());
    if (_q.length > 200) _q.removeAt(0);
    // فوری فقط برای fatal و حداکثر هر ۵ ثانیه؛ بقیه دسته‌ای (۳۰ ثانیه)
    if (r.level == LogLevel.fatal && _fails == 0 && DateTime.now().difference(_last).inSeconds >= 5) {
      flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 30), flush);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_busy || _q.isEmpty) return;
    SupabaseClient client;
    try {
      client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        _later();
        return;
      }
    } catch (_) {
      _later();
      return;
    }
    _busy = true;
    _last = DateTime.now();
    final batch = _q.take(50).toList();
    try {
      await client.from('app_logs').insert(batch);
      _q.removeWhere(batch.contains);
      _fails = 0;
    } catch (e) {
      _fails++;
      if (kDebugMode) Zone.root.print('[log] remote flush failed: $e');
    } finally {
      _busy = false;
      if (_q.isNotEmpty) _later();
    }
  }

  void _later() {
    final secs = math.min(300, 30 * (1 << math.min(_fails, 3)));
    _timer ??= Timer(Duration(seconds: secs), flush);
  }
}

// ───────────────────────── رابط اصلی ─────────────────────────

class Log {
  Log._();

  static final _console = _ConsoleSink();
  static final _memory = _MemorySink();
  static final _file = _FileSink();
  static final _remote = _RemoteSink();
  static late final List<_Sink> _sinks = [_console, _memory, _file, _remote];

  static final String sessionId = const Uuid().v4().substring(0, 8);
  static String? _userId;
  static String? _screen;
  static int _seq = 0;
  static bool _inPrint = false;
  static final _recent = <String, int>{};
  static bool _inited = false;

  static ValueListenable<int> get version => _memory.version;
  static List<LogRecord> get recent => _memory.all;

  /// ارسال لاگ‌های error+ به سرور را روشن/خاموش کنید (مثلاً از تنظیمات حریم خصوصی)
  static set remoteEnabled(bool v) => _remote.enabled = v;
  static bool get remoteEnabled => _remote.enabled;

  /// یک‌بار در ابتدای _bootstrap صدا زده شود (بعد از ensureInitialized).
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      await _file.init();
    } catch (e) {
      if (kDebugMode) Zone.root.print('[log] file sink disabled: $e');
    }

    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      Log.e('flutter', d.exceptionAsString(),
          error: d.exception,
          stack: d.stack,
          fields: {'library': d.library, if (d.context != null) 'context': d.context.toString()});
      if (kDebugMode) prev?.call(d);
    };
    // خطاهای async که به هیچ zone ای نرسیده‌اند
    PlatformDispatcher.instance.onError = (error, stack) {
      Log.f('platform', 'Unhandled error', error: error, stack: stack);
      return true;
    };
    WidgetsBinding.instance.addObserver(_LifeObserver());

    i('app', 'session start', fields: {
      'version': kAppVersion,
      'mode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
      'platform': _platformLabel,
      'dart': kIsWeb ? 'web' : Platform.version.split(' ').first,
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
    });
  }

  static void setUser(String? id) {
    if (id == _userId) return;
    _userId = id;
    i('auth', id == null ? 'user cleared' : 'user set');
    if (id != null) _remote.flush();
  }

  static void screen(String name) {
    if (name == _screen) return;
    d('nav', 'screen', fields: {'from': _screen, 'to': name});
    _screen = name;
  }

  static void v(String tag, String msg, {Map<String, Object?>? fields}) =>
      _log(LogLevel.verbose, tag, msg, fields, null, null);
  static void d(String tag, String msg, {Map<String, Object?>? fields}) =>
      _log(LogLevel.debug, tag, msg, fields, null, null);
  static void i(String tag, String msg, {Map<String, Object?>? fields}) =>
      _log(LogLevel.info, tag, msg, fields, null, null);
  static void w(String tag, String msg, {Map<String, Object?>? fields, Object? error, StackTrace? stack}) =>
      _log(LogLevel.warn, tag, msg, fields, error, stack);
  static void e(String tag, String msg, {Map<String, Object?>? fields, Object? error, StackTrace? stack}) =>
      _log(LogLevel.error, tag, msg, fields, error, stack);
  static void f(String tag, String msg, {Map<String, Object?>? fields, Object? error, StackTrace? stack}) =>
      _log(LogLevel.fatal, tag, msg, fields, error, stack);

  /// زمان‌سنجی یک عملیات async: خطا را لاگ می‌کند و دوباره پرتاب می‌کند.
  static Future<T> timed<T>(String tag, String op, Future<T> Function() fn,
      {Map<String, Object?>? fields, Duration slow = const Duration(seconds: 2)}) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      final f = {...?fields, 'ms': sw.elapsedMilliseconds};
      if (sw.elapsed > slow) {
        w(tag, '$op slow', fields: f);
      } else {
        d(tag, '$op ok', fields: f);
      }
      return r;
    } catch (err, st) {
      e(tag, '$op failed', error: err, stack: st, fields: {...?fields, 'ms': sw.elapsedMilliseconds});
      rethrow;
    }
  }

  /// از main.dart در ZoneSpecification.print صدا زده می‌شود تا همهٔ print های قدیمی هم ثبت شوند.
  static void fromPrint(String line) {
    if (_inPrint) return;
    _inPrint = true;
    try {
      final l = line.toLowerCase();
      final bad = l.contains('error') || l.contains('exception') || l.contains('failed') || line.contains('خطا');
      _log(bad ? LogLevel.warn : LogLevel.debug, 'print', line, null, null, null);
    } finally {
      _inPrint = false;
    }
  }

  static void _log(LogLevel lvl, String tag, String msg, Map<String, Object?>? fields, Object? error, StackTrace? stack) {
    try {
      var any = false;
      for (final s in _sinks) {
        if (lvl.index >= s.min.index) {
          any = true;
          break;
        }
      }
      if (!any) return;

      // تکرار یکسان در ۲ ثانیه (مثلاً خطای build در حلقه) فقط یک‌بار ثبت می‌شود
      if (lvl.index >= LogLevel.warn.index) {
        final key = '$tag|$msg|${error ?? ''}';
        final now = DateTime.now().millisecondsSinceEpoch;
        final last = _recent[key];
        if (last != null && now - last < 2000) return;
        if (_recent.length > 200) _recent.clear();
        _recent[key] = now;
      }

      final rec = LogRecord(
        seq: ++_seq,
        time: DateTime.now().toUtc(),
        level: lvl,
        tag: tag,
        message: _scrub(msg),
        fields: fields == null ? null : (_scrubValue(fields) as Map).cast<String, Object?>(),
        error: error == null ? null : _scrub(error.toString()),
        stack: stack?.toString(),
        sessionId: sessionId,
        userId: _userId,
        screen: _screen,
      );
      for (final s in _sinks) {
        if (lvl.index >= s.min.index) s.add(rec);
      }
    } catch (_) {
      // لاگ نباید هیچ‌وقت برنامه را بشکند
    }
  }

  // ───────────── خروجی/مشاهده ─────────────

  static Future<void> flush() async {
    await _file.flush();
    await _remote.flush();
  }

  /// لاگ‌های ذخیره‌شده روی دیسک (جلسه‌های قبلی هم)، قدیمی → جدید
  static Future<List<LogRecord>> readHistory({int maxLines = 2000}) async {
    final out = <LogRecord>[];
    for (final f in await _file.files()) {
      for (final line in await f.readAsLines()) {
        try {
          final r = LogRecord.fromJson(jsonDecode(line) as Map<String, dynamic>);
          if (r != null) out.add(r);
        } catch (_) {}
      }
    }
    return out.length > maxLines ? out.sublist(out.length - maxLines) : out;
  }

  /// یک فایل متنی برای اشتراک‌گذاری با پشتیبانی
  static Future<File?> exportFile() async {
    if (kIsWeb) return null;
    final recs = await readHistory(maxLines: 5000);
    final tmp = await getTemporaryDirectory();
    final out = File('${tmp.path}/dacko_logs.txt');
    final b = StringBuffer()
      ..writeln('Dacko logs  version=$kAppVersion  platform=$_platformLabel  session=$sessionId')
      ..writeln('exported ${DateTime.now().toIso8601String()}')
      ..writeln('-' * 60);
    for (final r in recs) {
      b.writeln(r.toLine());
    }
    await out.writeAsString(b.toString());
    return out;
  }

  static Future<void> clear() async {
    _memory.clear();
    await _file.clear();
  }
}

class _LifeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.i('app', 'lifecycle', fields: {'state': state.name});
    if (state != AppLifecycleState.resumed) Log.flush();
  }

  @override
  void didHaveMemoryPressure() => Log.w('app', 'memory pressure');
}

/// ثبت جابه‌جایی صفحه‌ها (push/pop/replace) در Navigator
class LogNavigatorObserver extends NavigatorObserver {
  String _n(Route<dynamic>? r) => r?.settings.name ?? r?.runtimeType.toString() ?? '-';
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      Log.d('nav', 'push', fields: {'route': _n(route), 'from': _n(previousRoute)});
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      Log.d('nav', 'pop', fields: {'route': _n(route), 'to': _n(previousRoute)});
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      Log.d('nav', 'replace', fields: {'new': _n(newRoute), 'old': _n(oldRoute)});
}
