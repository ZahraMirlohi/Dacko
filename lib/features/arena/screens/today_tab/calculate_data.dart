// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از today_tab.dart (بدون تغییر رفتار): refreshData, _resetState, _initAnimation, _calculateTotalItems, _calculateAndUpdateProgress, _resetTotalItems…
part of '../today_tab.dart';

extension TodayTabStateCalculateData on TodayTabState {

  void refreshData() {
    if (!_isLoading) {
      _cacheTime = null;
      _cachedHabits = null;
      _cachedTasks = null;
      _loadData();
    }
  }

  // ==================== متدهای کمکی ====================

  void _resetState() {
    _initialCountSet = false;
    _hasShownCongratulationToday = false;
    _expandedItemId = null;
    _expandedType = null;
    _expandedSubItemId = null;
  }

  void _initAnimation(String id) {
    if (!_animationControllers.containsKey(id)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
      _animationControllers[id] = controller;
      _animations[id] = animation;
    }
  }

  void _calculateTotalItems() {
    final allHabits = _todayHabits + _completedHabits;
    final allTasks = _todayTasks + _completedTasks;

    final uniqueHabits = <String, Habit>{};
    for (var habit in allHabits) {
      if (!uniqueHabits.containsKey(habit.id)) {
        uniqueHabits[habit.id] = habit;
      }
    }

    _totalTodayItems = uniqueHabits.length + allTasks.length;
    _completedItems = _completedHabits.length + _completedTasks.length;
  }

  void _calculateAndUpdateProgress() {
    if (_totalTodayItems == 0) {
      _calculateTotalItems();
    }

    _completedItems = _completedHabits.length + _completedTasks.length;

    double progress =
        _totalTodayItems > 0 ? _completedItems / _totalTodayItems : 0.0;

    if (progress > 1.0) {
      progress = 1.0;
    }

    if (widget.onProgressUpdate != null) {
      widget.onProgressUpdate!(progress);
    }
    widget.onStatsUpdate?.call(_completedItems, _totalTodayItems);
  }

  void _resetTotalItems() {
    _totalTodayItems = 0;
    _calculateTotalItems();
    _calculateAndUpdateProgress();
  }

  // ==================== متد تبریک ====================

  void _checkAllCompletedAndShowCongratulation() {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastCheckDate == today && _hasShownCongratulationToday) return;

    final hadAnyTaskForToday = _initialTodayItemsCount > 0;
    final allPendingEmpty = _todayHabits.isEmpty && _todayTasks.isEmpty;

