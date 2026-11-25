// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از today_tab.dart (بدون تغییر رفتار): _checkIfTodayHasOtherActivities, _recalculateQuestProgress, _markTaskCompleted, _unmarkTask, _getIconData, _showHabitDetailsDialog…
part of '../today_tab.dart';

extension TodayTabStateTaskHabit on TodayTabState {

  Future<bool> _checkIfTodayHasOtherActivities() async {
    final hasCompletedHabits = _completedHabits.isNotEmpty;
    final hasCompletedTasks = _completedTasks.isNotEmpty;

    if (hasCompletedHabits || hasCompletedTasks) {
      return true;
    }

    try {
      final todayStr = widget.selectedDate.toIso8601String().split('T').first;

      final habitCompletions = await _supabase.client
          .from('habit_completions')
          .select('id, habit_id')
          .eq('user_id', _currentUserId!)
          .eq('date', todayStr);

      if (habitCompletions.isNotEmpty) {
        for (var completion in habitCompletions) {
          final habitId = completion['habit_id'];
          final habit = await _supabase.client
              .from('habits')
              .select('challenge_id, quest_id')
              .eq('id', habitId)
              .maybeSingle();

          if (habit != null &&
              habit['challenge_id'] == null &&
              habit['quest_id'] == null) {
            return true;
          }
        }
      }

      final challengeCompletions = await _supabase.client
          .from('challenge_completions')
          .select('id')
          .eq('user_id', _currentUserId!)
          .eq('date', todayStr)
          .limit(1);

      if (challengeCompletions.isNotEmpty) {
        return true;
      }

      final tasks = await _supabase.client
          .from('tasks')
          .select('id')
          .eq('user_id', _currentUserId!)
          .eq('is_completed', true)
          .eq('due_date', todayStr)
          .limit(1);

      if (tasks.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e, stk) {
      Log.e('today', '_checkIfTodayHasOtherActivities failed', error: e, stack: stk);
      return false;
    }
  }

  Future<void> _recalculateQuestProgress(String userId, String questId) async {
    try {
      final habits = await _supabase.getHabits(userId);
      final questHabits = habits.where((h) => h.questId == questId).toList();

      int completedCount = 0;
      for (var habit in questHabits) {
        final isCompleted = await _supabase.isHabitCompletedOnDate(
          habit.id,
          userId,
          DateTime.now(),
        );
        if (isCompleted) completedCount++;
      }

      final userQuests = await _supabase.getUserQuests(userId);
      final userQuest = userQuests.firstWhere(
        (uq) => uq.questId == questId && uq.isActive,
      );

      await _supabase.client
          .from('user_quests')
          .update({'progress': completedCount}).eq('id', userQuest.id);
    } catch (e, stk) {
      Log.e('today', 'Error recalculating quest progress: $e', error: e, stack: stk);
    }
  }

  Future<void> _markTaskCompleted(Task task) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    setState(() {
      task.isCompleted = true;
      _taskCompletedStatus[task.id] = true;
      _todayTasks.remove(task);
      if (!_completedTasks.contains(task)) {
        _completedTasks.add(task);
      }
      _initialTodayItemsCount = _todayHabits.length + _todayTasks.length;
    });

    _calculateAndUpdateProgress();

    SoundService.instance.play(Sfx.complete);

    try {
      if (syncProvider.isOnline) {
        await Future.wait([
          _supabase.updateTask(task),
          _supabase.addXP(_currentUserId!, task.xpReward),
          _supabase.recordDailyActivity(
            userId: _currentUserId!,
            date: widget.selectedDate,
            tasksCompleted: 1,
            xpEarned: task.xpReward,
            isActive: true,
          ),
        ]);
        _scheduleProfileRefresh();
      } else {
        await syncProvider.addOfflineOperation(
          type: OperationType.completeTask,
          data: {...task.toMap(), 'id': task.id, 'xpReward': task.xpReward},
        );
      }

      if (mounted) {
        showArenaSnack(
          context,
          syncProvider.isOnline
              ? context.tr('ah.today.xpEarned', {'xp': '${task.xpReward}'})
              : context.tr('ah.today.taskOffline'),
          kind: syncProvider.isOnline
              ? ArenaSnackKind.success
              : ArenaSnackKind.warning,
          duration: const Duration(milliseconds: 1200),
          clearPrevious: true,
        );
      }

      _checkAllCompletedAndShowCongratulation();
    } catch (e, stk) {
      Log.e('today', '_markTaskCompleted failed', error: e, stack: stk);
      setState(() {
        task.isCompleted = false;
        _taskCompletedStatus[task.id] = false;
        _completedTasks.remove(task);
        if (task.isForDate(widget.selectedDate) &&
            !_todayTasks.contains(task)) {
          _todayTasks.add(task);
        }
      });
    }
  }

