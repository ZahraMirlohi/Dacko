// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از analytics_detail_screen.dart (بدون تغییر رفتار): _buildBestHabitRow, _getWeekDayNamesForChart, _lowDayIndexes, _buildDropsBody, _buildDropsCta, _buildLoadingState…
part of '../analytics_detail_screen.dart';

extension _AnalyticsDetailScreenStateDayDrops on _AnalyticsDetailScreenState {

  Widget _buildBestHabitRow(ThemeProvider theme, Habit habit, int streak) {
    return _whiteCard(
      theme,
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getIconData(habit.iconName),
                size: 22, color: theme.textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  context.tr('an.rec_streak_days', {'n': _n(streak)}),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.local_fire_department_rounded,
              size: 18, color: theme.textColor),
          const SizedBox(width: 4),
          Text(
            _n(streak),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== نمودار شکست ====================
  List<String> _getWeekDayNamesForChart() {
    final calendar = Provider.of<CalendarProvider>(context, listen: false);
    if (calendar.isJalali) {
      return (context.isEnglish ? ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'] : [
            'شنبه',
            'یک‌شنبه',
            'دوشنبه',
            'سه‌شنبه',
            'چهارشنبه',
            'پنج‌شنبه',
            'جمعه'
          ]);
    } else {
      return [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
    }
  }

  List<int> _lowDayIndexes() {
    final idx = List<int>.generate(7, (i) => i)
      ..sort((a, b) => _successData[a].compareTo(_successData[b]));
    return idx.where((i) => _successData[i] < 0.5).take(2).toList()..sort();
  }

  Widget _buildDropsBody(BuildContext ctx) {
    final theme = Provider.of<ThemeProvider>(ctx);
    final calendar = Provider.of<CalendarProvider>(ctx);
    final maxValue = _successData.reduce((a, b) => a > b ? a : b);
    final hasData = _activeDays.isNotEmpty && maxValue > 0;

    if (!hasData) {
      return _emptyCard(
        theme,
        Icons.trending_down_rounded,
        ctx.tr('an.sec_drops'),
        ctx.tr('an.drops_need_data'),
      );
    }

    final names = _getWeekDayNamesForChart();
    final letters = _getWeekDayLetters(calendar);
    final lows = _lowDayIndexes();
    final peach = theme.tone(Tone.peach);
    final weakColor =
        theme.isDarkMode ? peach.fg : const Color(0xFFFFB48A);

    String headline;
    String hint;
    if (lows.isEmpty) {
      headline = ctx.tr('an.drops_no_low');
      hint = ctx.tr('an.drops_no_low_hint');
    } else if (lows.length == 1) {
      headline = names[lows.first];
      hint = ctx.tr('an.drops_low_hint');
    } else {
      headline =
          ctx.tr('an.drops_and', {'a': names[lows[0]], 'b': names[lows[1]]});
      hint = ctx.tr('an.drops_low_hint');
    }

    Widget tip(Tone tone, IconData icon, String text) {
      final t = theme.tone(tone);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _whiteCard(
          theme,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: theme.textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: peach.bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: theme.isDarkMode ? 0.1 : 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.trending_down_rounded,
                    size: 26, color: theme.textColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctx.tr('an.drops_low_days'),
                      style: TextStyle(
                          fontSize: 12, color: theme.textSecondaryColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: TextStyle(
                          fontSize: 12, color: theme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _whiteCard(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.tr('an.drops_chart'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 14),
              _barChart(
                theme: theme,
                letters: letters,
                values: _successData,
                chartHeight: 130,
                barMax: 100,
                bold: lows.toSet(),
                colorOf: (i) =>
                    lows.contains(i) ? weakColor : theme.primarySoft,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle(theme, ctx.tr('an.drops_tips')),
        const SizedBox(height: 10),
        tip(Tone.sky, Icons.remove_rounded, ctx.tr('an.drops_tip1')),
        tip(Tone.lilac, Icons.notifications_none_rounded,
            ctx.tr('an.drops_tip2')),
        tip(Tone.butter, Icons.person_outline_rounded, ctx.tr('an.drops_tip3')),
      ],
    );
  }

  Widget _buildDropsCta(BuildContext ctx) {
    final theme = Provider.of<ThemeProvider>(ctx);
    final dark = theme.isDarkMode;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // یادآور اختصاصی هنوز بک‌اند ندارد؛ فعلاً پیام «به‌زودی»
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(ctx.tr('an.soon'))),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: dark ? theme.effectivePrimary : _AnalyticsDetailScreenState._ink,
          foregroundColor: dark ? _AnalyticsDetailScreenState._ink : theme.effectivePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          ctx.tr('an.drops_cta'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ==================== حالت لودینگ ====================
  Widget _buildLoadingState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.effectivePrimary),
          const SizedBox(height: 16),
          Text(
            context.tr('an.loading'),
            style: TextStyle(color: theme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // ==================== متدهای کمکی ====================
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'book':
        return Icons.book;
      case 'science':
        return Icons.science;
      case 'restaurant':
        return Icons.restaurant;
      case 'bedtime':
        return Icons.bedtime;
      case 'water_drop':
        return Icons.water_drop;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'run_circle':
        return Icons.run_circle;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.fitness_center;
    }
  }
}