    if (hadAnyTaskForToday && allPendingEmpty) {
      final hasAnyCompleted =
          _completedHabits.isNotEmpty || _completedTasks.isNotEmpty;
      if (!hasAnyCompleted) {
        return;
      }

      int todayXP = 0;
      for (var habit in _completedHabits) {
        todayXP += habit.xpReward;
      }
      for (var task in _completedTasks) {
        todayXP += task.xpReward;
      }

      _hasShownCongratulationToday = true;
      _lastCheckDate = today;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CongratulationScreen(
                todayXP: todayXP,
                totalTasksCompleted: _completedTasks.length,
                totalHabitsCompleted: _completedHabits.length,
              ),
            ),
          ).then((_) {
            if (mounted) {
              _loadData();
            }
          });
        }
      });
    }
  }

  int _calculateTodayXP() {
    int totalXP = 0;
    for (var habit in _completedHabits) {
      totalXP += habit.xpReward;
    }
    for (var task in _completedTasks) {
      totalXP += task.xpReward;
    }
    return totalXP;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // فقط بار اول «در حال بارگذاری» نشان بده؛ رفرش‌های بعدی بی‌صدا جایگزین می‌شوند
    if (!_hasLoadedOnce) setState(() => _isLoading = true);

    try {
      final user = await _supabase.getCurrentUser();
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _currentUserId = user.id;

      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      List<Habit> allHabits = [];
      if (syncProvider.habits.isNotEmpty) {
        allHabits = syncProvider.habits;
      } else if (syncProvider.isOnline) {
        allHabits = await _supabase.getHabits(_currentUserId!);
      }

      List<Task> allTasks = [];
      if (syncProvider.tasks.isNotEmpty) {
        allTasks = syncProvider.tasks;
      } else if (syncProvider.isOnline) {
        allTasks = await _supabase.getTasks(_currentUserId!);
      }

      final List<Habit> pendingHabits = [];
      final List<Habit> completedHabits = [];

      // دو درخواست برای کل روز (قبلاً دو درخواست برای هر عادت بود)
      Set<String>? completedIds;
      if (syncProvider.isOnline) {
        final results = await Future.wait([
          _supabase.getCompletedHabitIdsOnDate(
              _currentUserId!, widget.selectedDate),
          _supabase.getHabitTimesOnDate(_currentUserId!, widget.selectedDate),
        ]);
        completedIds = results[0] as Set<String>?;
        _habitRecordedTimes.addAll(results[1] as Map<String, int>);
      }

      for (var habit in allHabits) {
        if (!habit.isActive) continue;

        bool shouldShow = false;

        if (habit.questId != null) {
          shouldShow = habit.shouldShowQuestOnDate(widget.selectedDate);
        } else if (habit.challengeId != null) {
          shouldShow = habit.shouldDoOnDate(widget.selectedDate);
        } else {
          shouldShow = habit.shouldDoOnDate(widget.selectedDate);
        }

        if (!shouldShow) continue;

        // آفلاین یا خطا: به وضعیتی که قبلاً در حافظه داریم تکیه می‌کنیم
        final isCompleted = completedIds != null
            ? completedIds.contains(habit.id)
            : (_habitCompletionStatus[habit.id] == true);

        if (isCompleted) {
          completedHabits.add(habit);
          _habitCompletionStatus[habit.id] = true;
        } else {
          pendingHabits.add(habit);
        }
      }

      final List<Task> pendingTasks = [];
      final List<Task> completedTasks = [];

      for (var task in allTasks) {
        if (task.dueDate == null) continue;
        if (!task.isForDate(widget.selectedDate)) continue;

        if (task.isCompleted) {
          completedTasks.add(task);
          _taskCompletedStatus[task.id] = true;
        } else {
          pendingTasks.add(task);
        }
      }

      if (mounted) {
        setState(() {
          _todayHabits = pendingHabits;
          _todayTasks = pendingTasks;
          _completedHabits = completedHabits;
          _completedTasks = completedTasks;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }

      _resetTotalItems();

      // مرور دیروز و پرسش‌های مربی؛ بعد از نمایش امروز و فقط وقتی امروز دیده می‌شود
      if (_isViewingToday && mounted) {
        unawaited(runDailyFlows(context, onChanged: _loadData));
      }
    } catch (e, stk) {
      Log.e('today', 'Error loading data: $e', error: e, stack: stk);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== متدهای تکمیل عادت و وظیفه ====================

  Future<void> _markHabitCompleted(Habit habit) async {
    if (!mounted || !_isViewingToday) return;

    final level = await showDialog<CompletionLevel>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CompletionLevelPicker(
        habitTitle: habit.title,
        habitXpReward: habit.xpReward,
        habitId: habit.id,
        isQuest: habit.questId != null,
        isChallenge: habit.challengeId != null,
        fullDescription: habit.fullDescription,
        halfDescription: habit.halfDescription,
        basicDescription: habit.basicDescription,
        targetValue: habit.targetValue,
        onSelected: (selectedLevel) {
          Navigator.pop(context, selectedLevel);
        },
      ),
    );

    if (level == null || !mounted) return;

    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    setState(() {
      _todayHabits.remove(habit);
      if (!_completedHabits.contains(habit)) {
        _completedHabits.add(habit);
      }
      _habitCompletionStatus[habit.id] = true;
    });

    _calculateAndUpdateProgress();

    final xpEarned = (habit.xpReward * level.xpMultiplier / 100).round();
    SoundService.instance
        .play(level == CompletionLevel.full ? Sfx.complete : Sfx.check);
    if (mounted) {
      showArenaSnack(
        context,
        context.tr('ah.today.xpEarned', {'xp': '$xpEarned'}),
        kind: ArenaSnackKind.success,
        duration: const Duration(milliseconds: 1200),
        clearPrevious: true,
      );
    }

    _scheduleProfileRefresh();
    _performDatabaseOperations(habit, level, xpEarned);
  }

  Future<void> _performDatabaseOperations(
      Habit habit, CompletionLevel level, int xpEarned) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    try {
      if (syncProvider.isOnline) {
        await Future.wait([
          _supabase.markHabitCompletedWithLevel(
            habitId: habit.id,
            userId: _currentUserId!,
            date: widget.selectedDate,
            level: level,
          ),
          _supabase.recordDailyActivity(
            userId: _currentUserId!,
            date: widget.selectedDate,
            habitsCompleted: _completedHabits.length,
            tasksCompleted: _completedTasks.length,
            xpEarned: _calculateTodayXP(),
            isActive: true,
          ),
        ]);

        if (habit.challengeId != null) {
          // ترتیبی (نه همزمان): اول ثبت روز، بعد شمارش پیشرفت
          try {
            await _supabase.completeChallengeDay(
              userId: _currentUserId!,
              challengeId: habit.challengeId!,
              date: widget.selectedDate,
            );
          } catch (e, stk) {
            Log.e('today', '_performDatabaseOperations failed', error: e, stack: stk);
            if (mounted) {
              showArenaSnack(context, 'ثبت پیشرفت چالش ناموفق بود: $e',
                  kind: ArenaSnackKind.error);
            }
          }

          if (widget.profileRefreshNotifier != null) {
            widget.profileRefreshNotifier!.value++;
          }
          unawaited(_checkAndCompleteChallenge(habit));
        }

        if (habit.questId != null) {
          unawaited(_handleQuestCompletion(habit));
        }

        _scheduleProfileRefresh();
      } else {
        await syncProvider.addOfflineOperation(
          type: OperationType.completeHabitWithLevel,
          data: {
            'habitId': habit.id,
            'date': widget.selectedDate.toIso8601String(),
            'xpReward': habit.xpReward,
            'level': level.toString().split('.').last,
          },
        );
        if (mounted) {
          showArenaSnack(
            context,
            context.tr('ah.today.doneOffline'),
            kind: ArenaSnackKind.warning,
            duration: const Duration(milliseconds: 1200),
            clearPrevious: true,
          );
        }
      }

      _checkAllCompletedAndShowCongratulation();
    } catch (e, stk) {
      Log.e('today', 'Error in database operations: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _habitCompletionStatus[habit.id] = false;
          _completedHabits.remove(habit);
          if (habit.shouldDoOnDate(widget.selectedDate) &&
              !_todayHabits.contains(habit)) {
            _todayHabits.add(habit);
          }
        });

        showArenaSnack(context, context.tr('ad.tmr.error', {'e': e.toString()}),
            kind: ArenaSnackKind.error);
      }
    }
  }

  Future<void> _checkAndCompleteChallenge(Habit habit) async {
    try {
      final completedChallenge = await _supabase.checkAndCompleteChallenge(
          _currentUserId!, habit.challengeId!);

      if (completedChallenge != null && mounted) {
        if (widget.profileRefreshNotifier != null) {
          widget.profileRefreshNotifier!.value++;
        }

        final progress = await _supabase.getUserChallengeProgressDetails(
          _currentUserId!,
          habit.challengeId!,
        );

        final completedDays = progress['completedDays'] ?? 0;
        final totalDays = progress['totalDays'] ?? 3;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeCompletionScreen(
              challenge: completedChallenge,
              completedDays: completedDays,
              totalDays: totalDays,
            ),
          ),
        );

        _hasShownCongratulationToday = false;
        _initialCountSet = false;

        if (mounted) {
          await _loadData();
        }
      }
    } catch (e, stk) {
      Log.e('today', 'Challenge completion check error: $e', error: e, stack: stk);
    }
  }

  Future<void> _handleQuestCompletion(Habit habit) async {
    try {
      if (habit.questId == null) return;

      final completedQuest =
          await _supabase.updateQuestProgress(_currentUserId!, habit.id);

      if (completedQuest != null && mounted) {
        await _loadData();

        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        await syncProvider.forceRefresh();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestCompletionScreen(
              quest: completedQuest,
              completedDays: completedQuest.targetCount,
            ),
          ),
        );

        if (mounted) {
          await _loadData();
        }
      }
    } catch (e, stk) {
      Log.e('today', 'Quest completion error: $e', error: e, stack: stk);
    }
  }

  void _scheduleProfileRefresh() {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > TodayTabState._minRefreshInterval) {
      _lastRefreshTime = now;

      try {
        if (widget.profileRefreshNotifier != null) {
          widget.profileRefreshNotifier!.value++;
        }
      } catch (e, stk) {
        Log.e('today', 'Profile refresh error: $e', error: e, stack: stk);
      }
    }
  }

  Future<void> _unmarkHabit(Habit habit) async {
    if (!_isViewingToday) return;
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    SoundService.instance.play(Sfx.tap);

    setState(() {
      _completedHabits.remove(habit);
      if (habit.shouldDoOnDate(widget.selectedDate) &&
          !_todayHabits.contains(habit)) {
        _todayHabits.add(habit);
      }
      _habitCompletionStatus[habit.id] = false;
    });

    _calculateAndUpdateProgress();

    Future.microtask(() async {
      try {
        if (syncProvider.isOnline) {
          await _supabase.uncompleteHabitAndRefundXp(
            habitId: habit.id,
            userId: _currentUserId!,
            date: widget.selectedDate,
          );

          if (habit.challengeId != null) {
            await _supabase.removeChallengeDay(
              userId: _currentUserId!,
              challengeId: habit.challengeId!,
              date: widget.selectedDate,
            );
            await _supabase.updateChallengeProgress(
              _currentUserId!,
              habit.challengeId!,
            );
          }

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
          _hasShownCongratulationToday = false;
          _checkAllCompletedAndShowCongratulation();
          await _loadData();
        } else {
          await syncProvider.addOfflineOperation(
            type: OperationType.uncompleteHabit,
            data: {
              'habitId': habit.id,
              'date': widget.selectedDate.toIso8601String(),
              'xpReward': habit.xpReward,
              'challengeId': habit.challengeId,
            },
          );
        }

        if (habit.questId != null && syncProvider.isOnline) {
          unawaited(_recalculateQuestProgress(_currentUserId!, habit.questId!));
        }
      } catch (e, stk) {
        Log.e('today', 'Error unmarking habit: $e', error: e, stack: stk);
        if (mounted) {
          setState(() {
            _habitCompletionStatus[habit.id] = true;
            _completedHabits.add(habit);
            _todayHabits.remove(habit);
          });
          showArenaSnack(context, context.tr('ad.tmr.error', {'e': e.toString()}),
            kind: ArenaSnackKind.error);
        }
      }
    });
  }
}
