// ignore_for_file: invalid_use_of_protected_member
// بخشی از arena_form_widgets.dart (بدون تغییر رفتار): arenaPillDecoration, ArenaTextField, ArenaDateField, ArenaAddCircle, ArenaAddItemRow, ArenaRemovableChips
part of '../arena_form_widgets.dart';


// ───────────────────────── ورودی‌ها ─────────────────────────

InputDecoration arenaPillDecoration(
  ThemeProvider theme, {
  String? hint,
  double radius = 26,
  double verticalPadding = 15,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 14,
      color: theme.textSecondaryColor.withValues(alpha: 0.8),
    ),
    filled: true,
    fillColor: theme.cardSecondaryColor,
    isDense: true,
    contentPadding:
        EdgeInsets.symmetric(horizontal: 18, vertical: verticalPadding),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: theme.effectivePrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: theme.errorColor, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: theme.errorColor, width: 1.5),
    ),
  );
}

/// برچسب ۱۳/۶۰۰ + ورودی قرص‌مانند (شعاع ۲۶، پس‌زمینهٔ cardSecondary)
class ArenaTextField extends StatelessWidget {
  final String? label;
  final IconData? labelIcon;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;

  const ArenaTextField({
    super.key,
    this.label,
    this.labelIcon,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final multi = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ArenaLabel(label!, icon: labelIcon),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: theme.textColor),
          cursorColor: theme.effectivePrimary,
          textAlignVertical: multi ? TextAlignVertical.top : null,
          decoration: arenaPillDecoration(
            theme,
            hint: hint,
            verticalPadding: multi ? 14 : 15,
          ),
        ),
      ],
    );
  }
}

/// فیلد تاریخ: متن + آیکن تقویم، با لمس باز می‌شود.
class ArenaDateField extends StatelessWidget {
  final String text;
  final bool hasValue;
  final VoidCallback onTap;

  const ArenaDateField({
    super.key,
    required this.text,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: theme.cardSecondaryColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue
                      ? theme.textColor
                      : theme.textSecondaryColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(Icons.calendar_month_rounded,
                size: 20, color: theme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

/// دایرهٔ «+» رنگ اصلی ۴۸ پیکسلی
class ArenaAddCircle extends StatelessWidget {
  final VoidCallback onTap;

  const ArenaAddCircle({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.effectivePrimary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add_rounded, size: 22, color: theme.onPrimaryColor),
      ),
    );
  }
}

/// ردیف «ورودی + دکمهٔ افزودن» برای زیرعادت/زیرتسک
class ArenaAddItemRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  const ArenaAddItemRow({
    super.key,
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, color: theme.textColor),
            cursorColor: theme.effectivePrimary,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: arenaPillDecoration(theme, hint: hint, verticalPadding: 16),
          ),
        ),
        const SizedBox(width: 10),
        ArenaAddCircle(onTap: onAdd),
      ],
    );
  }
}

/// چیپ‌های قابل حذف (زیرعادت/زیرتسک)
class ArenaRemovableChips extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onRemove;

  const ArenaRemovableChips(
      {super.key, required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            height: 34,
            padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
            decoration: BoxDecoration(
              color: theme.primarySoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => onRemove(item),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 12, color: theme.textColor),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── کنترل‌ها ─────────────────────────

/// سوییچ بخش‌بندی‌شده (روزانه | هفتگی | ماهانه) با ارتفاع ثابت و گوشهٔ گرد
class ArenaSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  const ArenaSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardSecondaryColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected
                        ? theme.effectivePrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular((height - 8) / 2),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          i == selected ? FontWeight.w700 : FontWeight.w500,
                      color: i == selected
                          ? theme.onPrimaryColor
                          : theme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «هر [−] n [+] روز» (مرحله‌دهنده)
class ArenaStepper extends StatelessWidget {
  final String prefix;
  final String suffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const ArenaStepper({
    super.key,
    required this.prefix,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    Widget btn(IconData icon, Color bg, Color fg, VoidCallback? onTap) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: fg),
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArenaLabel(prefix),
          const SizedBox(width: 10),
          btn(Icons.remove_rounded, theme.cardSecondaryColor, theme.textColor,
              value > min ? () => onChanged(value - 1) : null),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          btn(Icons.add_rounded, theme.effectivePrimary, theme.onPrimaryColor,
              value < max ? () => onChanged(value + 1) : null),
          const SizedBox(width: 10),
          ArenaLabel(suffix),
        ],
      ),
    );
  }
}

/// دایرهٔ قابل انتخاب (روز هفته/روز ماه)
class ArenaDayCircle extends StatelessWidget {
  final String text;
  final bool selected;
  final double fontSize;
  final VoidCallback onTap;

  const ArenaDayCircle({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.effectivePrimary : theme.cardSecondaryColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: selected ? theme.onPrimaryColor : theme.textColor,
          ),
        ),
      ),
    );
  }
}

/// شبکهٔ دایره‌های ثابت‌اندازه (بدون بریدگی؛ حلقهٔ انتخاب از لبه بیرون می‌زند)
class ArenaCircleGrid extends StatelessWidget {
  final int columns;
  final double spacing;
  final List<Widget> children;

  const ArenaCircleGrid({
    super.key,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: size, height: size, child: c),
          ],
        );
      },
    );
  }
}

/// دکمهٔ اصلی ۵۶ پیکسلی قرصی (رنگ اصلی + سایهٔ رنگی)
class ArenaPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  const ArenaPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final fg = theme.onPrimaryColor;
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: theme.effectivePrimary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: theme.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: theme.effectivePrimary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ───────────────────────── اسلایدر XP ─────────────────────────

class _XpThumbShape extends SliderComponentShape {
  final Color color;
  const _XpThumbShape(this.color);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(center, 14, Paint()..color = color);
  }
}