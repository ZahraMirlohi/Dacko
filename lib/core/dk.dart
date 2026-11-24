// lib/core/dk.dart
// رنگ‌های «ثابت» قدیمی (خاکستری روشن، سفید، ...) در حالت شب باید به رنگ‌های تم تبدیل شوند.
// بدون context کار می‌کند؛ ThemeProvider در هر محاسبهٔ تم، مقدارها را به‌روز می‌کند.
// در حالت روز همان رنگ اصلی را برمی‌گرداند، پس ظاهر روز تغییری نمی‌کند.
import 'package:flutter/material.dart';

class Dk {
  Dk._();
  static bool dark = false;
  static Color _fill = const Color(0xFF1F2420);
  static Color _line = const Color(0xFF343A33);
  static Color _sub = const Color(0xFFB4B8B0);
  static Color _text = const Color(0xFFF1F3EE);

  static void update({
    required bool isDark,
    required Color fill,
    required Color line,
    required Color sub,
    required Color text,
  }) {
    dark = isDark;
    _fill = fill;
    _line = line;
    _sub = sub;
    _text = text;
  }

  /// پس‌زمینهٔ ملایم (کارت/چیپ/جعبه)
  static Color f(Color light) => dark ? _fill : light;

  /// خط و حاشیه / پس‌زمینهٔ غیرفعال
  static Color l(Color light) => dark ? _line : light;

  /// متن و آیکون ثانویه
  static Color s(Color light) => dark ? _sub : light;

  /// متن اصلی
  static Color t(Color light) => dark ? _text : light;
}
