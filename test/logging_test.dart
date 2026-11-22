import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/core/logging/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Log.resetForTest);

  group('پاک‌سازی دادهٔ حساس', () {
    test('ایمیل، JWT و تلفن حذف می‌شوند', () {
      expect(scrubText('mail a.b@example.com now'), 'mail [email] now');
      expect(
        scrubText('t=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcdefghijk'),
        't=[jwt]',
      );
      expect(scrubText('call +989123456789 now'), 'call [phone] now');
    });

    test('کلیدهای حساس در Map مخفی می‌شوند (تو در تو هم)', () {
      final out = scrubValue({
        'password': 'x',
        'name': 'ali',
        'nested': {'token': 't', 'n': 1},
      });
      expect(out, {
        'password': '***',
        'name': 'ali',
        'nested': {'token': '***', 'n': 1},
      });
    });

    test('رشتهٔ خیلی بلند کوتاه می‌شود', () {
      final out = scrubValue('a' * 700) as String;
      expect(out.length, 601);
      expect(out.endsWith('…'), isTrue);
    });
  });

  group('Log', () {
    test('سطح، تگ، پیام و خطا ثبت می‌شود', () {
      Log.e('t1', 'boom-1', error: Exception('x'));
      final r = Log.recent.last;
      expect(r.level, LogLevel.error);
      expect(r.tag, 't1');
      expect(r.message, 'boom-1');
      expect(r.error, contains('Exception: x'));
    });

    test('خطای تکراری در ۲ ثانیه فقط یک‌بار ثبت می‌شود', () {
      Log.e('t2', 'same-error');
      Log.e('t2', 'same-error');
      expect(Log.recent.where((r) => r.message == 'same-error'), hasLength(1));
    });

    test('verbose ثبت نمی‌شود ولی debug و info می‌شود', () {
      Log.v('t3', 'v-msg');
      Log.d('t3', 'd-msg');
      Log.i('t3', 'i-msg');
      final msgs = Log.recent.map((r) => r.message).toList();
      expect(msgs, isNot(contains('v-msg')));
      expect(msgs, containsAll(['d-msg', 'i-msg']));
    });

    test('پیام و فیلدها پاک‌سازی می‌شوند', () {
      Log.i('t4', 'mail a@b.com', fields: {'token': 'abc', 'k': 1});
      final r = Log.recent.last;
      expect(r.message, 'mail [email]');
      expect(r.fields, {'token': '***', 'k': 1});
    });

    test('کاربر و صفحهٔ جاری روی رکوردها می‌نشیند', () {
      Log.setUser('user-1');
      Log.screen('home');
      Log.i('t5', 'with-context');
      final r = Log.recent.last;
      expect(r.userId, 'user-1');
      expect(r.screen, 'home');
    });

    test('print های قدیمی: خطادار warn، بقیه debug', () {
      Log.fromPrint('Error loading things');
      expect(Log.recent.last.level, LogLevel.warn);
      expect(Log.recent.last.tag, 'print');
      Log.fromPrint('just a note');
      expect(Log.recent.last.level, LogLevel.debug);
    });

    test('timed: نتیجه را برمی‌گرداند و زمان را ثبت می‌کند', () async {
      final v = await Log.timed('t6', 'op-ok', () async => 42);
      expect(v, 42);
      final r = Log.recent.last;
      expect(r.message, 'op-ok ok');
      expect(r.fields!['ms'], isA<int>());
    });

    test('timed: خطا را لاگ می‌کند و دوباره پرتاب می‌کند', () async {
      await expectLater(
        Log.timed<int>('t7', 'op-fail', () async => throw StateError('bad')),
        throwsA(isA<StateError>()),
      );
      final r = Log.recent.last;
      expect(r.level, LogLevel.error);
      expect(r.message, 'op-fail failed');
    });
  });

  group('LogRecord', () {
    test('JSON رفت‌وبرگشت', () {
      final r = LogRecord(
        seq: 7,
        time: DateTime.utc(2026, 1, 2, 3, 4, 5),
        level: LogLevel.warn,
        tag: 'tag',
        message: 'msg',
        fields: const {'a': 1},
        error: 'err',
        stack: 'st',
        sessionId: 'sid',
        userId: 'uid',
        screen: 'scr',
      );
      final back = LogRecord.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>)!;
      expect(back.seq, 7);
      expect(back.time, r.time);
      expect(back.level, LogLevel.warn);
      expect(back.tag, 'tag');
      expect(back.message, 'msg');
      expect(back.fields, {'a': 1});
      expect(back.error, 'err');
      expect(back.userId, 'uid');
      expect(back.screen, 'scr');
    });

    test('fromJson با ورودی خراب null می‌دهد', () {
      expect(LogRecord.fromJson({'t': 'not-a-date'}), isNull);
    });

    test('toLine تگ و پیام را دارد', () {
      final r = LogRecord(
        seq: 1,
        time: DateTime.utc(2026),
        level: LogLevel.error,
        tag: 'chat',
        message: 'send failed',
        sessionId: 's',
      );
      expect(r.toLine(), allOf(contains('E/chat'), contains('send failed')));
    });
  });
}
