// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از analytics_detail_screen.dart (بدون تغییر رفتار): _barChart, _buildTodayCard, _buildSectionCard, _shiftMonth, _buildHistoryBody, _getJalaliMonthName…
part of '../analytics_detail_screen.dart';

extension _AnalyticsDetailScreenStateMonthToday on _AnalyticsDetailScreenState {

  Widget _barChart({
    required ThemeProvider theme,
    required List<String> letters,
    required List<double> values,
    required double chartHeight,
    required double barMax,
    required Color Function(int) colorOf,
    required Set<int> bold,
    bool showPct = false,
  }) {
    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final v = values[i].clamp(0.0, 1.0);
              final h = (v * barMax).clamp(6.0, barMax);
              return SizedBox(
                width: 36,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showPct) ...[
                      Text(
                        '${_n((v * 100).round())}٪',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              bold.contains(i) ? FontWeight.w700 : FontWeight.w400,
                          color: bold.contains(i)
                              ? theme.textColor
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Container(
                      width: 36,
                      height: h,
                      decoration: BoxDecoration(
                        color: colorOf(i),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            return SizedBox(
              width: 36,
              child: Text(
                i < letters.length ? letters[i] : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      bold.contains(i) ? FontWeight.w700 : FontWeight.w400,
                  color: bold.contains(i)
                      ? theme.textColor
                      : theme.textSecondaryColor,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTodayCard(ThemeProvider theme) {
    final dark = theme.isDarkMode;
    final bg = dark ? const Color(0xFF1E2119) : _AnalyticsDetailScreenState._ink;
    final tileBg = dark ? const Color(0xFF2A2D24) : const Color(0xFF1E2119);
    final track = dark ? const Color(0xFF3A3E33) : const Color(0xFF2A2D24);
    const mutedText = Dk.l(Color(0xFFBFC5B3));

    final done = _tHabitsDone + _tTasksDone + _tChDone + _tQuDone;
    final total = _tHabitsTotal + _tTasksTotal + _tChTotal + _tQuTotal;
    final progress = total > 0 ? done / total : 0.0;

    Widget tile(String label, int d, int t) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                '${_n(d)}/${_n(t)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: mutedText),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(76, 76),
                      painter: _RingPainter(
                        progress: progress,
                        color: theme.effectivePrimary,
                        track: track,
                      ),
                    ),
                    Text(
                      '${_n((progress * 100).round())}٪',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('an.today_rate'),
                      style: const TextStyle(fontSize: 13, color: mutedText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total > 0
                          ? context.tr('an.today_done', {
                              'done': _n(done),
                              'total': _n(total),
                            })
                          : context.tr('an.today_none'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              tile(context.tr('an.tile_habits'), _tHabitsDone, _tHabitsTotal),
              const SizedBox(width: 8),
              tile(context.tr('an.tile_tasks'), _tTasksDone, _tTasksTotal),
              const SizedBox(width: 8),
              tile(context.tr('an.tile_challenges'), _tChDone, _tChTotal),
              const SizedBox(width: 8),
              tile(context.tr('an.tile_quests'), _tQuDone, _tQuTotal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeProvider theme,
    Tone tone,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final t = theme.tone(tone);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: theme.isDarkMode ? 0.1 : 0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 24, color: theme.textColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              textDirection: TextDirection.ltr,
              size: 22,
              color: theme.textColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== تاریخچه کلی ====================
  void _shiftMonth(CalendarProvider calendar, int delta) {
    _rebuild(() {
      if (calendar.isJalali) {
        final jalali = Jalali.fromDateTime(_currentMonth);
        int newMonth = jalali.month + delta;
        int newYear = jalali.year;
        if (newMonth < 1) {
          newMonth = 12;
          newYear--;
        } else if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        _currentMonth = Jalali(newYear, newMonth, 1).toDateTime();
      } else {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      }
    });
  }

  Widget _buildHistoryBody(BuildContext ctx) {
    final theme = Provider.of<ThemeProvider>(ctx);
    final calendar = Provider.of<CalendarProvider>(ctx);
    final rtl = Directionality.of(ctx) == TextDirection.rtl;

    String monthName;
    String yearText;
    int daysInMonth;
    int firstDayWeekday;

    if (calendar.isJalali) {
      final jalali = Jalali.fromDateTime(_currentMonth);
      monthName = _getJalaliMonthName(jalali.month);
      yearText = jalali.year.toString();
      daysInMonth = calendar.daysInMonth(jalali.year, jalali.month);
      firstDayWeekday = _getJalaliWeekday(jalali.year, jalali.month, 1);
    } else {
      monthName = _getGregorianMonthName(_currentMonth.month);
      yearText = _currentMonth.year.toString();
      daysInMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      firstDayWeekday =
          DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    }

    Widget navButton(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.cardSecondaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: theme.textColor, textDirection: TextDirection.ltr),
        ),
      );
    }

    Widget legendBox(Color c) => Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(7),
          ),
        );

    Widget statTile(Tone tone, String value, String label) {
      final t = theme.tone(tone);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _whiteCard(
          theme,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  navButton(
                    rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    ctx.tr('an.prev_month'),
                    () => _shiftMonth(calendar, -1),
                  ),
                  Text(
                    _n('$monthName $yearText'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor,
                    ),
                  ),
                  navButton(
                    rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    ctx.tr('an.next_month'),
                    () => _shiftMonth(calendar, 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCalendarGrid(
                theme,
                daysInMonth,
                firstDayWeekday,
                calendar,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ctx.tr('an.legend_less'),
                    style: TextStyle(
                        fontSize: 12, color: theme.textSecondaryColor),
                  ),
                  const SizedBox(width: 3),
                  legendBox(theme.cardSecondaryColor),
                  legendBox(theme.primarySoft),
                  legendBox(Color.lerp(
                      theme.effectivePrimary, theme.cardColor, 0.4)!),
                  legendBox(theme.effectivePrimary),
                  const SizedBox(width: 3),
                  Text(
                    ctx.tr('an.legend_more'),
                    style: TextStyle(
                        fontSize: 12, color: theme.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            statTile(Tone.sky, _n(_totalActiveDays),
                ctx.tr('an.stat_active_days')),
            const SizedBox(width: 10),
            statTile(Tone.lilac, _n(_habits.length),
                ctx.tr('an.stat_total_habits')),
            const SizedBox(width: 10),
            statTile(
                Tone.peach, _n(_bestStreak), ctx.tr('an.stat_best_streak')),
          ],
        ),
      ],
    );
  }

  String _getJalaliMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getGregorianMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  int _getJalaliWeekday(int year, int month, int day) {
    final jalali = Jalali(year, month, day);
    return jalali.weekDay - 1;
  }

  Widget _buildCalendarGrid(
    ThemeProvider theme,
    int daysInMonth,
    int firstDayWeekday,
    CalendarProvider calendar,
  ) {
    final weekDays = calendar.weekDayHeaders;
    final now = DateTime.now();
    final accent = theme.effectivePrimary;

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < weekDays.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      weekDays[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 40,
          ),
          itemCount: firstDayWeekday + daysInMonth,
          itemBuilder: (context, index) {
            final day = index - firstDayWeekday + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox();
            }

            DateTime date;
            if (calendar.isJalali) {
              final jalali = Jalali.fromDateTime(_currentMonth);
              date = Jalali(jalali.year, jalali.month, day).toDateTime();
            } else {
              date = DateTime(_currentMonth.year, _currentMonth.month, day);
            }

            final isToday = _isToday(date, calendar);
            final isActive = _activeDays.any(
              (d) =>
                  d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day,
            );
            final isFuture = date.isAfter(now) && !isToday;

            Color? bg;
            Color fg = theme.textColor;
            if (isToday) {
              bg = theme.isDarkMode ? Colors.white : _AnalyticsDetailScreenState._ink;
              fg = theme.isDarkMode ? _AnalyticsDetailScreenState._ink : Colors.white;
            } else if (isActive) {
              bg = accent;
              fg = _AnalyticsDetailScreenState._ink;
            } else if (isFuture) {
              fg = theme.textSecondaryColor.withValues(alpha: 0.6);
            }

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _n(day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isToday(DateTime date, CalendarProvider calendar) {
    final now = DateTime.now();
    if (calendar.isJalali) {
      final todayJalali = Jalali.fromDateTime(now);
      final dateJalali = Jalali.fromDateTime(date);
      return todayJalali.year == dateJalali.year &&
          todayJalali.month == dateJalali.month &&
          todayJalali.day == dateJalali.day;
    } else {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }
  }
}
