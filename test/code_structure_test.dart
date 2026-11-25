import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// نگهبان معماری: فایل‌ها دوباره غول‌پیکر نشوند و خطا بی‌صدا بلعیده نشود.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('هیچ فایلی بیشتر از ۱۲۰۰ خط نیست', () {
    final big = <String>[];
    for (final f in files) {
      final n = f.readAsLinesSync().length;
      if (n > 1200) big.add('${f.path}: $n');
    }
    expect(big, isEmpty, reason: 'این فایل‌ها را به part/ماژول‌های کوچک‌تر بشکنید');
  });

  test('هیچ catch خالی خارج از سیستم لاگ وجود ندارد', () {
    final re = RegExp(r'catch \(\w+(, \w+)?\) \{\s*\}');
    final bad = <String>[];
    for (final f in files) {
      if (f.path.contains('core/logging')) continue;
      if (re.hasMatch(f.readAsStringSync())) bad.add(f.path);
    }
    expect(bad, isEmpty, reason: 'خطا باید حداقل با Log.w/Log.e ثبت شود');
  });

  test('هر فایل part به فایل اصلی خودش اشاره می‌کند', () {
    for (final f in files) {
      final s = f.readAsStringSync();
      final m = RegExp(r"^part of '([^']+)';", multiLine: true).firstMatch(s);
      if (m == null) continue;
      final target = File('${f.parent.path}/${m.group(1)}');
      expect(target.existsSync(), isTrue, reason: f.path);
      final stem = f.parent.uri.pathSegments.where((e) => e.isNotEmpty).last;
      expect(target.readAsStringSync(), contains("part '$stem/${f.uri.pathSegments.last}';"),
          reason: '${f.path} در فایل اصلی part نشده');
    }
  });
}
