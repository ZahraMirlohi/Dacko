// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): checkAndCompleteChallenge, _removeChallengeHabits, getUserActivePackages, updateUserStreak, _calculateStreak, recordDailyActivity…
part of '../supabase_service.dart';

extension SupabaseServiceUserUsername on SupabaseService {

  // ==================== Challenges ====================

// lib/services/supabase_service.dart

  Future<Map<String, dynamic>?> checkAndCompleteChallenge(
    String userId,
    String challengeId,
  ) async {
    if (!await isOnline()) return null;

    try {
      // دریافت همزمان اطلاعات
      final challenge = await getChallengeById(challengeId);
      if (challenge == null) return null;

      final userChallenge = await client
          .from('user_challenges')
          .select()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      if (userChallenge == null ||
          userChallenge['is_completed'] == true ||
          userChallenge['status'] == 'failed') {
        return null;
      }

      final completions = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      final completedDays = {
        for (final c in completions) (c['date'] as String).split('T').first
      }.length;
      final totalDays = challenge['challenge_duration'] as int? ?? 7;

      if (completedDays < totalDays) return null;

      // اتمیک: فقط یک درخواست موفق می‌شود؛ XP فقط برای همان یکی
      final updated = await client
          .from('user_challenges')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'progress': totalDays,
            'status': 'completed',
            'is_active': false,
          })
          .eq('id', userChallenge['id'])
          .eq('is_completed', false)
          .select('id');
      if (updated.isEmpty) return null;

      await addXP(userId, challenge['xp_reward'] as int? ?? 0);

      // حذف عادت‌های چالش (با ignore)
      unawaited(_removeChallengeHabits(userId, challengeId));

      return challenge;
    } catch (e, stk) {
      Log.e('supabase', 'Error checking challenge: $e', error: e, stack: stk);
      return null;
    }
  }

