// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از analytics_detail_screen.dart (بدون تغییر رفتار): _loadData, _getSampleActiveDays, _calculateAllHabitsStreak, _calculateBestStreak, _calculateSuccessData, _calculateSuccessDataFallback…
part of '../analytics_detail_screen.dart';

extension _AnalyticsDetailScreenStateCalculateData on _AnalyticsDetailScreenState {

  Future<void> _loadData() async {
    _clearCache();
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      if (syncProvider.habits.isNotEmpty) {
        _habits = syncProvider.habits;
      } else if (syncProvider.isOnline) {
        _habits = await _supabase.getHabits(widget.userId);
      } else {
        _habits = [];
      }

      try {
        final activityResponse = await _supabase.client
            .from('user_daily_activity')
            .select(
              'activity_date, habits_completed, tasks_completed, xp_earned',
            )
            .eq('user_id', widget.userId)
            .eq('is_active', true)
            .order('activity_date', ascending: false);

        _maxXpInDay = 0;
        for (final d in activityResponse) {
          final xp = (d['xp_earned'] as num?)?.toInt() ?? 0;
          if (xp > _maxXpInDay) _maxXpInDay = xp;
        }
        if (activityResponse.isNotEmpty) {
          _activeDays = activityResponse
              .map((d) => DateTime.parse(d['activity_date']))
              .toList();
        } else {
          _activeDays = _getSampleActiveDays();
        }
      } catch (e, stk) {
        Log.e('analytics_detail', '_loadData failed', error: e, stack: stk);
        _activeDays = _getSampleActiveDays();
      }

      _totalActiveDays = _activeDays.length;

      await _calculateBestStreak();
      await _calculateSuccessData();
      await _calculateHabitRates();
      await _calculateToday();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stk) {
      Log.e('analytics_detail', '_loadData failed', error: e, stack: stk);
      _activeDays = _getSampleActiveDays();
      _totalActiveDays = _activeDays.length;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<DateTime> _getSampleActiveDays() {
    // داده‌ی نمونه نشان نمی‌دهیم؛ بدون فعالیت یعنی خالی
    return <DateTime>[];
  }

  Future<Map<String, int>> _calculateAllHabitsStreak() async {
    final Map<String, int> habitStreaks = {};

    if (_habits.isEmpty) return habitStreaks;

    try {
      final habitIds = _habits.map((h) => h.id).toList();
      final response = await _supabase.client
          .from('habit_completions')
          .select('habit_id, date')
          .eq('user_id', widget.userId)
          .inFilter('habit_id', habitIds)
          .order('date', ascending: false);

      final Map<String, List<DateTime>> habitCompletions = {};
      final Map<String, int> perDay = {};
      for (var item in response) {
        final habitId = item['habit_id'] as String;
        final date = DateTime.parse(item['date'] as String);
        habitCompletions.putIfAbsent(habitId, () => []).add(date);
        final key = (item['date'] as String).split('T').first;
        perDay[key] = (perDay[key] ?? 0) + 1;
      }
      _maxItemsInDay =
          perDay.values.fold<int>(0, (m, v) => v > m ? v : m);

      for (var habit in _habits) {
        final completions = habitCompletions[habit.id] ?? [];
        if (completions.isEmpty) {
          habitStreaks[habit.id] = 0;
          continue;
        }

        final sortedDates = completions.toList()
          ..sort((a, b) => b.compareTo(a));

        int streak = 0;
        DateTime checkDate = DateTime.now();
        // اگر امروز هنوز انجام نشده، استریک از دیروز حساب می‌شود (فقط با یک روز کامل خالی می‌شکند)
        final latest = sortedDates.first;
        final yesterday = checkDate.subtract(const Duration(days: 1));
        if (!(latest.year == checkDate.year &&
            latest.month == checkDate.month &&
            latest.day == checkDate.day)) {
          checkDate = yesterday;
        }

        for (var date in sortedDates) {
          if (date.year == checkDate.year &&
              date.month == checkDate.month &&
              date.day == checkDate.day) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        habitStreaks[habit.id] = streak;
      }

      return habitStreaks;
    } catch (e, stk) {
      Log.e('analytics_detail', '_calculateAllHabitsStreak failed', error: e, stack: stk);
      return {};
    }
  }

  Future<void> _calculateBestStreak() async {
    if (_activeDays.isEmpty) return;

    final sortedDays = List<DateTime>.from(_activeDays)..sort();
    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    _bestStreak = maxStreak;

    final habitStreaks = await _calculateAllHabitsStreak();

    _bestStreakHabit = null;
    int maxHabitStreak = 0;

    for (var habit in _habits) {
      if (!habit.isActive) continue;
      if (habit.challengeId != null || habit.questId != null) continue;

      final streak = habitStreaks[habit.id] ?? 0;

      if (streak > habit.bestStreak) {
        habit.bestStreak = streak;
      }

      if (streak > maxHabitStreak) {
        maxHabitStreak = streak;
        _bestStreakHabit = habit;
      }
    }
  }

  Future<void> _calculateSuccessData() async {
    final now = DateTime.now();

    final List<double> successRates = List.filled(7, 0.0);
    final activeHabits = _habits.where((h) => h.isActive).toList();

    if (activeHabits.isEmpty) {
      setState(() => _successData = successRates);
      return;
    }

    final List<String> allDates = [];
    final List<DateTime> allDateTimes = [];

    for (int dayOffset = 27; dayOffset >= 0; dayOffset--) {
      final date = now.subtract(Duration(days: dayOffset));
      allDates.add(date.toIso8601String().split('T').first);
      allDateTimes.add(date);
    }

    final habitIds = activeHabits.map((h) => h.id).toList();
    Map<String, Set<String>> completions = {};

    try {
      final response = await _supabase.client
          .from('habit_completions')
          .select('habit_id, date')
          .eq('user_id', widget.userId)
          .inFilter('habit_id', habitIds);

      for (var item in response) {
        final habitId = item['habit_id'] as String;
        final date = item['date'] as String;
        if (allDates.contains(date)) {
          completions.putIfAbsent(habitId, () => {}).add(date);
        }
      }
    } catch (e, stk) {
      Log.e('analytics_detail', '_calculateSuccessData failed', error: e, stack: stk);
      _calculateSuccessDataFallback();
      return;
    }

    final Map<int, List<DateTime>> daysByWeekday = {
      for (int i = 0; i < 7; i++) i: [],
    };

    for (var date in allDateTimes) {
      final jalali = Jalali.fromDateTime(date);
      final weekday = jalali.weekDay - 1;
      daysByWeekday[weekday]?.add(date);
    }

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      int totalItems = 0;
      int completedItems = 0;

      final dates = daysByWeekday[dayIndex] ?? [];

      for (var date in dates) {
        final dateStr = date.toIso8601String().split('T').first;

        for (var habit in activeHabits) {
          if (!habit.shouldDoOnDate(date)) continue;
          // روزهای قبل از ساخته شدن عادت شکست حساب نمی‌شوند
          final created = DateTime(habit.createdAt.year, habit.createdAt.month,
              habit.createdAt.day);
          if (DateTime(date.year, date.month, date.day).isBefore(created)) {
            continue;
          }

          totalItems++;
          final isCompleted = completions[habit.id]?.contains(dateStr) ?? false;
          if (isCompleted) {
            completedItems++;
          }
        }
      }

      if (totalItems > 0) {
        successRates[dayIndex] = completedItems / totalItems;
      } else {
        successRates[dayIndex] = 0.0;
      }
    }

    setState(() {
      _successData = successRates;
    });
  }

  void _calculateSuccessDataFallback() {
    final now = DateTime.now();

    final List<double> successRates = List.filled(7, 0.0);
    final activeHabits = _habits.where((h) => h.isActive).toList();

    if (activeHabits.isEmpty) {
      setState(() => _successData = successRates);
      return;
    }

    final Map<int, int> dayCount = {for (int i = 0; i < 7; i++) i: 0};

    for (var date in _activeDays) {
      final jalali = Jalali.fromDateTime(date);
      final weekday = jalali.weekDay - 1;
      dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
    }

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      int totalItems = 0;
      int completedItems = 0;

      for (int week = 0; week < 4; week++) {
        final date = now
            .subtract(Duration(days: 27))
            .add(Duration(days: (week * 7) + dayIndex));

        if (date.isAfter(now)) continue;

        for (var habit in activeHabits) {
          if (!habit.shouldDoOnDate(date)) continue;
          // روزهای قبل از ساخته شدن عادت شکست حساب نمی‌شوند
          final created = DateTime(habit.createdAt.year, habit.createdAt.month,
              habit.createdAt.day);
          if (DateTime(date.year, date.month, date.day).isBefore(created)) {
            continue;
          }
          totalItems++;

          final isActiveDay = _activeDays.any(
            (d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day,
          );
          if (isActiveDay) completedItems++;
        }
      }

      if (totalItems > 0) {
        successRates[dayIndex] = completedItems / totalItems;
      }
    }

    setState(() {
      _successData = successRates;
    });
  }

  // متدهای کمکی با CalendarProvider
  DateTime _getWeekStart(DateTime date, CalendarProvider calendar) {
    if (calendar.isJalali) {
      final jalali = Jalali.fromDateTime(date);
      final daysToSubtract = jalali.weekDay - 1;
      return date.subtract(Duration(days: daysToSubtract));
    } else {
      final daysToSubtract = date.weekday % 7;
      return date.subtract(Duration(days: daysToSubtract));
    }
  }

  int _getCurrentWeekdayIndex(CalendarProvider calendar) {
    if (calendar.isJalali) {
      final jalaliNow = Jalali.now();
      return jalaliNow.weekDay - 1;
    } else {
      return DateTime.now().weekday % 7;
    }
  }

  List<String> _getWeekDayLetters(CalendarProvider calendar) {
    return calendar.weekDayHeaders;
  }

  List<Map<String, dynamic>> _getBestWeekDays(CalendarProvider calendar) {
    final weekDays = calendar.isJalali
        ? (context.isEnglish ? ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'] : [
            'شنبه',
            'یک‌شنبه',
            'دوشنبه',
            'سه‌شنبه',
            'چهارشنبه',
            'پنج‌شنبه',
            'جمعه'
          ])
        : [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];
    final List<Map<String, dynamic>> result = [];

    final Map<int, int> dayActivityCount = {};
    for (int i = 0; i < 7; i++) {
      dayActivityCount[i] = 0;
    }

    for (var date in _activeDays) {
      int weekday;
      if (calendar.isJalali) {
        final jalali = Jalali.fromDateTime(date);
        weekday = jalali.weekDay - 1;
      } else {
        weekday = date.weekday % 7;
      }
      dayActivityCount[weekday] = (dayActivityCount[weekday] ?? 0) + 1;
    }

    final sortedDays = dayActivityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedDays) {
      if (entry.value > 0) {
        result.add({
          'day': weekDays[entry.key],
          'count': entry.value,
          'index': entry.key,
        });
      }
    }

