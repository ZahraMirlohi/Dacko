// lib/features/arena/widgets/arena_form_widgets.dart
//
// قطعه‌های مشترک فرم‌های عادت و تسک (افزودن/ویرایش) و دیالوگ انتخاب تاریخ،
// مطابق آرت‌بوردهای AddHabit / AddTask / EditHabit / EditTask / DateDialog.

import '/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '/features/arena/models/habit_model.dart';
import '/l10n/app_strings.dart';
import '/providers/calendar_provider.dart';
import '/providers/theme_provider.dart';
import '/core/app_palette.dart';
import '/core/dk.dart';

part 'arena_form_widgets/arena_pill_decoration.dart';
part 'arena_form_widgets/arena_xp_slider.dart';
part 'arena_form_widgets/arena_level_section.dart';

// ───────────────────────── صفحه و سربرگ ─────────────────────────

/// اسکلت صفحهٔ فرم: دکمهٔ بازگشت گرد + عنوان ۲۰/۸۰۰ + بدنهٔ اسکرول‌شونده.
class ArenaFormPage extends StatelessWidget {
  final String title;
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;

  const ArenaFormPage({
    super.key,
    required this.title,
    required this.children,
    this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: theme.softShadow,
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 22, color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        children[i],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// کارت سفید گرد (شعاع ۲۸) با فاصلهٔ ۱۲ بین فرزندها.
class ArenaSection extends StatelessWidget {
  final List<Widget> children;

  /// اگر داده شود به‌جای کارت سفید و با سایه، کارت رنگی بدون سایه می‌شود.
  final Color? color;

  const ArenaSection({super.key, required this.children, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: color == null ? theme.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// تیتر بخش: آیکن ۲۰ + متن ۱۶/۸۰۰
class ArenaSectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;

  const ArenaSectionHeader({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class ArenaLabel extends StatelessWidget {
  final String text;
  final IconData? icon;

  const ArenaLabel(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: theme.textSecondaryColor,
    );
    if (icon == null) return Text(text, style: style);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.textSecondaryColor),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
