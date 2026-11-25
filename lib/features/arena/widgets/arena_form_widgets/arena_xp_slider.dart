// ignore_for_file: invalid_use_of_protected_member
// بخشی از arena_form_widgets.dart (بدون تغییر رفتار): ArenaXpSlider, _jalaliMonthsFa, _jalaliMonthsEn, _gregorianMonthsFa, _gregorianMonthsEn, showArenaDateDialog
part of '../arena_form_widgets.dart';


/// بخش امتیاز XP: اسلایدر با دستگیرهٔ مشکی + قرص «n XP» + نوشتهٔ حداقل/حداکثر
class ArenaXpSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int divisions;
  final ValueChanged<int> onChanged;

  const ArenaXpSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 5,
    this.max = 200,
    this.divisions = 39,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tone = theme.tone(Tone.apricot);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: theme.effectivePrimary,
                  inactiveTrackColor: theme.cardSecondaryColor,
                  thumbShape: _XpThumbShape(theme.checkButtonBackground),
                  overlayShape: SliderComponentShape.noOverlay,
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: divisions,
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 72),
              height: 34,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                '$value XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.isDarkMode ? tone.fg : const Color(0xFF090909),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min',
                  style: TextStyle(
                      fontSize: 12, color: theme.textSecondaryColor)),
              Text('$max',
                  style: TextStyle(
                      fontSize: 12, color: theme.textSecondaryColor)),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── دیالوگ انتخاب تاریخ ─────────────────────────

const List<String> _jalaliMonthsFa = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];
const List<String> _jalaliMonthsEn = [
  'Farvardin',
  'Ordibehesht',
  'Khordad',
  'Tir',
  'Mordad',
  'Shahrivar',
  'Mehr',
  'Aban',
  'Azar',
  'Dey',
  'Bahman',
  'Esfand',
];
const List<String> _gregorianMonthsFa = [
  'ژانویه',
  'فوریه',
  'مارس',
  'آوریل',
  'مه',
  'ژوئن',
  'ژوئیه',
  'اوت',
  'سپتامبر',
  'اکتبر',
  'نوامبر',
  'دسامبر',
];
const List<String> _gregorianMonthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// دیالوگ انتخاب تاریخ با چرخ‌های سال/ماه/روز و کلید شمسی/میلادی.
/// تاریخ انتخاب‌شده را (میلادی، فقط روز) برمی‌گرداند؛ با انصراف null.
Future<DateTime?> showArenaDateDialog(
  BuildContext context, {
  DateTime? initial,
}) {
  final calendar = Provider.of<CalendarProvider>(context, listen: false);
  return showDialog<DateTime>(
    context: context,
    barrierColor: const Color(0xFF090909).withValues(alpha: 0.42),
    builder: (_) => _ArenaDateDialog(
      initial: initial ?? DateTime.now(),
      startJalali: calendar.isJalali,
    ),
  );
}

class _ArenaDateDialog extends StatefulWidget {
  final DateTime initial;
  final bool startJalali;

  const _ArenaDateDialog({required this.initial, required this.startJalali});

  @override
  State<_ArenaDateDialog> createState() => _ArenaDateDialogState();
}