    return result;
  }


  // ==================== ابزارهای مشترک ====================
  String _n(Object v) {
    final s = v.toString();
    if (context.isEnglish) return s;
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var out = s;
    for (int i = 0; i < en.length; i++) {
      out = out.replaceAll(en[i], fa[i]);
    }
    return out;
  }

  void _rebuild(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _tick.value++;
  }

  Widget _header(BuildContext ctx, ThemeProvider theme, String title) {
    final rtl = Directionality.of(ctx) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: theme.softShadow,
              ),
              child: Icon(
                Icons.arrow_back_rounded,

                size: 22,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pushSub(
    String title,
    Widget Function(BuildContext ctx) bodyBuilder, {
    Widget Function(BuildContext ctx)? bottomBuilder,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeCtx) => ValueListenableBuilder<int>(
          valueListenable: _tick,
          builder: (c, _, __) {
            final theme = Provider.of<ThemeProvider>(c);
            return Scaffold(
              backgroundColor: theme.backgroundColor,
              body: SafeArea(
                child: Column(
                  children: [
                    _header(c, theme, title),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: bodyBuilder(c),
                      ),
                    ),
                    if (bottomBuilder != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: bottomBuilder(c),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _whiteCard(ThemeProvider theme,
      {required Widget child,
      EdgeInsets padding = const EdgeInsets.all(18),
      double radius = 32}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: theme.softShadow,
      ),
      child: child,
    );
  }

  Widget _soonBadge(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.tr('an.soon'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeProvider theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: theme.textColor,
      ),
    );
  }

  Widget _emptyCard(ThemeProvider theme, IconData icon, String title,
      String subtitle) {
    return _whiteCard(
      theme,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 56, color: theme.textSecondaryColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
