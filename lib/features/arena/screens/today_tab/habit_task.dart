// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از today_tab.dart (بدون تغییر رفتار): _editTask, _deleteTask, _buildSwipeableHabitItem, _buildSwipeableCompletedHabitItem, _buildSwipeableTaskItem, _buildSwipeableCompletedTaskItem…
part of '../today_tab.dart';

extension TodayTabStateHabitTask on TodayTabState {

  void _editTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
    if (result == true && mounted) {
      _cacheTime = null;
      _cachedTasks = null;
      await _loadData();
    }
    _toggleExpanded(task.id, 'task');
  }

  void _deleteTask(Task task) async {
    final confirm = await showArenaDeleteDialog(
      context,
      title: context.tr('ah.tasks.delTitle'),
      message: context.tr('ah.tasks.delMsg'),
    );

    if (confirm == true && mounted) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 1. حذف از state محلی
      setState(() {
        _todayTasks.removeWhere((t) => t.id == task.id);
        _completedTasks.removeWhere((t) => t.id == task.id);
      });

      // 2. حذف از LocalStorage
      await syncProvider.deleteTaskFromLocal(task.id);

      try {
        // 3. حذف از Supabase
        if (syncProvider.isOnline) {
          await _supabase.deleteTask(task.id);

          // 4. رفرش
          await syncProvider.refreshHabitsAndTasks();
        }

        // 5. رفرش دیتای صفحه
        await _loadData();
      } catch (e, stk) {
        Log.e('today', 'Error deleting task: $e', error: e, stack: stk);
        if (mounted) {
          showArenaSnack(context,
              context.tr('ah.tasks.delError', {'e': e.toString()}),
              kind: ArenaSnackKind.error);
        }
      }

      _toggleExpanded(task.id, 'task');
    }
  }

  // ==================== ویجت‌های Swipe ====================

  Widget _buildSwipeableHabitItem(Habit habit, Color primaryColor) {
    final bool isQuest = habit.questId != null;
    final bool isChallenge = habit.challengeId != null;
    final bool isEditable = !isQuest && !isChallenge;

    return Dismissible(
      key: ValueKey('dismissible_habit_${habit.id}'),
      direction: _isViewingToday
          ? DismissDirection.horizontal
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _buildSwipeBackground(
        isLeft: true,
        primaryColor: primaryColor,
        label: context.tr('ah.swipe.done'),
        icon: Icons.check_circle_outline_rounded,
      ),
      secondaryBackground: _buildSwipeBackground(
        isLeft: false,
        primaryColor: primaryColor,
        label: context.tr('ah.swipe.done'),
        icon: Icons.check_circle_outline_rounded,
      ),
      confirmDismiss: (direction) async {
        _markHabitCompleted(habit);
        return false;
      },
      child: HabitCard(
        key: ValueKey('habit_card_${habit.id}'),
        habit: habit,
        isCompleted: false,
        viewOnly: !_isViewingToday,
        recordedTimeSeconds: _habitRecordedTimes[habit.id], // پاس دادن زمان
        onToggle: () => _markHabitCompleted(habit),
        onEdit: isEditable ? () => _editHabit(habit) : () {},
        onDelete: isEditable ? () => _deleteHabit(habit) : () {},
        onTimer: isEditable && _isViewingToday ? () => _showTimerDialog(habit) : null,
        onToggleSubHabit: (subHabit) => _toggleSubHabit(habit, subHabit),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(habit: habit),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeableCompletedHabitItem(Habit habit, Color primaryColor) {
    final bool isQuest = habit.questId != null;
    final bool isChallenge = habit.challengeId != null;
    final bool isEditable = !isQuest && !isChallenge;

    return Dismissible(
      key: ValueKey('dismissible_completed_habit_${habit.id}'),
      direction: _isViewingToday
          ? DismissDirection.horizontal
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _buildSwipeBackground(
        isLeft: true,
        primaryColor: Provider.of<ThemeProvider>(context, listen: false)
            .accentGold,
        label: context.tr('ah.swipe.undo'),
        icon: Icons.refresh_rounded,
      ),
      secondaryBackground: _buildSwipeBackground(
        isLeft: false,
        primaryColor: Provider.of<ThemeProvider>(context, listen: false)
            .accentGold,
        label: context.tr('ah.swipe.undo'),
        icon: Icons.refresh_rounded,
      ),
      confirmDismiss: (direction) async {
        _unmarkHabit(habit);
        return false;
      },
      child: HabitCard(
        key: ValueKey('completed_habit_card_${habit.id}'),
        habit: habit,
        isCompleted: true,
        viewOnly: !_isViewingToday,
        onToggle: () => _unmarkHabit(habit),
        onEdit: isEditable ? () => _editHabit(habit) : () {},
        onDelete: isEditable ? () => _deleteHabit(habit) : () {},
        onTimer: isEditable && _isViewingToday ? () => _showTimerDialog(habit) : null,
        onToggleSubHabit: (subHabit) => _toggleSubHabit(habit, subHabit),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(habit: habit),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeableTaskItem(Task task, Color primaryColor) {
    return Dismissible(
      key: ValueKey('dismissible_task_${task.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _buildSwipeBackground(
        isLeft: true,
        primaryColor: primaryColor,
        label: context.tr('ah.swipe.done'),
        icon: Icons.check_circle_outline_rounded,
      ),
      secondaryBackground: _buildSwipeBackground(
        isLeft: false,
        primaryColor: primaryColor,
        label: context.tr('ah.swipe.done'),
        icon: Icons.check_circle_outline_rounded,
      ),
      confirmDismiss: (direction) async {
        _markTaskCompleted(task);
        return false;
      },
      child: TaskCard(
        key: ValueKey('task_card_${task.id}'),
        task: task,
        isCompleted: false,
        onToggle: () => _markTaskCompleted(task),
        onEdit: () => _editTask(task),
        onDelete: () => _deleteTask(task),
        onToggleSubTask: (subTask) => _toggleSubTask(task, subTask),
        onDetails: () => _showTaskDetailsDialog(task),
      ),
    );
  }

  Widget _buildSwipeableCompletedTaskItem(Task task, Color primaryColor) {
    return Dismissible(
      key: ValueKey('dismissible_completed_task_${task.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      background: _buildSwipeBackground(
        isLeft: true,
        primaryColor: Provider.of<ThemeProvider>(context, listen: false)
            .accentGold,
        label: context.tr('ah.swipe.undo'),
        icon: Icons.refresh_rounded,
      ),
      secondaryBackground: _buildSwipeBackground(
        isLeft: false,
        primaryColor: Provider.of<ThemeProvider>(context, listen: false)
            .accentGold,
        label: context.tr('ah.swipe.undo'),
        icon: Icons.refresh_rounded,
      ),
      confirmDismiss: (direction) async {
        _unmarkTask(task);
        return false;
      },
      child: TaskCard(
        key: ValueKey('completed_task_card_${task.id}'),
        task: task,
        isCompleted: true,
        onToggle: () => _unmarkTask(task),
        onEdit: () => _editTask(task),
        onDelete: () => _deleteTask(task),
        onToggleSubTask: (subTask) => _toggleSubTask(task, subTask),
        onDetails: () => _showTaskDetailsDialog(task),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required bool isLeft,
    required Color primaryColor,
    required String label,
    required IconData icon,
    Color? foreground,
  }) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final Color fg = foreground ??
        (primaryColor == theme.accentGold
            ? Colors.white
            : theme.onPrimaryColor);
    final iconWidget = Icon(icon, color: fg, size: 22);
    final text = Text(
      label,
      style: TextStyle(
        color: fg,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      alignment:
          isLeft ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [iconWidget, const SizedBox(width: 8), text]
            : [text, const SizedBox(width: 8), iconWidget],
      ),
    );
  }

  // ==================== سایر متدها ====================

  Future<HabitTimeTracking?> _getHabitTimeToday(String habitId) async {
    try {
      final user = await _supabase.getCurrentUser();
      if (user == null) return null;

      final today = DateTime.now();
      final dateStr = today.toIso8601String().split('T').first;

      final response = await _supabase.client
          .from('habit_time_tracking')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', user.id)
          .eq('date', dateStr)
          .maybeSingle();

      if (response != null) {
        return HabitTimeTracking.fromMap(response);
      }
      return null;
    } catch (e, stk) {
      Log.e('today', '_getHabitTimeToday failed', error: e, stack: stk);
      return null;
    }
  }

// lib/features/arena/screens/today_tab.dart

  void _showTimerDialog(Habit habit) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      barrierColor: const Color(0xFF090909).withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (bottomSheetContext) => SafeArea(top: false, child: Builder(builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  _TimerDialogContent(
                    habit: habit,
                    initialMinutes: habit.timerSetting?.minutes ?? 10,
                    initialSeconds: habit.timerSetting?.seconds ?? 0,
                    onSave: (minutes, seconds, isCountdown) {
                      _saveTimerSetting(
                          habit.id, minutes, seconds, isCountdown);
                    },
                    onFinished: (done) {
                      if (!done) return;
                      Future.delayed(const Duration(milliseconds: 700), () {
                        if (mounted) _markHabitCompleted(habit);
                      });
                    },
                    onComplete: () {
                      // 1. اول BottomSheet رو ببند
                      Navigator.of(bottomSheetContext).pop();

                      // 2. بعد از بسته شدن، زمان رو از سرور بخون
                      Future.microtask(() async {
                        if (!mounted) return;
                        await _reloadHabitTime(habit.id);
                        // 3. refresh سبک از سرور برای همگام‌سازی
                        try {
                          final syncProvider =
                              Provider.of<SyncProvider>(context, listen: false);
                          if (syncProvider.isOnline) {
                            await syncProvider.refreshHabitsAndTasks();
                          }
                        } catch (e, stk) {
                          Log.e('today', 'Error refreshing after timer: $e', error: e, stack: stk);
                        }

                        if (mounted) {
                          showArenaSnack(context, context.tr('at.snack.timeSaved'),
                              kind: ArenaSnackKind.success);
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      })),
    );
  }

  /// خوندن مجدد زمان رکورد شده یک عادت
  Future<void> _reloadHabitTime(String habitId) async {
    if (_currentUserId == null) return;

    try {
      final timeSeconds = await _supabase.getHabitTimeOnDate(
        habitId: habitId,
        userId: _currentUserId!,
        date: widget.selectedDate,
      );

      if (mounted) {
        setState(() {
          if (timeSeconds != null && timeSeconds > 0) {
            _habitRecordedTimes[habitId] = timeSeconds;
          } else {
            _habitRecordedTimes.remove(habitId);
          }
        });
      }
    } catch (e, stk) {
      Log.e('today', 'Error reloading habit time: $e', error: e, stack: stk);
    }
  }

  void _saveTimerSetting(
    String habitId,
    int minutes,
    int seconds,
    bool isCountdown,
  ) async {
    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      final habits = syncProvider.habits;
      final index = habits.indexWhere((h) => h.id == habitId);

      if (index == -1) return;

      final habit = habits[index];

      final timerSetting = TimerSetting(
        habitId: habitId,
        minutes: minutes,
        seconds: seconds,
        isCountdown: isCountdown,
        isEnabled: true,
      );

      final updatedHabit = Habit(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        description: habit.description,
        subHabits: habit.subHabits,
        completedSubHabits: habit.completedSubHabits,
        iconName: habit.iconName,
        iconColor: habit.iconColor,
        backgroundColor: habit.backgroundColor,
        frequencyType: habit.frequencyType,
        dailyIntervalDays: habit.dailyIntervalDays,
        weeklyDays: habit.weeklyDays,
        weeklyIntervalWeeks: habit.weeklyIntervalWeeks,
        monthlyDays: habit.monthlyDays,
        monthlyIntervalMonths: habit.monthlyIntervalMonths,
        timeOfDay: habit.timeOfDay,
        reminders: habit.reminders,
        xpReward: habit.xpReward,
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
        isActive: habit.isActive,
        createdAt: habit.createdAt,
        updatedAt: DateTime.now(),
        groupId: habit.groupId,
        startDate: habit.startDate,
        endDate: habit.endDate,
        challengeId: habit.challengeId,
        questId: habit.questId,
        timerSetting: timerSetting,
      );

      final supabase = SupabaseService();
      await supabase.updateHabit(updatedHabit);
      await syncProvider.saveHabitToLocal(updatedHabit);

      if (mounted) {
        setState(() {
          final habitIndex = _todayHabits.indexWhere((h) => h.id == habitId);
          if (habitIndex != -1) {
            _todayHabits[habitIndex] = updatedHabit;
          }
        });

        showArenaSnack(context, context.tr('at.snack.settingsSaved'),
            kind: ArenaSnackKind.success);
      }
    } catch (e, stk) {
      Log.e('today', '_saveTimerSetting failed', error: e, stack: stk);
      if (mounted) {
        showArenaSnack(context, context.tr('ad.tmr.error', {'e': e.toString()}),
            kind: ArenaSnackKind.error);
      }
    }
  }

  Future<void> _showCompleteHabitDialog(Habit habit) async {
    final yes = await showHabitTimerEndDialog(context, habit.title);
    if (yes == true && mounted) _markHabitCompleted(habit);
  }

  Future<CompletionLevel> _getHabitCompletionLevel(String habitId) async {
    try {
      final date = widget.selectedDate;
      final dateStr = date.toIso8601String().split('T').first;

      final response = await _supabase.client
          .from('habit_completions')
          .select('completion_level')
          .eq('habit_id', habitId)
          .eq('user_id', _currentUserId!)
          .eq('date', dateStr)
          .maybeSingle();

      if (response != null && response['completion_level'] != null) {
        final levelStr = response['completion_level'] as String;
        return CompletionLevelExtension.fromString(levelStr);
      }

      return CompletionLevel.full;
    } catch (e, stk) {
      Log.e('today', '_getHabitCompletionLevel failed', error: e, stack: stk);
      return CompletionLevel.full;
    }
  }

  Widget _buildTodayContent(Color primaryColor, ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_todayHabits.isNotEmpty || _todayTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._todayHabits
              .map((habit) => _buildSwipeableHabitItem(habit, primaryColor)),
          ..._todayTasks
              .map((task) => _buildSwipeableTaskItem(task, primaryColor)),
          const SizedBox(height: 16),
        ],
        if (_completedHabits.isNotEmpty || _completedTasks.isNotEmpty) ...[
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.textColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('ah.today.doneHeader'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.cardSecondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_completedHabits.length + _completedTasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._completedHabits.map((habit) =>
              _buildSwipeableCompletedHabitItem(habit, primaryColor)),
          ..._completedTasks.map(
              (task) => _buildSwipeableCompletedTaskItem(task, primaryColor)),
          const SizedBox(height: 16),
        ],
        if (_todayHabits.isEmpty &&
            _todayTasks.isEmpty &&
            _completedHabits.isEmpty &&
            _completedTasks.isEmpty)
          ArenaStateView(
            icon: Icons.check_circle_outline_rounded,
            title: context.tr('ah.today.emptyTitle'),
            subtitle: context.tr('ah.today.emptySub'),
            actionLabel: context.tr('ah.fab.habit'),
            actionIcon: Icons.add_rounded,
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategorySelectionScreen()),
            ).then((_) => refreshData()),
          ),
      ],
    );
  }
}