  Future<void> _unmarkTask(Task task) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    setState(() {
      task.isCompleted = false;
      _taskCompletedStatus[task.id] = false;
      _completedTasks.remove(task);
      if (task.isForDate(widget.selectedDate) && !_todayTasks.contains(task)) {
        _todayTasks.add(task);
      }
      _initialTodayItemsCount = _todayHabits.length + _todayTasks.length;
    });

    _calculateAndUpdateProgress();

    try {
      final updatedTask = Task(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        subTasks: task.subTasks,
        completedSubTasks: task.completedSubTasks,
        dueDate: task.dueDate,
        isCompleted: false,
        xpReward: task.xpReward,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );

      if (syncProvider.isOnline) {
        await _supabase.updateTask(updatedTask);
        await _supabase.removeXP(_currentUserId!, task.xpReward);

        final hasOtherActivities = await _checkIfTodayHasOtherActivities();

        if (!hasOtherActivities) {
          await _supabase.recordDailyActivity(
            userId: _currentUserId!,
            date: widget.selectedDate,
            habitsCompleted: 0,
            tasksCompleted: 0,
            xpEarned: 0,
            isActive: false,
          );
          await _supabase.updateUserStreak(_currentUserId!);
          _scheduleProfileRefresh();
        } else {
          await _supabase.recordDailyActivity(
            userId: _currentUserId!,
            date: widget.selectedDate,
            habitsCompleted: _completedHabits.length,
            tasksCompleted: _completedTasks.length,
            xpEarned: _calculateTodayXP(),
            isActive: true,
          );
        }

        _scheduleProfileRefresh();
      } else {
        await syncProvider.addOfflineOperation(
          type: OperationType.uncompleteTask,
          data: {
            ...updatedTask.toMap(),
            'id': updatedTask.id,
            'xpReward': updatedTask.xpReward,
          },
        );
      }

      _hasShownCongratulationToday = false;
      _checkAllCompletedAndShowCongratulation();
    } catch (e, stk) {
      Log.e('today', '_unmarkTask failed', error: e, stack: stk);
      setState(() {
        task.isCompleted = true;
        _taskCompletedStatus[task.id] = true;
        _completedTasks.add(task);
        _todayTasks.remove(task);
      });
    }
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

