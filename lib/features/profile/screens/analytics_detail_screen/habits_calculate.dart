// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از analytics_detail_screen.dart (بدون تغییر رفتار): _getAllHabitsWeeklyStatus, _clearCache, _calculateHabitRates, _calculateToday, _buildHabitsBody, _buildHabitRateRow…
part of '../analytics_detail_screen.dart';

extension _AnalyticsDetailScreenStateHabitsCalculate on _AnalyticsDetailScreenState {

  // ==================== جزئیات عادت‌ها ====================
  Future<Map<String, List<bool>>> _getAllHabitsWeeklyStatus(
    CalendarProvider calendar,
  ) async {
    if (_cachedWeeklyStatus != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _AnalyticsDetailScreenState._cacheDuration) {
      return _cachedWeeklyStatus!;
    }

    final Map<String, List<bool>> result = {};
    final now = DateTime.now();
    final weekStart = _getWeekStart(now, calendar);

    if (_habits.isEmpty) return result;

    final List<String> weekDates = [];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      weekDates.add(date.toIso8601String().split('T').first);
    }

    final List<String> habitIds = _habits.map((h) => h.id).toList();

    try {
      final response = await _supabase.client
          .from('habit_completions')
          .select('habit_id, date')
          .eq('user_id', widget.userId)
          .inFilter('habit_id', habitIds)
          .inFilter('date', weekDates);

      final Set<String> completedSet = {};
      for (var item in response) {
        final habitId = item['habit_id'] as String;
        final date = item['date'] as String;
        completedSet.add('$habitId|$date');
      }

      for (var habit in _habits) {
        final List<bool> weekStatus = [];
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          final dateStr = date.toIso8601String().split('T').first;
          final key = '${habit.id}|$dateStr';
          weekStatus.add(completedSet.contains(key));
        }
        result[habit.id] = weekStatus;
      }

      _cachedWeeklyStatus = result;
      _cacheTime = DateTime.now();

