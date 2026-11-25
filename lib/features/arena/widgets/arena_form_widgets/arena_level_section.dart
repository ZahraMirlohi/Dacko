// ignore_for_file: invalid_use_of_protected_member
// بخشی از arena_form_widgets.dart (بدون تغییر رفتار): ArenaLevelSection, ArenaSubItemsSection, ArenaHabitIcon, kArenaHabitIcons, kArenaHabitBgColors, ArenaIconColorSection
part of '../arena_form_widgets.dart';


// ───────────────────────── بخش‌های فرم عادت ─────────────────────────

/// بخش «تنظیمات سطوح انجام عادت»: کارت رنگ ملایم + چهار ورودی
class ArenaLevelSection extends StatelessWidget {
  final String? targetValue;
  final String? fullDescription;
  final String? halfDescription;
  final String? basicDescription;
  final ValueChanged<String> onTarget;
  final ValueChanged<String> onFull;
  final ValueChanged<String> onHalf;
  final ValueChanged<String> onBasic;

  const ArenaLevelSection({
    super.key,
    required this.targetValue,
    required this.fullDescription,
    required this.halfDescription,
    required this.basicDescription,
    required this.onTarget,
    required this.onFull,
    required this.onHalf,
    required this.onBasic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ArenaSection(
      color: theme.primarySoft,
      children: [
        ArenaSectionHeader(
          icon: Icons.track_changes_rounded,
          text: context.tr('af.level.title'),
        ),
        Text(
          context.tr('af.level.desc'),
          style: TextStyle(
            fontSize: 12,
            height: 1.8,
            color: theme.textColor.withValues(alpha: 0.75),
          ),
        ),
        ArenaTextField(
          label: context.tr('af.level.target'),
          hint: context.tr('af.level.target_hint'),
          initialValue: targetValue,
          onChanged: onTarget,
        ),
        ArenaTextField(
          label: context.tr('af.level.full'),
          labelIcon: Icons.stars_rounded,
          hint: context.tr('af.level.full_hint'),
          initialValue: fullDescription,
          onChanged: onFull,
        ),
        ArenaTextField(
          label: context.tr('af.level.half'),
          labelIcon: Icons.star_half_rounded,
          hint: context.tr('af.level.half_hint'),
          initialValue: halfDescription,
          onChanged: onHalf,
        ),
        ArenaTextField(
          label: context.tr('af.level.basic'),
          labelIcon: Icons.auto_awesome_rounded,
          hint: context.tr('af.level.basic_hint'),
          initialValue: basicDescription,
          onChanged: onBasic,
        ),
      ],
    );
  }
}

/// بخش زیرعادت/زیرتسک: تیتر + ورودی با دکمهٔ «+» + چیپ‌های قابل حذف
class ArenaSubItemsSection extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final List<String> items;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const ArenaSubItemsSection({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  void _submit() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onAdd(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ArenaSection(
      children: [
        ArenaSectionHeader(icon: Icons.format_list_bulleted_rounded, text: title),
        ArenaAddItemRow(controller: controller, hint: hint, onAdd: _submit),
        if (items.isNotEmpty)
          ArenaRemovableChips(items: items, onRemove: onRemove),
      ],
    );
  }
}

class ArenaHabitIcon {
  final String name;
  final IconData icon;
  const ArenaHabitIcon(this.name, this.icon);
}

/// آیکن‌های قابل‌انتخاب عادت (نام ذخیره‌شده در مدل همان قبلی است)
const List<ArenaHabitIcon> kArenaHabitIcons = [
  ArenaHabitIcon('fitness_center', Icons.fitness_center_rounded),
  ArenaHabitIcon('self_improvement', Icons.self_improvement_rounded),
  ArenaHabitIcon('book', Icons.menu_book_rounded),
  ArenaHabitIcon('science', Icons.science_rounded),
  ArenaHabitIcon('restaurant', Icons.restaurant_rounded),
  ArenaHabitIcon('bedtime', Icons.bedtime_rounded),
  ArenaHabitIcon('water_drop', Icons.water_drop_rounded),
  ArenaHabitIcon('directions_walk', Icons.directions_walk_rounded),
  ArenaHabitIcon('run_circle', Icons.run_circle_rounded),
  ArenaHabitIcon('emoji_events', Icons.emoji_events_rounded),
];

/// رنگ‌های باکس عادت (داده‌اند، نه توکن تم)
const List<int> kArenaHabitBgColors = [
  0xFFFFF8E7,
  0xFFFFE0B2,
  0xFFFFCC80,
  0xFFFFAB91,
  0xFFB0CC5D,
  0xFF81D4FA,
  0xFFCE93D8,
  0xFFA5D6A7,
];

/// بخش «آیکن و رنگ»
class ArenaIconColorSection extends StatelessWidget {
  final String selectedIcon;
  final int selectedColor;
  final ValueChanged<String> onIcon;
  final ValueChanged<int> onColor;

  const ArenaIconColorSection({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIcon,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ArenaSection(
      children: [
        ArenaSectionHeader(
          icon: Icons.star_outline_rounded,
          text: context.tr('af.icon.title'),
        ),
        ArenaLabel(context.tr('af.icon.icon')),
        ArenaCircleGrid(
          columns: 5,
          spacing: 10,
          children: [
            for (final item in kArenaHabitIcons)
              GestureDetector(
                onTap: () => onIcon(item.name),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedIcon == item.name
                        ? theme.effectivePrimary
                        : theme.cardSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: selectedIcon == item.name
                        ? theme.onPrimaryColor
                        : theme.textColor,
                  ),
                ),
              ),
          ],
        ),
        ArenaLabel(context.tr('af.icon.color')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: ArenaCircleGrid(
            columns: 8,
            spacing: 8,
            children: [
              for (final value in kArenaHabitBgColors)
                GestureDetector(
                  onTap: () => onColor(value),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      boxShadow: selectedColor == value
                          ? [
                              BoxShadow(color: theme.cardColor, spreadRadius: 3),
                              BoxShadow(color: theme.textColor, spreadRadius: 6),
                            ]
                          : null,
                    ),
                    child: selectedColor == value
                        ? Icon(Icons.check_rounded,
                            size: 18, color: Color(0xFF090909))
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// بخش «تکرار»: روزانه / هفتگی / ماهانه (شنبه=۰ … جمعه=۶)
class ArenaFrequencySection extends StatelessWidget {
  final String frequencyType; // daily | weekly | monthly
  final int dailyInterval;
  final List<int> weeklyDays;
  final int weeklyInterval;
  final List<int> monthlyDays;
  final int monthlyInterval;
  final ValueChanged<String> onType;
  final ValueChanged<int> onDailyInterval;
  final ValueChanged<int> onToggleWeekday;
  final ValueChanged<int> onWeeklyInterval;
  final ValueChanged<int> onToggleMonthDay;
  final ValueChanged<int> onMonthlyInterval;

  const ArenaFrequencySection({
    super.key,
    required this.frequencyType,
    required this.dailyInterval,
    required this.weeklyDays,
    required this.weeklyInterval,
    required this.monthlyDays,
    required this.monthlyInterval,
    required this.onType,
    required this.onDailyInterval,
    required this.onToggleWeekday,
    required this.onWeeklyInterval,
    required this.onToggleMonthDay,
    required this.onMonthlyInterval,
  });

  static const List<String> _types = ['daily', 'weekly', 'monthly'];
  static const List<String> _lettersFa = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
  static const List<String> _lettersEn = ['S', 'S', 'M', 'T', 'W', 'T', 'F'];

  @override
  Widget build(BuildContext context) {
    final letters = context.isEnglish ? _lettersEn : _lettersFa;
    final selected = _types.indexOf(frequencyType).clamp(0, 2).toInt();
    final every = context.tr('af.freq.every');

    final List<Widget> content;
    switch (frequencyType) {
      case 'weekly':
        content = [
          ArenaCircleGrid(
            columns: 7,
            spacing: 6,
            children: [
              for (int i = 0; i < 7; i++)
                ArenaDayCircle(
                  text: letters[i],
                  selected: weeklyDays.contains(i),
                  onTap: () => onToggleWeekday(i),
                ),
            ],
          ),
          ArenaStepper(
            prefix: every,
            suffix: context.tr('af.freq.week'),
            value: weeklyInterval,
            min: 1,
            max: 12,
            onChanged: onWeeklyInterval,
          ),
        ];
        break;
      case 'monthly':
        content = [
          ArenaCircleGrid(
            columns: 8,
            spacing: 6,
            children: [
              for (int d = 1; d <= 31; d++)
                ArenaDayCircle(
                  text: '$d',
                  fontSize: 12,
                  selected: monthlyDays.contains(d),
                  onTap: () => onToggleMonthDay(d),
                ),
            ],
          ),
          ArenaStepper(
            prefix: every,
            suffix: context.tr('af.freq.month'),
            value: monthlyInterval,
            min: 1,
            max: 12,
            onChanged: onMonthlyInterval,
          ),
        ];
        break;
      default:
        content = [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ArenaStepper(
              prefix: every,
              suffix: context.tr('af.freq.day'),
              value: dailyInterval,
              min: 1,
              max: 30,
              onChanged: onDailyInterval,
            ),
          ),
        ];
    }

    return ArenaSection(
      children: [
        ArenaSectionHeader(
          icon: Icons.repeat_rounded,
          text: context.tr('af.freq.title'),
        ),
        ArenaSegmented(
          labels: [
            context.tr('af.freq.daily'),
            context.tr('af.freq.weekly'),
            context.tr('af.freq.monthly'),
          ],
          selected: selected,
          onChanged: (i) => onType(_types[i]),
        ),
        ...content,
      ],
    );
  }
}

/// بخش «زمان»: صبح / ظهر / بعدازظهر / شب
class ArenaTimeOfDaySection extends StatelessWidget {
  final String value; // morning | noon | afternoon | night
  final ValueChanged<String> onChanged;

  const ArenaTimeOfDaySection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final items = <List<Object>>[
      ['morning', 'af.time.morning', Icons.wb_sunny_rounded],
      ['noon', 'af.time.noon', Icons.light_mode_rounded],
      ['afternoon', 'af.time.afternoon', Icons.wb_twilight_rounded],
      ['night', 'af.time.night', Icons.bedtime_rounded],
    ];
    return ArenaSection(
      children: [
        ArenaSectionHeader(
          icon: Icons.schedule_rounded,
          text: context.tr('af.time.title'),
        ),
        Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(items[i][0] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 72,
                    decoration: BoxDecoration(
                      color: value == items[i][0]
                          ? theme.effectivePrimary
                          : theme.cardSecondaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i][2] as IconData,
                          size: 22,
                          color: value == items[i][0]
                              ? theme.onPrimaryColor
                              : theme.textColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(items[i][1] as String),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: value == items[i][0]
                                ? theme.onPrimaryColor
                                : theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// بخش «یادآور»: دکمهٔ افزودن + فهرست یادآورها (سوییچ فعال/غیرفعال + حذف)
class ArenaRemindersSection extends StatelessWidget {
  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<Reminder> onRemove;
  final void Function(Reminder reminder, bool enabled) onToggle;

  const ArenaRemindersSection({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onRemove,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ArenaSection(
      children: [
        Row(
          children: [
            Expanded(
              child: ArenaSectionHeader(
                icon: Icons.alarm_rounded,
                text: context.tr('af.rem.title'),
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.effectivePrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: theme.onPrimaryColor),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('af.rem.add'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.onPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              context.tr('af.rem.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
            ),
          )
        else
          for (final r in reminders)
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsetsDirectional.only(start: 18, end: 6),
              decoration: BoxDecoration(
                color: theme.cardSecondaryColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.getTimeString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  ArenaToggle(
                    value: r.isEnabled,
                    onChanged: (v) => onToggle(r, v),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => onRemove(r),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.errorColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: theme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// کارت «تاریخ» (شروع/سررسید): تیتر + فیلد تاریخ
class ArenaDateSection extends StatelessWidget {
  final String title;
  final String text;
  final bool hasValue;
  final VoidCallback onTap;

  const ArenaDateSection({
    super.key,
    required this.title,
    required this.text,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ArenaSection(
      children: [
        ArenaSectionHeader(icon: Icons.calendar_month_rounded, text: title),
        ArenaDateField(text: text, hasValue: hasValue, onTap: onTap),
      ],
    );
  }
}

/// کارت «امتیاز XP»
class ArenaXpSection extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  const ArenaXpSection({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ArenaSection(
      children: [
        ArenaSectionHeader(icon: Icons.star_outline_rounded, text: title),
        ArenaXpSlider(value: value, onChanged: onChanged),
      ],
    );
  }
}