class _ArenaDateDialogState extends State<_ArenaDateDialog> {
  late bool _jalali;
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _jalali = widget.startJalali;
    _setFrom(widget.initial);
  }

  void _setFrom(DateTime d) {
    if (_jalali) {
      final j = Jalali.fromDateTime(d);
      _year = j.year;
      _month = j.month;
      _day = j.day;
    } else {
      _year = d.year;
      _month = d.month;
      _day = d.day;
    }
  }

  int _daysIn(int year, int month) {
    if (_jalali) return Jalali(year, month, 1).monthLength;
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _current() {
    final day = _day.clamp(1, _daysIn(_year, _month)).toInt();
    return _jalali
        ? Jalali(_year, _month, day).toDateTime()
        : DateTime(_year, _month, day);
  }

  void _switchMode(bool jalali) {
    if (jalali == _jalali) return;
    final d = _current();
    setState(() {
      _jalali = jalali;
      _setFrom(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final en = context.isEnglish;

    final nowYear = _jalali ? Jalali.now().year : DateTime.now().year;
    final firstYear = (nowYear - 2) < _year ? nowYear - 2 : _year;
    final lastYear = (nowYear + 10) > _year ? nowYear + 10 : _year;
    final years = [for (int y = firstYear; y <= lastYear; y++) y];

    final monthNames = _jalali
        ? (en ? _jalaliMonthsEn : _jalaliMonthsFa)
        : (en ? _gregorianMonthsEn : _gregorianMonthsFa);

    final daysCount = _daysIn(_year, _month);
    if (_day > daysCount) _day = daysCount;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF090909).withValues(alpha: 0.25),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('af.date.title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 14),
            ArenaSegmented(
              height: 44,
              labels: [
                context.tr('af.date.jalali'),
                context.tr('af.date.gregorian'),
              ],
              selected: _jalali ? 0 : 1,
              onChanged: (i) => _switchMode(i == 0),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DateWheel(
                      key: ValueKey('y_$_jalali'),
                      title: context.tr('af.date.year'),
                      labels: [for (final y in years) '$y'],
                      selectedIndex: years.indexOf(_year),
                      onChanged: (i) => setState(() => _year = years[i]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateWheel(
                      key: ValueKey('m_$_jalali'),
                      title: context.tr('af.date.month'),
                      labels: monthNames,
                      selectedIndex: _month - 1,
                      onChanged: (i) => setState(() => _month = i + 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateWheel(
                      key: ValueKey('d_${_jalali}_$daysCount'),
                      title: context.tr('af.date.day'),
                      labels: [for (int d = 1; d <= daysCount; d++) '$d'],
                      selectedIndex: _day - 1,
                      onChanged: (i) => setState(() => _day = i + 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.cardSecondaryColor,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(
                        context.tr('af.date.cancel'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 13,
                  child: GestureDetector(
                    onTap: () {
                      try {
                        final d = _current();
                        Navigator.pop(context, DateTime(d.year, d.month, d.day));
                      } catch (err, stk) {
                        Log.w('arena_form', 'build ignored error', error: err, stack: stk);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('af.date.invalid')),
                            backgroundColor: theme.errorColor,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.checkButtonBackground,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(
                        context.tr('af.date.confirm'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.onCheckButton,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// یک چرخ انتخاب (۵ ردیف قابل‌دیدن؛ ردیف وسط با قرص رنگی مشخص می‌شود)
class _DateWheel extends StatefulWidget {
  final String title;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DateWheel({
    super.key,
    required this.title,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<_DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<_DateWheel> {
  static const double _itemExtent = 40;
  late FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex.clamp(0, widget.labels.length - 1).toInt();
    _controller = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Column(
      children: [
        ArenaLabel(widget.title),
        const SizedBox(height: 6),
        SizedBox(
          height: _itemExtent * 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.primarySoft,
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: _itemExtent,
                diameterRatio: 100,
                perspective: 0.0001,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  setState(() => _selected = i);
                  widget.onChanged(i);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.labels.length,
                  builder: (context, i) {
                    final dist = (i - _selected).abs();
                    final isSel = dist == 0;
                    return Center(
                      child: Opacity(
                        opacity: isSel ? 1 : (dist == 1 ? 0.5 : 0.22),
                        child: Text(
                          widget.labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isSel ? 18 : 15,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── کمک‌های مشترک ─────────────────────────

/// اسنک‌بار هماهنگ با تم (موفق/خطا)
void showArenaSnack(BuildContext context, String message, {bool error = false}) {
  final theme = Provider.of<ThemeProvider>(context, listen: false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? theme.errorColor : theme.successColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// ساعت‌شمار یادآور با ظاهر هماهنگ با برنامه
Future<TimeOfDay?> showArenaTimePicker(
  BuildContext context, {
  TimeOfDay? initial,
}) {
  final theme = Provider.of<ThemeProvider>(context, listen: false);
  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
    builder: (ctx, child) {
      final base = Theme.of(ctx);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: theme.effectivePrimary,
            onPrimary: theme.onPrimaryColor,
            surface: theme.cardColor,
            onSurface: theme.textColor,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            hourMinuteShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            hourMinuteColor: theme.cardSecondaryColor,
            dialBackgroundColor: theme.cardSecondaryColor,
            dialHandColor: theme.effectivePrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

/// سوییچ ۴۸×۲۸ مطابق طراحی (دکمهٔ گرد داخل کپسول)
class ArenaToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ArenaToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? theme.effectivePrimary : theme.borderColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? theme.onPrimaryColor : theme.cardColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}