      return result;
    } catch (e, stk) {
      Log.e('analytics_detail', '_getAllHabitsWeeklyStatus failed', error: e, stack: stk);
      for (var habit in _habits) {
        result[habit.id] = List.filled(7, false);
      }
      return result;
    }
  }

  void _clearCache() {
    _cachedWeeklyStatus = null;
    _cacheTime = null;
  }

  Future<void> _calculateHabitRates() async {
    final activeHabits = _habits.where((h) => h.isActive).toList();
    final Map<String, double> rates = {};
    if (activeHabits.isEmpty) {
      _habitRates = rates;
      return;
    }

    final now = DateTime.now();
    final List<DateTime> days = [
      for (int i = 29; i >= 0; i--) now.subtract(Duration(days: i)),
    ];
    final dateStrs = days.map((d) => d.toIso8601String().split('T').first);
    final Map<String, Set<String>> completions = {};

    try {
      final response = await _supabase.client
          .from('habit_completions')
          .select('habit_id, date')
          .eq('user_id', widget.userId)
          .inFilter('habit_id', activeHabits.map((h) => h.id).toList())
          .inFilter('date', dateStrs.toList());
      for (var item in response) {
        completions
            .putIfAbsent(item['habit_id'] as String, () => {})
            .add(item['date'] as String);
      }
    } catch (e, stk) {
      Log.e('analytics_detail', '_calculateHabitRates failed', error: e, stack: stk);
      // بدون داده‌ی تکمیل، نرخ‌ها صفر می‌مانند
    }

    for (var habit in activeHabits) {
      final created = DateTime(
          habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
      int total = 0;
      int done = 0;
      for (var d in days) {
        if (!habit.shouldDoOnDate(d)) continue;
        if (DateTime(d.year, d.month, d.day).isBefore(created)) continue;
        total++;
        final s = d.toIso8601String().split('T').first;
        if (completions[habit.id]?.contains(s) ?? false) done++;
      }
      rates[habit.id] = total > 0 ? done / total : 0.0;
    }
    _habitRates = rates;
  }

  Future<void> _calculateToday() async {
    if (!mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = now.toIso8601String().split('T').first;
    final sync = Provider.of<SyncProvider>(context, listen: false);

    final scheduled = _habits.where((h) {
      if (!h.isActive || !h.shouldDoOnDate(now)) return false;
      final created =
          DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
      return !created.isAfter(today);
    }).toList();

    Set<String> doneIds = {};
    if (scheduled.isNotEmpty) {
      try {
        final response = await _supabase.client
            .from('habit_completions')
            .select('habit_id')
            .eq('user_id', widget.userId)
            .eq('date', todayStr)
            .inFilter('habit_id', scheduled.map((h) => h.id).toList());
        doneIds = {for (var r in response) r['habit_id'] as String};
      } catch (e, stk) {
        Log.e('analytics_detail', '_calculateToday failed', error: e, stack: stk);
        // نادیده بگیر
      }
    }

    int hd = 0, ht = 0, cd = 0, ct = 0, qd = 0, qt = 0;
    for (var h in scheduled) {
      final isDone = doneIds.contains(h.id);
      if (h.challengeId != null) {
        ct++;
        if (isDone) cd++;
      } else if (h.questId != null) {
        qt++;
        if (isDone) qd++;
      } else {
        ht++;
        if (isDone) hd++;
      }
    }

    final todayTasks = sync.tasks.where((t) => t.isForToday()).toList();

    _tHabitsDone = hd;
    _tHabitsTotal = ht;
    _tChDone = cd;
    _tChTotal = ct;
    _tQuDone = qd;
    _tQuTotal = qt;
    _tTasksTotal = todayTasks.length;
    _tTasksDone = todayTasks.where((t) => t.isCompleted).length;
  }

  Widget _buildHabitsBody(BuildContext ctx) {
    final theme = Provider.of<ThemeProvider>(ctx);
    final calendar = Provider.of<CalendarProvider>(ctx);

    if (_habits.isEmpty) {
      return _emptyCard(
        theme,
        Icons.bar_chart_rounded,
        ctx.tr('an.habits_empty_title'),
        ctx.tr('an.habits_empty_sub'),
      );
    }

    final names = _getWeekDayNamesForChart();
    final letters = _getWeekDayLetters(calendar);
    int bestIdx = 0;
    for (int i = 1; i < _successData.length; i++) {
      if (_successData[i] > _successData[bestIdx]) bestIdx = i;
    }
    final hasBest = _successData[bestIdx] > 0;

    final activeHabits = _habits.where((h) => h.isActive).toList()
      ..sort((a, b) =>
          (_habitRates[b.id] ?? 0).compareTo(_habitRates[a.id] ?? 0));
    const tones = [Tone.lilac, Tone.sky, Tone.peach, Tone.butter];
    const maxShown = 6;
    final shown = activeHabits.take(maxShown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _whiteCard(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ctx.tr('an.habits_weekday'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  if (hasBest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ctx.tr('an.habits_best', {'day': names[bestIdx]}),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _barChart(
                theme: theme,
                letters: letters,
                values: _successData,
                chartHeight: 150,
                barMax: 110,
                showPct: true,
                bold: hasBest ? {bestIdx} : <int>{},
                colorOf: (i) => (hasBest && i == bestIdx)
                    ? theme.effectivePrimary
                    : theme.primarySoft,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle(theme, ctx.tr('an.habits_last30')),
        const SizedBox(height: 10),
        for (int i = 0; i < shown.length; i++) ...[
          _buildHabitRateRow(theme, shown[i], tones[i % tones.length]),
          const SizedBox(height: 10),
        ],
        if (activeHabits.length > maxShown)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                ctx.tr('an.habits_more',
                    {'n': _n(activeHabits.length - maxShown)}),
                style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHabitRateRow(ThemeProvider theme, Habit habit, Tone tone) {
    final t = theme.tone(tone);
    final rate = (_habitRates[habit.id] ?? 0.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_n((rate * 100).round())}٪',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            alignment: AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: theme.isDarkMode ? 0.12 : 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: rate,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.isDarkMode ? t.fg : _AnalyticsDetailScreenState._ink,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== رکوردهای شما ====================
  List<({Habit habit, int streak})> _getHabitsWithBestStreak() {
    List<({Habit habit, int streak})> result = [];

    if (_habits.isEmpty) return result;

    int maxStreak = 0;
    for (var habit in _habits) {
      if (!habit.isActive) continue;
      if (habit.challengeId != null || habit.questId != null) continue;

      if (habit.bestStreak > maxStreak) {
        maxStreak = habit.bestStreak;
      }
    }

    if (maxStreak == 0) return result;

    for (var habit in _habits) {
      if (!habit.isActive) continue;
      if (habit.challengeId != null || habit.questId != null) continue;

      if (habit.bestStreak == maxStreak) {
        result.add((habit: habit, streak: habit.bestStreak));
      }
    }

    return result;
  }

  Widget _buildRecordsBody(BuildContext ctx) {
    final theme = Provider.of<ThemeProvider>(ctx);
    final calendar = Provider.of<CalendarProvider>(ctx);
    final dark = theme.isDarkMode;
    final accent = theme.effectivePrimary;
    final bestDays = _getBestWeekDays(calendar);
    final topDay = bestDays.isNotEmpty ? bestDays.first : null;
    final bestHabits = _getHabitsWithBestStreak();

    Widget recTile(Tone tone, String label, String value) {
      final t = theme.tone(tone);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      );
    }

    final noData = ctx.tr('an.rec_no_data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(22),
            color: dark ? const Color(0xFF1E2119) : _AnalyticsDetailScreenState._ink,
            child: Stack(
              children: [
                Positioned(
                  left: -52,
                  top: -52,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF2A2D24)
                          : const Color(0xFF1E2119),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 36, color: _AnalyticsDetailScreenState._ink),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.tr('an.rec_longest'),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFBFC5B3)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctx.tr('an.day_unit', {'n': _n(_bestStreak)}),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bestStreak > 0
                                ? ctx.tr('an.rec_from_days',
                                    {'n': _n(_activeDays.length)})
                                : ctx.tr('an.rec_none'),
                            style: TextStyle(fontSize: 12, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  recTile(
                    Tone.butter,
                    ctx.tr('an.rec_best_weekday'),
                    topDay != null ? topDay['day'] as String : noData,
                  ),
                  const SizedBox(height: 10),
                  recTile(
                    Tone.lilac,
                    ctx.tr('an.rec_most_xp'),
                    _maxXpInDay > 0 ? '${_n(_maxXpInDay)} XP' : noData,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  recTile(
                    Tone.sky,
                    ctx.tr('an.rec_most_tasks'),
                    _maxItemsInDay > 0
                        ? ctx.tr('an.n_items', {'n': _n(_maxItemsInDay)})
                        : noData,
                  ),
                  const SizedBox(height: 10),
                  recTile(
                    Tone.peach,
                    ctx.tr('an.rec_active_total'),
                    ctx.tr('an.day_unit', {'n': _n(_totalActiveDays)}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(theme, ctx.tr('an.rec_best_habits')),
        const SizedBox(height: 10),
        if (bestHabits.isEmpty)
          _whiteCard(
            theme,
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              _habits.isNotEmpty
                  ? ctx.tr('an.rec_none')
                  : ctx.tr('an.habits_empty_title'),
              style: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
            ),
          )
        else
          for (final item in bestHabits.take(5)) ...[
            _buildBestHabitRow(theme, item.habit, item.streak),
            const SizedBox(height: 10),
          ],
        if (bestHabits.length > 5)
          Center(
            child: Text(
              ctx.tr('an.habits_more', {'n': _n(bestHabits.length - 5)}),
              style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _sectionTitle(theme, ctx.tr('an.rec_medals'))),
            _soonBadge(theme),
          ],
        ),
        const SizedBox(height: 10),
        _whiteCard(
          theme,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.military_tech_rounded,
                    size: 22, color: theme.textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ctx.tr('an.rec_medals_soon'),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