  void _showHabitDetailsDialog(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
    );
  }

  void _showTaskDetailsDialog(Task task) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    String dueDateStr = '';
    if (task.dueDate != null) {
      dueDateStr = await DateService.formatDate(task.dueDate!);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF090909).withValues(alpha: 0.42),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(task.isCompleted ? 'ah.td.done' : 'ah.td.pending'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? theme.successColor
                            : theme.cardSecondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle_outline_rounded
                            : Icons.assignment_outlined,
                        color: task.isCompleted
                            ? const Color(0xFF090909)
                            : theme.textSecondaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.description.isEmpty
                                ? context.tr('ah.td.noDesc')
                                : task.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: theme.cardSecondaryColor),
                const SizedBox(height: 14),
                if (task.dueDate != null) ...[
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    context.tr('ah.td.due'),
                    dueDateStr,
                    theme,
                  ),
                  const SizedBox(height: 14),
                ],
                _buildDetailRow(
                  Icons.star_outline_rounded,
                  context.tr('ah.td.xp'),
                  '${task.xpReward} XP',
                  theme,
                ),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, ThemeProvider theme) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.textColor, size: 19),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const Spacer(),
        Text(value,
            style: TextStyle(fontSize: 14, color: theme.textSecondaryColor)),
      ],
    );
  }

  Future<void> _toggleSubHabit(Habit habit, String subHabit) async {
    List<String> newCompletedSubHabits = List.from(habit.completedSubHabits);

    if (newCompletedSubHabits.contains(subHabit)) {
      newCompletedSubHabits.remove(subHabit);
    } else {
      newCompletedSubHabits.add(subHabit);
    }

    final updatedHabit = Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      subHabits: habit.subHabits,
      completedSubHabits: newCompletedSubHabits,
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
      timerSetting: habit.timerSetting,
    );

    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    setState(() {
      final todayIndex = _todayHabits.indexWhere((h) => h.id == habit.id);
      if (todayIndex != -1) {
        _todayHabits[todayIndex] = updatedHabit;
      }

      final completedIndex =
          _completedHabits.indexWhere((h) => h.id == habit.id);
      if (completedIndex != -1) {
        _completedHabits[completedIndex] = updatedHabit;
      }
    });

    await syncProvider.saveHabitToLocal(updatedHabit);

    if (syncProvider.isOnline) {
      await _supabase.updateHabit(updatedHabit);
    } else {
      await syncProvider.addOfflineOperation(
        type: OperationType.updateHabit,
        data: updatedHabit.toMap(),
      );
    }
  }

  void _toggleExpanded(String id, String type) {
    setState(() {
      if (_expandedItemId == id && _expandedType == type) {
        if (_animationControllers.containsKey(id)) {
          _animationControllers[id]!.reverse();
        }
        _expandedItemId = null;
        _expandedType = null;
        _expandedSubItemId = null;
      } else {
        if (_expandedItemId != null &&
            _animationControllers.containsKey(_expandedItemId)) {
          _animationControllers[_expandedItemId]!.reverse();
        }
        _initAnimation(id);
        _animationControllers[id]!.forward();
        _expandedItemId = id;
        _expandedType = type;
        _expandedSubItemId = null;
      }
    });
  }

  Future<void> _toggleSubTask(Task task, String subTask) async {
    List<String> newCompletedSubTasks = List.from(task.completedSubTasks);

    if (newCompletedSubTasks.contains(subTask)) {
      newCompletedSubTasks.remove(subTask);
    } else {
      newCompletedSubTasks.add(subTask);
    }

    final updatedTask = Task(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      subTasks: task.subTasks,
      completedSubTasks: newCompletedSubTasks,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      xpReward: task.xpReward,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    setState(() {
      final todayIndex = _todayTasks.indexWhere((t) => t.id == task.id);
      if (todayIndex != -1) {
        _todayTasks[todayIndex] = updatedTask;
      }

      final completedIndex = _completedTasks.indexWhere((t) => t.id == task.id);
      if (completedIndex != -1) {
        _completedTasks[completedIndex] = updatedTask;
      }
    });

    await syncProvider.saveTaskToLocal(updatedTask);

    if (syncProvider.isOnline) {
      await _supabase.updateTask(updatedTask);
    } else {
      await syncProvider.addOfflineOperation(
        type: OperationType.updateTask,
        data: {...updatedTask.toMap(), 'id': updatedTask.id},
      );
    }
  }

  void _editHabit(Habit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => edit_habit.EditHabitScreen(habit: habit),
      ),
    );

    if (result == true && mounted) {
      print('Habit edited, reloading data...');

      _cacheTime = null;
      _cachedHabits = null;
      _cachedTasks = null;

      await _loadData();
      print('Today tab data reloaded');
    }

    _toggleExpanded(habit.id, 'habit');
  }

  void _deleteHabit(Habit habit) async {
    final confirm = await showArenaDeleteDialog(
      context,
      title: context.tr('ah.habits.delTitle'),
      message: context.tr('ah.habits.delMsg'),
    );

    if (confirm == true && mounted) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 1. حذف از state محلی
      setState(() {
        _todayHabits.removeWhere((h) => h.id == habit.id);
        _completedHabits.removeWhere((h) => h.id == habit.id);
      });

      // 2. حذف از LocalStorage
      syncProvider.removeHabit(habit.id);

      try {
        // 3. حذف از Supabase
        if (syncProvider.isOnline) {
          await _supabase.deleteHabit(habit.id);

          // 4. رفرش
          await syncProvider.refreshHabitsAndTasks();
        }

        // 5. رفرش دیتای صفحه
        await _loadData();
      } catch (e, stk) {
        Log.e('today', 'Error deleting habit: $e', error: e, stack: stk);
        if (mounted) {
          showArenaSnack(context,
              context.tr('ah.habits.delError', {'e': e.toString()}),
              kind: ArenaSnackKind.error);
        }
      }

      _toggleExpanded(habit.id, 'habit');
    }
  }
}
