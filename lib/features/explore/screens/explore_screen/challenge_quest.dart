// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از explore_screen.dart (بدون تغییر رفتار): _onRefreshTriggered, forceRefresh, _loadData, _loadFromSupabase, _processChallenges, _processCompletedQuests…
part of '../explore_screen.dart';

extension _ExploreScreenStateChallengeQuest on _ExploreScreenState {

  void _onRefreshTriggered() {
    print('Refresh triggered from notifier');
    _challengeDetailsCache.clear();
    _isInitialized = false;
    _isLoadingInProgress = false;
    _loadData();
  }

  Future<void> forceRefresh() {
    _challengeDetailsCache.clear();
    _isInitialized = false;
    _isLoadingInProgress = false;
    return _loadData();
  }

  Future<void> _loadData() async {
    if (_isInitialized || _isLoadingInProgress) return;
    if (!mounted) return;

    print('_loadData: Starting...');
    _isLoadingInProgress = true;

    setState(() {
      if (!_hasLoadedOnce) _isLoading = true;
      _errorMessage = '';
    });

    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      final currentUser = await _supabase.getCurrentUser();


      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = context.tr('ex.login_first');
            _isLoading = false;
            _isInitialized = true;
            _isLoadingInProgress = false;
          });
        }
        return;
      }

      _currentUserId = currentUser.id;

      bool hasLocalData = false;

      if (syncProvider.hasChallenges) {
        _challenges = syncProvider.challenges;
        _myChallenges = syncProvider.userChallenges;
        hasLocalData = true;
      }

      if (syncProvider.packages.isNotEmpty) {
        _templatePackages = syncProvider.packages;
        hasLocalData = true;
      }

      if (syncProvider.quests.isNotEmpty) {
        _quests = syncProvider.quests;
        hasLocalData = true;
      }

      if (_currentUserId.isNotEmpty) {
        // دو بررسی مستقل همزمان اجرا می‌شوند (قبلاً پشت سر هم، کند)
        await Future.wait([
          _supabase.checkAndUpdateUserChallenges(_currentUserId),
          _supabase.checkUserChallengeStreak(_currentUserId),
        ]);
      }

      if (syncProvider.isOnline) {
        await _loadFromSupabase(syncProvider);
      } else if (!hasLocalData) {
        setState(() {
          _errorMessage = 'ex.err.offline';
          _isLoading = false;
          _isInitialized = true;
          _isLoadingInProgress = false;
        });
        return;
      }

      _processChallenges();
      _processCompletedQuests();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
          _isInitialized = true;
          _isLoadingInProgress = false;
        });
      }
    } catch (e, stk) {
      Log.e('explore', '_loadData: Error - $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _errorMessage = 'ex.err.db';
          _errorDetail = e.toString();
          _isLoading = false;
          _isInitialized = true;
          _isLoadingInProgress = false;
        });
      }
    }
  }

  Future<void> _loadFromSupabase(SyncProvider syncProvider) async {
    try {
      final results = await Future.wait([
        _supabase.getChallenges(),
        _supabase.getUserChallenges(_currentUserId),
        _supabase.getPackages(),
        _supabase.getQuests(),
        _supabase.getUserQuests(_currentUserId),
      ]);

      final newChallenges = results[0] as List<Map<String, dynamic>>;
      final newUserChallenges = results[1] as List<Map<String, dynamic>>;
      final newPackages = results[2] as List<Package>;
      final newQuests = results[3] as List<Quest>;
      final userQuests = results[4] as List<UserQuest>;

      if (newChallenges.isNotEmpty) {
        _challenges = newChallenges;
        await syncProvider.saveChallengesToLocal(newChallenges);
      }

      // بدون شرط خالی نبودن: حذف آخرین چالش فعال هم باید دیده شود
      _myChallenges = newUserChallenges;
      await syncProvider.saveUserChallengesToLocal(newUserChallenges);

      if (newPackages.isNotEmpty) {
        _templatePackages = newPackages;
        await syncProvider.savePackagesToLocal(newPackages);
      }

      if (newQuests.isNotEmpty) {
        _quests = newQuests;
        await syncProvider.saveQuestsToLocal(newQuests);
      }

      final completedQuestIds = userQuests
          .where((uq) => uq.isCompleted == true)
          .map((uq) => uq.questId)
          .toList();

      _completedQuests =
          _quests.where((q) => completedQuestIds.contains(q.id)).toList();
    } catch (e, stk) {
      Log.e('explore', 'Background sync error: $e', error: e, stack: stk);
    }
  }

  void _processChallenges() {
    for (int i = 0; i < _challenges.length; i++) {
      final challenge = _challenges[i];
      final challengeId = challenge['id'];

      _challenges[i]['isRegistrationClosed'] = false;
      _challenges[i]['daysLeft'] = 999;

      final isJoined = _myChallenges.any((c) => c['id'] == challengeId);
      _challenges[i]['isJoined'] = isJoined;

      if (isJoined) {
        final userChallenge = _myChallenges.firstWhere(
          (c) => c['id'] == challengeId,
          orElse: () => {},
        );
        if (userChallenge.isNotEmpty) {
          _challenges[i]['isCompleted'] = userChallenge['isCompleted'] ?? false;
          _challenges[i]['status'] = userChallenge['status'] ?? 'active';
          _challenges[i]['progress'] = userChallenge['progress'] ?? 0;
        }
      } else {
        _challenges[i]['isCompleted'] = false;
        _challenges[i]['status'] = null;
        _challenges[i]['progress'] = 0;
      }
    }
  }

  void _processCompletedQuests() {}

  Future<void> _joinChallenge(Map<String, dynamic> challenge) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(context.tr('ex.ch.joining')),
            ],
          ),
          backgroundColor: Color(0xFF4A90E2),
          duration: Duration(seconds: 1),
        ),
      );
    }

    _isLoadingInProgress = true;
    if (mounted) setState(() => _isLoading = true);

    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser != null) {
        await _supabase.joinChallenge(currentUser.id, challenge['id']);

        final newChallenge = Map<String, dynamic>.from(challenge);
        newChallenge['isJoined'] = true;
        newChallenge['isCompleted'] = false;
        newChallenge['status'] = 'active';
        newChallenge['is_active'] = true;

        if (mounted) {
          setState(() {
            _myChallenges.add(newChallenge);
            _challenges.removeWhere((c) => c['id'] == challenge['id']);
            _challenges.add(newChallenge);
          });
        }

        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        unawaited(syncProvider.manualSync());

        if (widget.refreshNotifier != null) {
          widget.refreshNotifier!.value++;
        }

        _isInitialized = false;
        _isLoadingInProgress = false;
        unawaited(_loadData());

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ex.ch.joined')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stk) {
      Log.e('explore', '_joinChallenge failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ex.error', {'n': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveChallenge(Map<String, dynamic> challenge) async {
    _isLoadingInProgress = true;
    if (mounted) setState(() => _isLoading = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(context.tr('ex.ch.leaving')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser != null) {
        await _supabase.leaveChallenge(currentUser.id, challenge['id']);

        if (mounted) {
          setState(() {
            _myChallenges.removeWhere((c) => c['id'] == challenge['id']);
            _challenges.removeWhere((c) => c['id'] == challenge['id']);

            final updatedChallenge = Map<String, dynamic>.from(challenge);
            updatedChallenge['isJoined'] = false;
            updatedChallenge['isCompleted'] = false;
            updatedChallenge['status'] = null;
            updatedChallenge['is_active'] = false;
            _challenges.add(updatedChallenge);
          });
        }

        _challengeDetailsCache.remove(challenge['id']);

        if (mounted) {
          final syncProvider =
              Provider.of<SyncProvider>(context, listen: false);
          syncProvider.removeHabitsByChallengeId(challenge['id']);
          syncProvider.removeUserChallenge(challenge['id']);
          unawaited(syncProvider.manualSync());
        }

        _isInitialized = false;
        _isLoadingInProgress = false;
        unawaited(_loadData());

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ex.ch.left', {'n': '${challenge['title']}'})),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stk) {
      Log.e('explore', '_leaveChallenge failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ex.error', {'n': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startQuest(Quest quest) async {
    if (!mounted) return;

    _isLoadingInProgress = true;
    if (mounted) setState(() => _isLoading = true);

    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ex.login_first')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _supabase.startQuest(currentUser.id, quest);

      try {
        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        await syncProvider.manualSync();
      } catch (e) {
        try {
          final habits = await _supabase.getHabits(currentUser.id);
          final localStorage = LocalStorageService();
          await localStorage.saveHabits(habits);
        } catch (e2, stk) {
          Log.e('explore', 'Error updating LocalStorage: $e2', error: e2, stack: stk);
        }
      }

      _isInitialized = false;
      _isLoadingInProgress = false;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ex.q.started', {'n': quest.title})),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('explore', 'Error in _startQuest: $e', error: e, stack: stk);
      if (mounted) {
        String message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelQuest(Quest quest) async {
    _isLoadingInProgress = true;
    if (mounted) setState(() => _isLoading = true);

    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser != null) {
        await _supabase.cancelQuest(currentUser.id, quest.id);

        try {
          final localStorage = LocalStorageService();
          final habits = localStorage.getHabits();
          final updatedHabits =
              habits.where((h) => h.questId != quest.id).toList();
          await localStorage.saveHabits(updatedHabits);
        } catch (e, stk) {
          Log.e('explore', 'Error updating LocalStorage: $e', error: e, stack: stk);
        }

        _isInitialized = false;
        _isLoadingInProgress = false;
        await _loadData();

        if (widget.refreshNotifier != null) {
          widget.refreshNotifier!.value++;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ex.q.left', {'n': quest.title})),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stk) {
      Log.e('explore', '_cancelQuest failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ex.error', {'n': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // کلیک‌های پشت‌سرهم (اینترنت کند) فقط یک صفحه باز می‌کند
  void _showChallengeDetailsDialog(Map<String, dynamic> challenge) async {
    if (_detailChallengeDetailsDialogBusy || ModalRoute.of(context)?.isCurrent == false) return;
    _detailChallengeDetailsDialogBusy = true;
    try {
      await _showChallengeDetailsDialogImpl(challenge);
    } finally {
      _detailChallengeDetailsDialogBusy = false;
    }
  }

  Future<void> _showChallengeDetailsDialogImpl(Map<String, dynamic> challenge) async {
    try {
      final challengeId = challenge['id'];

      if (_challengeDetailsCache.containsKey(challengeId)) {
        final cached = _challengeDetailsCache[challengeId]!;
        if (DateTime.now().difference(cached.timestamp) <
            const Duration(seconds: 10)) {
          _showChallengeDetailsDialogWithData(challenge, cached.data);
          return;
        }
      }

      final results = await Future.wait([
        _supabase
            .getRealParticipantsCount(challengeId)
            .timeout(const Duration(seconds: 8), onTimeout: () => 0),
        _supabase
            .getUserChallengeProgressDetails(_currentUserId, challengeId)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => {'completedDays': 0, 'totalDays': 0},
            ),
      ]);

      final realParticipants = results[0];
      final progressData = results[1];

      final cacheData = {
        'participants': realParticipants,
        'progress': progressData,
      };

      _challengeDetailsCache[challengeId] = _CachedChallengeDetails(
        data: cacheData,
        timestamp: DateTime.now(),
      );

      if (_challengeDetailsCache.length > 20) {
        final keys = _challengeDetailsCache.keys.toList();
        _challengeDetailsCache.remove(keys.first);
      }

      _showChallengeDetailsDialogWithData(challenge, cacheData);
    } catch (e, stk) {
      Log.e('explore', 'Error showing challenge details: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ex.ch.detail_err', {'n': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
