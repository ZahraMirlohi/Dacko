// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از profile_screen.dart (بدون تغییر رفتار): _onRefreshTriggered, _loadProfile, _recalculateWeeklyStreak, _loadFromLocal, _loadFromSupabase, _calculateWeekDaysFromDatabase…
part of '../profile_screen.dart';

extension _ProfileScreenStateProfileWeekly on _ProfileScreenState {

  void _onRefreshTriggered() {
    print(
      'Profile refresh triggered from notifier: ${widget.refreshNotifier?.value}',
    );

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _ProfileScreenState._minRefreshInterval) {
      print('Skip refresh: too soon');
      return;
    }
    _lastRefreshTime = now;

    if (_isRefreshing) {
      print('Skip refresh: already refreshing');
      return;
    }

    _isRefreshing = true;
    print('Refreshing profile...');

    // فقط کش weekDays را پاک کن (چون _cachedHabits و _cachedTasks وجود ندارند)
    _cachedWeekDays = null;

    // اجباری کردن بارگذاری از دیتابیس
    _isLoadingInProgress = false;

    _loadProfile().then((_) {
      _analyticsKey.currentState?.refreshData();
      _isRefreshing = false;
      debugPrint('Profile refresh completed');
    }).catchError((e) {
      debugPrint('Profile refresh error: $e');
      _isRefreshing = false;
    });
  }
  // ==================== متد اصلی بارگذاری پروفایل ====================

  Future<void> _loadProfile() async {
    // چک کن SyncProvider پاک شده
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    if (syncProvider.isCleared) {
      print('Skip _loadProfile: SyncProvider is cleared');
      return;
    }

    if (!mounted) return;

    _isLoadingInProgress = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // همیشه از دیتابیس بخوان
      if (syncProvider.isOnline) {
        print('Online - loading from Supabase...');
        final success = await _loadFromSupabase(syncProvider);
        if (success) {
          _isLoadingInProgress = false;
          final calendar =
              Provider.of<CalendarProvider>(context, listen: false);
          await _recalculateWeeklyStreak(calendar); // با calendar
          if (mounted) {
            setState(() {});
          }
          return;
        }
      }

      // اگر آنلاین نبود، از localStorage بخوان
      print('Loading from LocalStorage...');
      final localSuccess = await _loadFromLocal(syncProvider);

      if (!localSuccess && mounted) {
        setState(() {
          _errorMessage = context.tr('pf.k001');
          _isLoading = false;
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stk) {
      Log.e('profile', 'Error loading profile: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _errorMessage = context.tr('pf.k002', {'p0': '${e.toString()}'});
          _isLoading = false;
        });
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }
  // ==================== به‌روزرسانی استریک هفتگی ====================

  Future<void> _recalculateWeeklyStreak(CalendarProvider calendar) async {
    try {
      if (_profile == null) return;

      final now = DateTime.now();

      // محاسبه شروع هفته بر اساس تقویم انتخابی
      int daysToSubtract;
      if (calendar.isJalali) {
        final jalaliToday = Jalali.fromDateTime(now);
        daysToSubtract = jalaliToday.weekDay - 1;
      } else {
        daysToSubtract = now.weekday % 7;
      }
      final weekStart = now.subtract(Duration(days: daysToSubtract));

      int newWeeklyStreak = 0;
      List<bool> weekStatus = [];

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;

        final activity = await _supabase.client
            .from('user_daily_activity')
            .select('is_active')
            .eq('user_id', _profile!.userId)
            .eq('activity_date', dateStr)
            .maybeSingle();

        final isActive = activity != null && activity['is_active'] == true;
        weekStatus.add(isActive);

        if (isActive) {
          newWeeklyStreak++;
        }
      }

      _cachedWeekDays = weekStatus;

      if (_profile!.weeklyStreak != newWeeklyStreak) {
        await _supabase.client.from('profiles').update(
            {'weekly_streak': newWeeklyStreak}).eq('user_id', _profile!.userId);

        setState(() {
          _weeklyStreak = newWeeklyStreak;
          _profile = _profile!.copyWith(
            weeklyStreak: newWeeklyStreak,
            lastStreakUpdate: DateTime.now(),
          );
        });
      }
    } catch (e, stk) {
      Log.e('profile', 'Error recalculating weekly streak: $e', error: e, stack: stk);
    }
  }
  // ==================== بارگذاری از LocalStorage ====================

  // lib/features/profile/screens/profile_screen.dart

  Future<bool> _loadFromLocal(SyncProvider syncProvider) async {
    try {
      final localProfile = syncProvider.profile;

      if (localProfile != null) {
        _profile = UserProfile.fromMap(
          localProfile,
          localProfile['user_id'] ?? '',
        );
        _currentStreak = localProfile['current_streak'] ?? 0;
        _bestStreak = localProfile['best_streak'] ?? 0;
        _weeklyStreak = localProfile['weekly_streak'] ?? 0;

        // اطمینان از اینکه total_xp از localStorage صحیح است
        _profile!.totalXp = localProfile['total_xp'] ?? 0;
        print(
          'Profile loaded from LOCAL storage with XP: ${_profile!.totalXp}',
        );

        print('Profile loaded from LOCAL storage');
        print('   - Name: ${_profile?.name}');
        print('   - XP: ${_profile?.totalXp}');
        print('   - Streak: $_currentStreak');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return true;
      }

      print('No profile found in LOCAL storage');
      return false;
    } catch (e, stk) {
      Log.e('profile', 'Error loading from local: $e', error: e, stack: stk);
      return false;
    }
  }

  // ==================== بارگذاری از Supabase ====================

  // lib/features/profile/screens/profile_screen.dart

  Future<bool> _loadFromSupabase(SyncProvider syncProvider) async {
    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser == null) {
        print('No user logged in');
        if (mounted) {
          setState(() {
            _errorMessage = context.tr('pf.k003');
            _isLoading = false;
          });
        }
        return false;
      }

      print('Loading profile for user: ${currentUser.id}');

      // دریافت پروفایل با XP از دیتابیس
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        // اطمینان از وجود unique_id
        if (response['unique_id'] == null || response['unique_id'].isEmpty) {
          final newUniqueId = UniqueIdGenerator.generateSecure();
          await _supabase.client
              .from('profiles')
              .update({'unique_id': newUniqueId}).eq('user_id', currentUser.id);
          response['unique_id'] = newUniqueId;
          print('Unique ID generated for user: $newUniqueId');
        }

        // دریافت XP از user_progress (منبع اصلی)
        int totalXP = response['total_xp'] ?? 0;
        try {
          final progressResponse = await _supabase.client
              .from('user_progress')
              .select('total_xp')
              .eq('user_id', currentUser.id)
              .maybeSingle();

          if (progressResponse != null) {
            final progressXP = progressResponse['total_xp'] as int? ?? 0;
            // از user_progress استفاده کن چون منبع اصلی است
            totalXP = progressXP;
            print('XP from user_progress: $totalXP');

            // اگر profiles با user_progress هماهنگ نیست، آن را به‌روزرسانی کن
            if (response['total_xp'] != totalXP) {
              await _supabase.client
                  .from('profiles')
                  .update({'total_xp': totalXP}).eq('user_id', currentUser.id);
              print('Profile XP updated to match user_progress: $totalXP');
            }
          }
        } catch (e, stk) {
          Log.e('profile', 'Error getting user_progress: $e', error: e, stack: stk);
        }

        // ساخت پروفایل با XP صحیح
        _profile = UserProfile.fromMap(response, currentUser.id);
        _currentStreak = response['current_streak'] ?? 0;
        _bestStreak = response['best_streak'] ?? 0;
        _weeklyStreak = response['weekly_streak'] ?? 0;

        // تنظیم total_xp با مقدار صحیح
        _profile!.totalXp = totalXP;
        print('Profile XP set to: ${_profile!.totalXp}');

        final calendar = Provider.of<CalendarProvider>(context, listen: false);
        _cachedWeekDays = await _calculateWeekDaysFromDatabase(
          currentUser.id,
          calendar,
        );
        // ذخیره در LocalStorage با مقدار صحیح
        final profileMap = _profile!.toMap();
        profileMap['user_id'] = currentUser.id;
        profileMap['current_streak'] = _currentStreak;
        profileMap['best_streak'] = _bestStreak;
        profileMap['weekly_streak'] = _weeklyStreak;
        profileMap['total_xp'] = totalXP;
        await syncProvider.saveProfileToLocal(profileMap);

        print('Profile loaded from SUPABASE');
        print('   - Name: ${_profile?.name}');
        print('   - XP: ${_profile?.totalXp}');
        print('   - Streak: $_currentStreak');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return true;
      }

      print('No profile found, creating new...');
      await _createNewProfile();
      return true;
    } catch (e, stk) {
      Log.e('profile', 'Error loading from Supabase: $e', error: e, stack: stk);
      return false;
    }
  }

  // متد محاسبه weekDays از دیتابیس (با await)
  Future<List<bool>> _calculateWeekDaysFromDatabase(
    String userId,
    CalendarProvider calendar,
  ) async {
    List<bool> weekDays = List.filled(7, false);

    try {
      final now = DateTime.now();

      // محاسبه شروع هفته بر اساس تقویم
      int daysToSubtract;
      if (calendar.isJalali) {
        final jalaliNow = Jalali.fromDateTime(now);
        daysToSubtract = jalaliNow.weekDay - 1;
      } else {
        daysToSubtract = now.weekday % 7;
      }
      final weekStart = now.subtract(Duration(days: daysToSubtract));

      // دریافت فعالیت‌های هفته
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;

        final activity = await _supabase.client
            .from('user_daily_activity')
            .select('is_active')
            .eq('user_id', userId)
            .eq('activity_date', dateStr)
            .maybeSingle();

        weekDays[i] = activity != null && activity['is_active'] == true;
      }

      return weekDays;
    } catch (e, stk) {
      Log.e('profile', 'Error calculating weekDays: $e', error: e, stack: stk);
      return weekDays;
    }
  }

  // ==================== ساخت پروفایل جدید ====================

  // lib/features/profile/screens/profile_screen.dart

  Future<void> _createNewProfile() async {
    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = context.tr('pf.k003');
            _isLoading = false;
          });
        }
        return;
      }

      // تولید ID یکتا
      final uniqueId = UniqueIdGenerator.generateSecure();

      final newProfile = UserProfile(
        userId: currentUser.id,
        name: currentUser.email?.split('@').first.isNotEmpty == true
            ? currentUser.email!.split('@').first
            : context.tr('pf.k004'),
        uniqueId: uniqueId, // اضافه کردن uniqueId
        email: currentUser.email,
        registeredAt: DateTime.now(),
        totalXp: 0,
      );

      // ذخیره در Supabase با unique_id
      await _supabase.client.from('profiles').insert({
        'user_id': currentUser.id,
        'name': newProfile.name,
        'email': newProfile.email,
        'unique_id': uniqueId, // ذخیره unique_id
        'total_xp': 0,
        'current_streak': 0,
        'best_streak': 0,
        'weekly_streak': 0,
      });

      // ایجاد user_progress
      await _supabase.createUserProgress(currentUser.id);

      // تنظیم پروفایل محلی
      _profile = newProfile;
      _currentStreak = 0;
      _bestStreak = 0;
      _weeklyStreak = 0;

      // ذخیره در LocalStorage
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      final profileMap = newProfile.toMap();
      profileMap['user_id'] = currentUser.id;
      profileMap['current_streak'] = 0;
      profileMap['best_streak'] = 0;
      profileMap['weekly_streak'] = 0;
      await syncProvider.saveProfileToLocal(profileMap);

      print('New profile created with Unique ID: $uniqueId');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stk) {
      Log.e('profile', 'Error creating profile: $e', error: e, stack: stk);
      await _createFallbackProfile();
    }
  }
  // ==================== پروفایل پیش‌فرض (Fallback) ====================

  Future<void> _createFallbackProfile() async {
    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser != null && _profile == null) {
        _profile = UserProfile(
          userId: currentUser.id,
          name: currentUser.email?.split('@').first ?? context.tr('pf.k004'),
          email: currentUser.email,
          registeredAt: DateTime.now(),
          totalXp: 0,
        );
        _currentStreak = 0;
        _bestStreak = 0;
        _weeklyStreak = 0;

        // ذخیره در LocalStorage
        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        final profileMap = _profile!.toMap();
        profileMap['user_id'] = _profile!.userId;
        profileMap['current_streak'] = 0;
        profileMap['best_streak'] = 0;
        profileMap['weekly_streak'] = 0;
        await syncProvider.saveProfileToLocal(profileMap);

        print('Fallback profile created');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e, stk) {
      Log.e('profile', 'Error creating fallback profile: $e', error: e, stack: stk);
    }
  }

  // ==================== ذخیره پروفایل ====================

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    try {
      final data = _profile!.toMap();
      data.remove('registered_at');

      await _supabase.client
          .from('profiles')
          .update(data)
          .eq('user_id', _profile!.userId);

      // ذخیره در LocalStorage
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      final profileMap = _profile!.toMap();
      profileMap['user_id'] = _profile!.userId;
      profileMap['current_streak'] = _currentStreak;
      profileMap['best_streak'] = _bestStreak;
      profileMap['weekly_streak'] = _weeklyStreak;
      await syncProvider.saveProfileToLocal(profileMap);

      print('Profile saved to Supabase and LocalStorage');
    } catch (e, stk) {
      Log.e('profile', 'Error saving profile: $e', error: e, stack: stk);
    }
  }

  // ==================== محاسبه استریک هفتگی ====================

  Future<void> _calculateWeeklyStreak() async {
    if (_profile == null) return;

    try {
      final now = DateTime.now();
      final todayGregorian = now;
      final weekdayGregorian = now.weekday;

      int daysToSubtract;
      if (weekdayGregorian == 1) {
        daysToSubtract = 2;
      } else {
        daysToSubtract = weekdayGregorian - 1;
      }

      final weekStart = todayGregorian.subtract(Duration(days: daysToSubtract));

      int streak = 0;
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;

        try {
          final activity = await _supabase.client
              .from('user_daily_activity')
              .select('is_active')
              .eq('user_id', _profile!.userId)
              .eq('activity_date', dateStr)
              .maybeSingle();

          final bool isActive =
              activity != null && activity['is_active'] == true;

          if (isActive) {
            streak++;
          }
        } catch (e, stk) {
          Log.e('profile', '_calculateWeeklyStreak failed', error: e, stack: stk);
          // اگر جدول وجود نداشت، از داده‌های موجود استفاده کن
          break;
        }
      }

      if (_profile!.weeklyStreak != streak) {
        _profile = _profile!.copyWith(
          weeklyStreak: streak,
          lastStreakUpdate: DateTime.now(),
        );
        await _saveProfile();

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e, stk) {
      Log.e('profile', 'Error calculating weekly streak: $e', error: e, stack: stk);
    }
  }

  // ==================== حالت خطا ====================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: _theme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('pf.k006')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== حالت خالی ====================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Dk.l(Colors.grey.shade300)),
          const SizedBox(height: 16),
          Text(context.tr('pf.k007')),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('pf.k008')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
