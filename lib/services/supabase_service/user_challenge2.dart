// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): joinChallenge, _addChallengeBadge, _completeChallenge, leaveChallengeWithCleanup, _refreshUserChallenges, getPackages…
part of '../supabase_service.dart';

extension SupabaseServiceUserChallenge2 on SupabaseService {

// lib/services/supabase_service.dart

  Future<void> joinChallenge(String userId, String challengeId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1. ابتدا همه رکوردهای قبلی را پاک کن (برای شروع تمیز)
      try {
        // حذف از user_challenges
        await client
            .from('user_challenges')
            .delete()
            .eq('user_id', userId)
            .eq('challenge_id', challengeId);

        // حذف از challenge_completions
        await client
            .from('challenge_completions')
            .delete()
            .eq('user_id', userId)
            .eq('challenge_id', challengeId);

        print('Cleaned up previous records for challenge: $challengeId');
      } catch (e, stk) {
        Log.e('supabase', 'Cleanup error (may not have existing records): $e', error: e, stack: stk);
      }

      // دریافت اطلاعات چالش
      final challengeResponse = await client
          .from('challenges')
          .select()
          .eq('id', challengeId)
          .maybeSingle();

      if (challengeResponse == null) {
        throw Exception('چالش یافت نشد');
      }

      final duration = challengeResponse['challenge_duration'] as int? ?? 7;
      final endDate = today.add(Duration(days: duration - 1));

      // ثبت‌نام جدید در user_challenges
      await client.from('user_challenges').insert({
        'user_id': userId,
        'challenge_id': challengeId,
        'joined_at': now.toIso8601String(),
        'challenge_start_date': today.toIso8601String(),
        'challenge_end_date': endDate.toIso8601String(),
        'progress': 0,
        'is_completed': false,
        'is_active': true,
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // حذف عادت‌های قبلی چالش (اگر وجود داشته باشند)
      try {
        final existingHabits = await client
            .from('habits')
            .select('id')
            .eq('user_id', userId)
            .eq('challenge_id', challengeId);

        if (existingHabits.isNotEmpty) {
          final habitIds =
              existingHabits.map((h) => h['id'] as String).toList();
          await client
              .from('habits')
              .delete()
              .eq('user_id', userId)
              .inFilter('id', habitIds);
          print('Removed ${habitIds.length} existing challenge habits');
        }
      } catch (e, stk) {
        Log.e('supabase', 'Error removing existing habits: $e', error: e, stack: stk);
      }

      // اضافه کردن عادت‌های چالش به کاربر
      await addChallengeHabitToUser(
        userId,
        challengeResponse,
        today,
        endDate,
      );

      print('User joined challenge: $challengeId');
      print('Start date: $today');
      print('End date: $endDate');
      print('Duration: $duration days');
    } catch (e) {
      print('Error joining challenge: $e');
      rethrow;
    }
  }

// متد جدید برای ثبت مدال چالش
  Future<void> _addChallengeBadge(
      String userId, Map<String, dynamic> challenge) async {
    try {
      final badgeName = '🏆 ${challenge['title']}';
      final badgeIcon = '🏆';

      // بررسی وجود مدال تکراری
      final existing = await client
          .from('user_badges')
          .select()
          .eq('user_id', userId)
          .eq('badge_name', badgeName)
          .maybeSingle();

      if (existing != null) {
        print('Badge already exists: $badgeName');
        return;
      }

      // ثبت مدال جدید
      await client.from('user_badges').insert({
        'user_id': userId,
        'badge_name': badgeName,
        'badge_icon': badgeIcon,
        'badge_type': 'challenge',
        'challenge_id': challenge['id'],
        'earned_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      print('Challenge badge earned: $badgeName');
    } catch (e, stk) {
      Log.e('supabase', 'Error adding challenge badge: $e', error: e, stack: stk);
    }
  }

// lib/services/supabase_service.dart

  Future<void> _completeChallenge(
    String userId,
    String userChallengeId,
    Map<String, dynamic> challenge,
  ) async {
    try {
      final now = DateTime.now();
      final challengeId = challenge['id'];
      final xpReward = challenge['xp_reward'] as int? ?? 50;
      final challengeDuration = challenge['challenge_duration'] as int? ?? 7;

      // 1. به‌روزرسانی وضعیت چالش (فقط اگر هنوز کامل نشده؛ مانع XP دوباره)
      final updated = await client
          .from('user_challenges')
          .update({
            'is_completed': true,
            'is_active': false,
            'status': 'completed',
            'progress': challengeDuration,
            'completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', userChallengeId)
          .eq('is_completed', false)
          .select('id');
      if (updated.isEmpty) return; // قبلاً کامل شده؛ XP دوباره داده نمی‌شود

      // 2. افزودن مدال چالش
      await _addChallengeBadge(userId, challenge);

      // 3. افزودن XP پاداش
      await addXP(userId, xpReward);

      // 4. حذف عادت‌های چالش
      final habits = await client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (habits.isNotEmpty) {
        final habitIds = habits.map((h) => h['id'] as String).toList();

        await client
            .from('habit_completions')
            .delete()
            .eq('user_id', userId)
            .inFilter('habit_id', habitIds);

        await client
            .from('habits')
            .delete()
            .eq('user_id', userId)
            .inFilter('id', habitIds);
      }

      // 5. حذف رکوردهای challenge_completions بعد از تکمیل
      await client
          .from('challenge_completions')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print('Challenge completions cleared after completion');

      // 6. حذف از LocalStorage
      try {
        final localStorage = LocalStorageService();
        final localHabits = localStorage.getHabits();
        final updatedHabits =
            localHabits.where((h) => h.challengeId != challengeId).toList();
        await localStorage.saveHabits(updatedHabits);

        final userChallenges = localStorage.getUserChallenges();
        final updatedUserChallenges =
            userChallenges.where((c) => c['id'] != challengeId).toList();
        await localStorage.saveUserChallenges(updatedUserChallenges);
      } catch (e, stk) {
        Log.e('supabase', 'Error removing from local storage: $e', error: e, stack: stk);
      }

      print('Challenge completed successfully: ${challenge['title']}');
    } catch (e) {
      print('Error completing challenge: $e');
      rethrow;
    }
  }

  // انصراف کاربر از چالش
  Future<void> leaveChallengeWithCleanup(
    String userId,
    String challengeId,
  ) async {
    try {
      // 1. حذف از user_challenges
      await client
          .from('user_challenges')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      // 2. حذف تمام رکوردهای تکمیل برای این چالش
      await client
          .from('challenge_completions')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print('User left challenge: $challengeId');
    } catch (e, stk) {
      Log.e('supabase', 'Error leaving challenge: $e', error: e, stack: stk);
    }
  }

  // ریفرش داده‌های چالش‌های کاربر
  Future<void> _refreshUserChallenges(String userId) async {
    try {
      final userChallenges = await client
          .from('user_challenges')
          .select('*')
          .eq('user_id', userId);

      print('User challenges refreshed: ${userChallenges.length}');
    } catch (e, stk) {
      Log.e('supabase', 'Error refreshing user challenges: $e', error: e, stack: stk);
    }
  }

  // ==================== Packages ====================

  Future<List<Package>> getPackages() async {
    if (!await isOnline()) {
      return [];
    }

    try {
      final response = await client
          .from('packages')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) {
        return Package.fromMap(data, data['id']);
      }).toList();
    } catch (e, stk) {
      Log.e('supabase', 'getPackages failed', error: e, stack: stk);
      return [];
    }
  }

  Future<List<UserPackage>> getUserPackages(String userId) async {
    try {
      final response = await client
          .from('user_packages')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      return response
          .map((data) => UserPackage.fromMap(data, data['id']))
          .toList();
    } catch (e, stk) {
      Log.e('supabase', 'getUserPackages failed', error: e, stack: stk);
      return [];
    }
  }

  Future<void> activatePackage(String userId, String packageId) async {
    try {
      // 1. دریافت اطلاعات بسته
      final packageResponse =
          await client.from('packages').select().eq('id', packageId).single();

      final package = Package.fromMap(packageResponse, packageId);

      // 2. ثبت در user_packages
      final existing = await client
          .from('user_packages')
          .select()
          .eq('user_id', userId)
          .eq('package_id', packageId);

      if (existing.isNotEmpty && existing[0]['is_active'] == true) {
        return; // قبلاً فعال است؛ عادت تکراری ساخته نشود
      }

      if (existing.isNotEmpty) {
        await client.from('user_packages').update({
          'is_active': true,
          'removed_at': null,
          'added_at': DateTime.now().toIso8601String(),
        }).eq('id', existing[0]['id']);
      } else {
        await client.from('user_packages').insert({
          'user_id': userId,
          'package_id': packageId,
          'is_active': true,
          'added_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. ایجاد عادت‌های بسته برای کاربر
      for (var packageHabit in package.habits) {
        final habit = packageHabit.toHabit(userId, packageId);
        await createHabit(habit);
      }

      // 4. XP پاداش فقط در اولین فعال‌سازی
      if (existing.isEmpty) {
        await addXP(userId, package.xpReward);
      }

      // 5. ذخیره در LocalStorage
      try {
        final localStorage = LocalStorageService();
        final habits = await getHabits(userId);
        await localStorage.saveHabits(habits);
      } catch (e, stk) {
        Log.e('supabase', 'Error saving to local storage: $e', error: e, stack: stk);
      }

      print('Package activated: $packageId');
      print('${package.habits.length} habits created');
    } catch (e) {
      print('Error activating package: $e');
      rethrow;
    }
  }

  /// عادتِ این بسته؟ اول با package_id؛ برای عادت‌های قدیمی (بدون package_id) با عنوان.
  bool _isHabitOfPackage(Habit habit, String packageId, Package package) {
    if (habit.packageId != null) return habit.packageId == packageId;
    return habit.title.startsWith('📦') &&
        package.habits.any((ph) => habit.title.contains(ph.title));
  }

  Future<void> deactivatePackage(String userId, String packageId) async {
    try {
      // 1. غیرفعال کردن در user_packages
      await client
          .from('user_packages')
          .update({
            'is_active': false,
            'removed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('package_id', packageId);

      // 2. دریافت اطلاعات بسته
      final packageResponse =
          await client.from('packages').select().eq('id', packageId).single();

      final package = Package.fromMap(packageResponse, packageId);

      // 3. حذف عادت‌های بسته از دیتابیس
      final habits = await getHabits(userId);
      for (var habit in habits) {
        if (_isHabitOfPackage(habit, packageId, package)) {
          await deleteHabit(habit.id);
        }
      }

      // 4. حذف از LocalStorage
      try {
        final localStorage = LocalStorageService();
        final localHabits = localStorage.getHabits();
        final updatedHabits = localHabits
            .where((h) => !_isHabitOfPackage(h, packageId, package))
            .toList();
        await localStorage.saveHabits(updatedHabits);
      } catch (e, stk) {
        Log.e('supabase', 'Error removing from local storage: $e', error: e, stack: stk);
      }

      print('Package deactivated: $packageId');
    } catch (e) {
      print('Error deactivating package: $e');
      rethrow;
    }
  }

  Future<bool> isPackageActiveForUser(String userId, String packageId) async {
    try {
      final response = await client
          .from('user_packages')
          .select()
          .eq('user_id', userId)
          .eq('package_id', packageId)
          .eq('is_active', true);

      return response.isNotEmpty;
    } catch (e, stk) {
      Log.e('supabase', 'isPackageActiveForUser failed', error: e, stack: stk);
      return false;
    }
  }

  Future<List<Package>> getActivePackagesForUser(String userId) async {
    try {
      final userPackagesResponse = await client
          .from('user_packages')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      if (userPackagesResponse.isEmpty) return [];

      List<Package> packages = [];
      for (var up in userPackagesResponse) {
        final packageId = up['package_id'];
        final packageResponse =
            await client.from('packages').select().eq('id', packageId).single();

        packages.add(Package.fromMap(packageResponse, packageId));
      }

      return packages;
    } catch (e, stk) {
      Log.e('supabase', 'getActivePackagesForUser failed', error: e, stack: stk);
      return [];
    }
  }

  // ==================== User Progress ====================

  Future<void> createUserProgress(String userId) async {
    try {
      final existing =
          await client.from('user_progress').select('id').eq('user_id', userId);

      if (existing.isEmpty) {
        await client.from('user_progress').insert({
          'user_id': userId,
          'total_xp': 0,
          'weekly_xp': 0,
          'monthly_xp': 0,
        });
      }
    } catch (e) {
      try {
        final profileExists = await client
            .from('profiles')
            .select('user_id')
            .eq('user_id', userId);

        if (profileExists.isEmpty) {
          await client.from('profiles').insert({
            'user_id': userId,
            'total_xp': 0,
          });
        }
      } catch (e2, stk) {
        Log.e('supabase', 'createUserProgress failed', error: e2, stack: stk);
        // ignore
      }
    }
  }

  // ==================== Quests ====================

  Future<List<Quest>> getQuests() async {
    if (!await isOnline()) {
      return [];
    }

    try {
      final response = await client
          .from('quests')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((data) => Quest.fromMap(data, data['id'])).toList();
    } catch (e, stk) {
      Log.e('supabase', 'getQuests failed', error: e, stack: stk);
      return [];
    }
  }

// lib/services/supabase_service.dart

  Future<List<UserQuest>> getUserQuests(String userId) async {
    try {
      print('getUserQuests called for userId: $userId');

      final response =
          await client.from('user_quests').select().eq('user_id', userId);

      print('getUserQuests response count: ${response.length}');

      final result =
          response.map((data) => UserQuest.fromMap(data, data['id'])).toList();

      for (var uq in result) {
        print(
            '   - Quest ID: ${uq.questId}, isActive: ${uq.isActive}, isCompleted: ${uq.isCompleted}, progress: ${uq.progress}');
      }

      return result;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting user quests: $e', error: e, stack: stk);
      return [];
    }
  }
}