// متد کمکی برای حذف عادت‌ها در پس‌زمینه
  Future<void> _removeChallengeHabits(String userId, String challengeId) async {
    try {
      final habits = await client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (habits.isEmpty) return;

      final habitIds = habits.map((h) => h['id'] as String).toList();

      await Future.wait([
        client
            .from('habit_completions')
            .delete()
            .eq('user_id', userId)
            .inFilter('habit_id', habitIds),
        client
            .from('habits')
            .delete()
            .eq('user_id', userId)
            .inFilter('id', habitIds),
      ]);

      // حذف از LocalStorage
      final localStorage = LocalStorageService();
      final localHabits = localStorage.getHabits();
      final updatedHabits =
          localHabits.where((h) => h.challengeId != challengeId).toList();
      await localStorage.saveHabits(updatedHabits);

      print('Removed ${habitIds.length} challenge habits');
    } catch (e, stk) {
      Log.e('supabase', 'Error removing challenge habits: $e', error: e, stack: stk);
    }
  }

  Future<List<Package>> getUserActivePackages(String userId) async {
    try {
      final response = await client.from('user_packages').select('''
          package_id,
          packages (*)
        ''').eq('user_id', userId).eq('is_active', true);

      if (response.isEmpty) return [];

      return response.map((item) {
        final packageData = item['packages'] as Map<String, dynamic>;
        final packageId = packageData['id'] as String;
        return Package.fromMap(packageData, packageId);
      }).toList();
    } catch (e, stk) {
      Log.e('supabase', 'Error getting user active packages: $e', error: e, stack: stk);
      return [];
    }
  }

  // ==================== Streak ====================

  Future<void> updateUserStreak(String userId) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T').first;

      final todayActivity = await client
          .from('user_daily_activity')
          .select('is_active')
          .eq('user_id', userId)
          .eq('activity_date', todayStr)
          .maybeSingle();

      final bool isActiveToday =
          todayActivity != null && todayActivity['is_active'] == true;

      int currentStreak = 0;
      int bestStreak = 0;

      if (isActiveToday) {
        currentStreak = await _calculateStreak(userId, today);
        if (currentStreak == 0) {
          currentStreak = 1;
        }
      } else {
        final lastActivity = await client
            .from('user_daily_activity')
            .select('activity_date')
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('activity_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (lastActivity != null) {
          final lastDate = DateTime.parse(lastActivity['activity_date']);
          final daysDiff = DateTime(today.year, today.month, today.day)
              .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
              .inDays;
          if (daysDiff == 1) {
            // امروز هنوز وقت دارد؛ استریک تا دیروز نگه داشته می‌شود
            currentStreak = await _calculateStreak(userId, lastDate);
          } else {
            currentStreak = 0;
          }
        }
      }

      final profile = await client
          .from('profiles')
          .select('best_streak')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile != null) {
        bestStreak = profile['best_streak'] ?? 0;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      }

      final jalaliToday = Jalali.fromDateTime(today);
      final daysToSubtract = jalaliToday.weekDay - 1;
      final weekStart = today.subtract(Duration(days: daysToSubtract));

      int weeklyStreak = 0;
      List<bool> weekStatus = [];

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;
        final activity = await client
            .from('user_daily_activity')
            .select('is_active')
            .eq('user_id', userId)
            .eq('activity_date', dateStr)
            .maybeSingle();

        final isActive = activity != null && activity['is_active'] == true;
        weekStatus.add(isActive);

        if (isActive) {
          weeklyStreak++;
        }
      }

      await client.from('profiles').update({
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_streak_date': todayStr,
        'weekly_streak': weeklyStreak,
      }).eq('user_id', userId);
    } catch (e, stk) {
      Log.e('supabase', 'updateUserStreak failed', error: e, stack: stk);
      // ignore
    }
  }

  /// تعداد روزهای فعالِ پشت‌سرهم تا endDate؛ فقط یک درخواست (قبلاً یک درخواست برای هر روز)
  Future<int> _calculateStreak(String userId, DateTime endDate) async {
    final rows = await client
        .from('user_daily_activity')
        .select('activity_date')
        .eq('user_id', userId)
        .eq('is_active', true)
        .lte('activity_date', endDate.toIso8601String().split('T').first)
        .order('activity_date', ascending: false)
        .limit(800);

    final active = <String>{
      for (final r in rows) r['activity_date'].toString().split('T').first,
    };

    int streak = 0;
    var d = DateTime(endDate.year, endDate.month, endDate.day);
    while (active.contains(d.toIso8601String().split('T').first)) {
      streak++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return streak;
  }

  Future<void> recordDailyActivity({
    required String userId,
    required DateTime date,
    int habitsCompleted = 0,
    int tasksCompleted = 0,
    int xpEarned = 0,
    bool isActive = true,
  }) async {
    if (!await isOnline()) {
      return;
    }
    try {
      final dateStr = _getDateString(date);

      final existing = await client
          .from('user_daily_activity')
          .select()
          .eq('user_id', userId)
          .eq('activity_date', dateStr)
          .maybeSingle();

      if (existing != null) {
        await client.from('user_daily_activity').update({
          'habits_completed': habitsCompleted,
          'tasks_completed': tasksCompleted,
          'xp_earned': xpEarned,
          'is_active': isActive,
        }).eq('id', existing['id']);
      } else {
        await client.from('user_daily_activity').insert({
          'user_id': userId,
          'activity_date': dateStr,
          'habits_completed': habitsCompleted,
          'tasks_completed': tasksCompleted,
          'xp_earned': xpEarned,
          'is_active': isActive,
        });
      }

      await updateUserStreak(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasUserActivityToday(String userId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      final response = await client
          .from('user_daily_activity')
          .select('is_active')
          .eq('user_id', userId)
          .eq('activity_date', todayStr)
          .maybeSingle();

      return response != null && response['is_active'] == true;
    } catch (e, stk) {
      Log.e('supabase', 'hasUserActivityToday failed', error: e, stack: stk);
      return false;
    }
  }

  // ==================== Helper ====================

  Map<String, dynamic> _convertKeys(Map<String, dynamic> data) {
    return data.map((key, value) {
      String newKey = key;
      switch (key) {
        case 'user_id':
          newKey = 'userId';
          break;
        case 'total_xp':
          newKey = 'totalXP';
          break;
        case 'sub_habits':
          newKey = 'subHabits';
          break;
        case 'completed_sub_habits':
          newKey = 'completedSubHabits';
          break;
        case 'icon_name':
          newKey = 'iconName';
          break;
        case 'icon_color':
          newKey = 'iconColor';
          break;
        case 'background_color':
          newKey = 'backgroundColor';
          break;
        case 'frequency_type':
          newKey = 'frequencyType';
          break;
        case 'daily_interval_days':
          newKey = 'dailyIntervalDays';
          break;
        case 'weekly_days':
          newKey = 'weeklyDays';
          break;
        case 'weekly_interval_weeks':
          newKey = 'weeklyIntervalWeeks';
          break;
        case 'monthly_days':
          newKey = 'monthlyDays';
          break;
        case 'monthly_interval_months':
          newKey = 'monthlyIntervalMonths';
          break;
        case 'time_of_day':
          newKey = 'timeOfDay';
          break;
        case 'xp_reward':
          newKey = 'xpReward';
          break;
        case 'current_streak':
          newKey = 'currentStreak';
          break;
        case 'best_streak':
          newKey = 'bestStreak';
          break;
        case 'is_active':
          newKey = 'isActive';
          break;
        case 'group_id':
          newKey = 'groupId';
          break;
        case 'start_date':
          newKey = 'startDate';
          break;
        case 'end_date':
          newKey = 'endDate';
          break;
        case 'challenge_id':
          newKey = 'challengeId';
          break;
        case 'created_at':
          newKey = 'createdAt';
          break;
        case 'updated_at':
          newKey = 'updatedAt';
          break;
        case 'is_completed':
          newKey = 'isCompleted';
          break;
        case 'sub_tasks':
          newKey = 'subTasks';
          break;
        case 'completed_sub_tasks':
          newKey = 'completedSubTasks';
          break;
        case 'due_date':
          newKey = 'dueDate';
          break;
        case 'habit_id':
          newKey = 'habitId';
          break;
        case 'completed_at':
          newKey = 'completedAt';
          break;
        case 'community_xp':
          newKey = 'communityXP';
          break;
        case 'target_xp':
          newKey = 'targetXP';
          break;
        case 'text_color':
          newKey = 'textColor';
          break;
        case 'registration_end_date':
          newKey = 'registrationEndDate';
          break;
        case 'challenge_duration':
          newKey = 'challengeDuration';
          break;
        case 'purchased_at':
          newKey = 'purchasedAt';
          break;
        case 'joined_at':
          newKey = 'joinedAt';
          break;
        case 'xp_earned':
          newKey = 'xpEarned';
          break;
        case 'preview_image':
          newKey = 'previewImage';
          break;
        case 'quest_id':
          newKey = 'questId';
          break;
        default:
          newKey = key;
      }
      return MapEntry(newKey, value);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // متدهای Username
  // ═══════════════════════════════════════════════════════════

  /// بررسی در دسترس بودن username
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalized = username.toLowerCase().trim();

      // چک فرمت
      final regex = RegExp(r'^[a-z][a-z0-9_.]{2,29}$');
      if (!regex.hasMatch(normalized)) {
        print('Username format invalid: $normalized');
        return false;
      }

      // چک یکتا بودن با تابع دیتابیس
      final result = await _client.rpc(
        'is_username_available',
        params: {'p_username': normalized},
      );

      print('is_username_available($normalized) = $result');
      return result as bool;
    } catch (e, stk) {
      Log.e('supabase', 'Error checking username: $e', error: e, stack: stk);
      return false;
    }
  }

  /// ذخیره username برای کاربر
  Future<void> setUsername(String userId, String username) async {
    try {
      final normalized = username.toLowerCase().trim();

      await _client.from('profiles').update({
        'username': normalized,
        'username_updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      print('Username set: $normalized');
    } catch (e) {
      print('Error setting username: $e');
      rethrow;
    }
  }

  /// بررسی می‌کند آیا کاربر می‌تواند username را تغییر دهد (محدودیت ۱ دقیقه)
  Future<bool> canChangeUsername(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('username_updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return true;

      final updatedAtStr = response['username_updated_at'];
      if (updatedAtStr == null) return true;

      final updatedAt = DateTime.parse(updatedAtStr);
      final secondsSince = DateTime.now().difference(updatedAt).inSeconds;

      return secondsSince >= 60;
    } catch (e, stk) {
      Log.e('supabase', 'Error checking username change eligibility: $e', error: e, stack: stk);
      return false;
    }
  }

  /// ثانیه‌های باقی‌مانده تا تغییر بعدی username
  Future<int> secondsUntilUsernameChange(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('username_updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return 0;

      final updatedAtStr = response['username_updated_at'];
      if (updatedAtStr == null) return 0;

      final updatedAt = DateTime.parse(updatedAtStr);
      final secondsSince = DateTime.now().difference(updatedAt).inSeconds;

      if (secondsSince >= 60) return 0;
      return 60 - secondsSince;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting seconds until change: $e', error: e, stack: stk);
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // متدهای Avatar
  // ═══════════════════════════════════════════════════════════

  /// به‌روزرسانی avatar_url در profiles
  Future<void> updateAvatarUrl(String userId, String? avatarUrl) async {
    try {
      await _client.from('profiles').update({
        'avatar_url': avatarUrl,
      }).eq('user_id', userId);

      print('Avatar URL updated: $avatarUrl');
    } catch (e) {
      print('Error updating avatar: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // متدهای Gallery
  // ═══════════════════════════════════════════════════════════

  /// دریافت همه‌ی عکس‌های گالری یک کاربر
  Future<List<UserPhoto>> getUserPhotos(
    String userId, {
    bool visibleOnly = false,
  }) async {
    try {
      var query = _client.from('user_photos').select().eq('user_id', userId);

      if (visibleOnly) {
        query = query.eq('is_visible', true);
      }

      final response = await query.order('display_order', ascending: true);

      return (response as List)
          .map((map) => UserPhoto.fromMap(map, map['id']))
          .toList();
    } catch (e, stk) {
      Log.e('supabase', 'Error getting user photos: $e', error: e, stack: stk);
      return [];
    }
  }

  /// شمارش عکس‌های گالری کاربر
  Future<int> getUserPhotosCount(String userId) async {
    try {
      final response =
          await _client.from('user_photos').select('id').eq('user_id', userId);

      return (response as List).length;
    } catch (e, stk) {
      Log.e('supabase', 'Error counting photos: $e', error: e, stack: stk);
      return 0;
    }
  }
}
