// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): updateChallengeProgress, _updateChallengeProgressForHabit, _adjustXpRpc, addXP, getUserXP, removeXP…
part of '../supabase_service.dart';

extension SupabaseServiceChallengeHabit on SupabaseService {

  // lib/services/supabase_service.dart

  Future<void> updateChallengeProgress(
    String userId,
    String challengeId,
  ) async {
    if (!await isOnline()) {
      print('Offline, skipping challenge progress update');
      return;
    }

    try {
      print('Updating challenge progress for: $challengeId');

      // 1. دریافت تعداد روزهای تکمیل شده
      final completions = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print('Completions count: ${completions.length}');

      // 2. دریافت اطلاعات چالش
      final challenge = await client
          .from('challenges')
          .select('challenge_duration')
          .eq('id', challengeId)
          .maybeSingle();

      final completedDays = completions.length;
      final totalDays = challenge?['challenge_duration'] as int? ?? 7;

      print('Completed: $completedDays / $totalDays');

      // 3. به‌روزرسانی
      await client
          .from('user_challenges')
          .update({
            'progress': completedDays > totalDays ? totalDays : completedDays,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print('Challenge progress updated: $completedDays / $totalDays');
    } catch (e, stk) {
      Log.e('supabase', 'Error updating challenge progress: $e', error: e, stack: stk);
    }
  }

  Future<void> _updateChallengeProgressForHabit(
    String userId,
    String habitId,
  ) async {
    try {
      if (!await isOnline()) {
        return;
      }

      final habit = await client
          .from('habits')
          .select('challenge_id')
          .eq('id', habitId)
          .eq('user_id', userId)
          .maybeSingle();

      if (habit == null) {
        return;
      }

      final challengeId = habit['challenge_id'];
      if (challengeId == null) {
        return;
      }

      await updateChallengeProgress(userId, challengeId);
    } catch (e, stk) {
      Log.e('supabase', '_updateChallengeProgressForHabit failed', error: e, stack: stk);
      // ignore
    }
  }

  // ==================== XP Management ====================

  /// تغییر اتمیک XP با تابع سرور `adjust_xp` (فایل sql/03). اگر هنوز ساخته نشده باشد
  /// false برمی‌گرداند و روش قدیمی اجرا می‌شود.
  Future<bool> _adjustXpRpc(String userId, int delta) async {
    try {
      await client.rpc('adjust_xp', params: {'p_user_id': userId, 'p_delta': delta});
      return true;
    } catch (err, stk) {
      Log.w('supabase', '_adjustXpRpc ignored error', error: err, stack: stk);
      return false;
    }
  }

  Future<void> addXP(String userId, int amount) async {
    if (await _adjustXpRpc(userId, amount)) return;
    try {
      final response = await client
          .from('user_progress')
          .select('total_xp')
          .eq('user_id', userId);

      if (response.isNotEmpty) {
        final currentXP = response[0]['total_xp'] ?? 0;
        final newXP = currentXP + amount;
        await client
            .from('user_progress')
            .update({'total_xp': newXP}).eq('user_id', userId);
      } else {
        await client.from('user_progress').insert({
          'user_id': userId,
          'total_xp': amount,
        });
      }

      try {
        final profileResponse = await client
            .from('profiles')
            .select('total_xp')
            .eq('user_id', userId);

        if (profileResponse.isNotEmpty) {
          final currentXP = profileResponse[0]['total_xp'] ?? 0;
          await client
              .from('profiles')
              .update({'total_xp': currentXP + amount}).eq('user_id', userId);
        } else {
          await client.from('profiles').insert({
            'user_id': userId,
            'total_xp': amount,
          });
        }
      } catch (e, stk) {
        Log.e('supabase', 'addXP failed', error: e, stack: stk);
        // ignore
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUserXP(String userId) async {
    try {
      final response = await client
          .from('user_progress')
          .select('total_xp')
          .eq('user_id', userId);

      if (response.isNotEmpty) {
        return response[0]['total_xp'] ?? 0;
      }

      final profileResponse = await client
          .from('profiles')
          .select('total_xp')
          .eq('user_id', userId);

      if (profileResponse.isNotEmpty) {
        return profileResponse[0]['total_xp'] ?? 0;
      }

      return 0;
    } catch (e, stk) {
      Log.e('supabase', 'getUserXP failed', error: e, stack: stk);
      return 0;
    }
  }

  // lib/services/supabase_service.dart

  Future<void> removeXP(String userId, int amount) async {
    if (await _adjustXpRpc(userId, -amount)) return;
    try {
      print('Removing $amount XP from user: $userId');

      // 1. به‌روزرسانی در user_progress
      final response = await client
          .from('user_progress')
          .select('id, total_xp')
          .eq('user_id', userId);

      if (response.isNotEmpty) {
        final currentXP = response[0]['total_xp'] ?? 0;
        final newXP = (currentXP - amount).clamp(0, double.infinity).toInt();

        print('Current XP: $currentXP, New XP: $newXP');

        await client
            .from('user_progress')
            .update({'total_xp': newXP}).eq('id', response[0]['id']);
      } else {
        await client.from('user_progress').insert({
          'user_id': userId,
          'total_xp': 0,
        });
      }

      // 2. به‌روزرسانی در profiles
      try {
        final profileResponse = await client
            .from('profiles')
            .select('total_xp')
            .eq('user_id', userId);

        if (profileResponse.isNotEmpty) {
          final currentXP = profileResponse[0]['total_xp'] ?? 0;
          final newXP = (currentXP - amount).clamp(0, double.infinity).toInt();

          print('Profile XP: $currentXP -> $newXP');

          await client
              .from('profiles')
              .update({'total_xp': newXP}).eq('user_id', userId);
        }
      } catch (e, stk) {
        Log.e('supabase', 'Error updating profile XP: $e', error: e, stack: stk);
      }

      print('XP removed successfully');
    } catch (e) {
      print('Error removing XP: $e');
      rethrow;
    }
  }

  // ==================== Challenges ====================

// اصلاح متد getChallenges - حذف فیلتر تاریخ
  Future<List<Map<String, dynamic>>> getChallenges() async {
    if (!await isOnline()) {
      return [];
    }

    try {
      // حذف شرط تاریخ - فقط چالش‌های فعال را بگیر
      final response = await client
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response;
    } catch (e, stk) {
      Log.e('supabase', 'getChallenges failed', error: e, stack: stk);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpiredChallenges() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await client
          .from('challenges')
          .select()
          .eq('is_active', true)
          .lt('registration_end_date', now)
          .order('created_at', ascending: false);

      return response;
    } catch (e, stk) {
      Log.e('supabase', 'getExpiredChallenges failed', error: e, stack: stk);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChallengeById(String challengeId) async {
    try {
      final response = await client
          .from('challenges')
          .select()
          .eq('id', challengeId)
          .single();

      return response;
    } catch (e, stk) {
      Log.e('supabase', 'getChallengeById failed', error: e, stack: stk);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChallengeHabits(
    String challengeId,
  ) async {
    try {
      final response = await client
          .from('challenge_habits')
          .select()
          .eq('challenge_id', challengeId);

      return response;
    } catch (e, stk) {
      Log.e('supabase', 'getChallengeHabits failed', error: e, stack: stk);
      return [];
    }
  }

// lib/services/supabase_service.dart

  Future<void> addChallengeHabitToUser(
    String userId,
    Map<String, dynamic> challenge,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final duration = challenge['challenge_duration'] as int;
      final xpPerDay = (challenge['xp_reward'] as int) ~/ duration;
      final challengeId = challenge['id'];

      // دریافت عادت‌های چالش
      final challengeHabits = await getChallengeHabits(challengeId);

      // فقط یک عادت برای کل چالش ایجاد کن
      List<String> subHabits = [];
      for (var habit in challengeHabits) {
        subHabits.add(habit['title']);
      }

      // عنوان عادت با شمارش روزهای باقیمانده
      final remainingDays = endDate.difference(startDate).inDays + 1;
      final titleSuffix = remainingDays > 0 ? ' (${remainingDays} روز)' : '';

      final newHabit = Habit(
        id: const Uuid().v4(), // UUID معتبر (ستون uuid در دیتابیس)
        userId: userId,
        title: '🏆 ${challenge['title']}$titleSuffix',
        description: '${challenge['description']} - $duration روز',
        subHabits: subHabits,
        completedSubHabits: [],
        iconName: 'emoji_events',
        iconColor: 0xFFFFA500,
        backgroundColor: 0xFFF5F5F5,
        frequencyType: 'daily',
        dailyIntervalDays: [1],
        weeklyDays: null,
        weeklyIntervalWeeks: 1,
        monthlyDays: null,
        monthlyIntervalMonths: 1,
        timeOfDay: 'morning',
        reminders: [],
        xpReward: xpPerDay > 0 ? xpPerDay : 5,
        currentStreak: 0,
        bestStreak: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groupId: null,
        startDate: startDate,
        endDate: endDate,
        challengeId: challengeId,
        questId: null,
        // اضافه کردن فیلدهای سطح از challenge
        fullDescription: challenge['full_description'] ?? 'انجام کامل چالش',
        halfDescription: challenge['half_description'] ?? 'انجام نیمی از چالش',
        basicDescription: challenge['basic_description'] ?? 'انجام حداقل چالش',
        targetValue: challenge['target_value'],
      );

      await createHabit(newHabit);
      print('Challenge habit created: ${newHabit.title}');
      print('Start: ${newHabit.startDate}');
      print('End: ${newHabit.endDate}');
    } catch (e) {
      print('Error adding challenge habit: $e');
      rethrow;
    }
  }

// lib/services/supabase_service.dart

  Future<void> completeChallengeDay({
    required String userId,
    required String challengeId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      // 1. بررسی اینکه آیا تاریخ در محدوده چالش است
      final userChallenge = await client
          .from('user_challenges')
          .select('challenge_start_date, challenge_end_date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      if (userChallenge != null) {
        // فقط بخش تاریخ؛ اگر ساعت ذخیره شده باشد روز اول به‌اشتباه «خارج از محدوده» می‌شد
        final sd = DateTime.parse(userChallenge['challenge_start_date']);
        final ed = DateTime.parse(userChallenge['challenge_end_date']);
        final startDate = DateTime(sd.year, sd.month, sd.day);
        final endDate = DateTime(ed.year, ed.month, ed.day);

        final checkDate = DateTime(date.year, date.month, date.day);

        // اگر تاریخ خارج از محدوده است، ثبت نشود
        if (checkDate.isBefore(startDate) || checkDate.isAfter(endDate)) {
          print('Date $dateStr is outside challenge range');
          return;
        }

        // اگر تاریخ آینده است، ثبت نشود
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (checkDate.isAfter(today)) {
          print('Date $dateStr is in the future');
          return;
        }
      }

      // 2. حذف رکورد قبلی (اگر وجود دارد)
      await client
          .from('challenge_completions')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .eq('date', dateStr);

      // 3. درج رکورد جدید
      await client.from('challenge_completions').insert({
        'user_id': userId,
        'challenge_id': challengeId,
        'date': dateStr,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. به‌روزرسانی progress در user_challenges با تعداد واقعی
      final completionsCount = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      // فقط روزهایی که در محدوده چالش هستند و از امروز گذشته نیستند
      int validCompletions = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (userChallenge != null) {
        final sd = DateTime.parse(userChallenge['challenge_start_date']);
        final ed = DateTime.parse(userChallenge['challenge_end_date']);
        final startDate = DateTime(sd.year, sd.month, sd.day);
        final endDate = DateTime(ed.year, ed.month, ed.day);

        for (var completion in completionsCount) {
          final compDate = DateTime.parse(completion['date'] as String);
          final compDateOnly =
              DateTime(compDate.year, compDate.month, compDate.day);

          if (compDateOnly.isBefore(startDate) ||
              compDateOnly.isAfter(endDate)) {
            continue;
          }
          if (compDateOnly.isAfter(today)) {
            continue;
          }
          validCompletions++;
        }
      }

      await client
          .from('user_challenges')
          .update({
            'progress': validCompletions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print(
          '✅ Challenge day recorded: $challengeId - $dateStr (progress: $validCompletions)');
    } catch (e) {
      print('Error completing challenge day: $e');
      rethrow; // تا کاربر/برنامه‌نویس خطای واقعی را ببیند
    }
  }

  // دریافت چالش‌های فعال یک عادت
  Future<List<Map<String, dynamic>>> getActiveChallengesForHabit(
    String userId,
    String habitId,
  ) async {
    try {
      // این متد باید چالش‌هایی که این عادت در آنها وجود دارد را پیدا کند
      // بستگی به ساختار دیتابیس شما دارد
      return [];
    } catch (e, stk) {
      Log.e('supabase', 'Error getting active challenges for habit: $e', error: e, stack: stk);
      return [];
    }
  }

// lib/services/supabase_service.dart

  Future<void> leaveChallenge(String userId, String challengeId) async {
    try {
      print('Leaving challenge: $challengeId for user: $userId');

      // 1. دریافت رکورد user_challenge
      final response = await client
          .from('user_challenges')
          .select()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (response.isNotEmpty) {
        // 2. حذف از user_challenges
        await client
            .from('user_challenges')
            .delete()
            .eq('id', response[0]['id']);

        print('User challenge removed from database');
      }

      // 3. حذف همه رکوردهای challenge_completions
      await client
          .from('challenge_completions')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      print('Challenge completions removed from database');

      // 4. حذف عادت‌های مرتبط با چالش
      final habits = await client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (habits.isNotEmpty) {
        final habitIds = habits.map((h) => h['id'] as String).toList();

        // حذف تکمیل‌های عادت‌ها
        await client
            .from('habit_completions')
            .delete()
            .eq('user_id', userId)
            .inFilter('habit_id', habitIds);

        // حذف خود عادت‌ها
        await client
            .from('habits')
            .delete()
            .eq('user_id', userId)
            .inFilter('id', habitIds);

        print('${habitIds.length} challenge habits removed');
      }

      // 5. حذف از LocalStorage
      try {
        final localStorage = LocalStorageService();

        // حذف عادت‌های چالش
        final localHabits = localStorage.getHabits();
        final updatedHabits =
            localHabits.where((h) => h.challengeId != challengeId).toList();
        await localStorage.saveHabits(updatedHabits);

        // حذف چالش کاربر
        final userChallenges = localStorage.getUserChallenges();
        final updatedUserChallenges =
            userChallenges.where((c) => c['id'] != challengeId).toList();
        await localStorage.saveUserChallenges(updatedUserChallenges);

        print('Removed from LocalStorage');
      } catch (e, stk) {
        Log.e('supabase', 'Error removing from LocalStorage: $e', error: e, stack: stk);
      }

      print('User left challenge completely: $challengeId');
    } catch (e) {
      print('Error leaving challenge: $e');
      rethrow;
    }
  }

  // حذف عادت‌های چالش از دیتابیس و localStorage
  Future<void> removeChallengeHabitByChallengeId(
    String userId,
    String challengeId,
  ) async {
    try {
      // 1. دریافت عادت‌های چالش از دیتابیس
      final habits = await client
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (habits.isNotEmpty) {
        // 2. حذف تکمیل‌های عادت‌ها
        for (var habit in habits) {
          await client
              .from('habit_completions')
              .delete()
              .eq('habit_id', habit['id'])
              .eq('user_id', userId);
        }

        // 3. حذف خود عادت‌ها
        final habitIds = habits.map((h) => h['id'] as String).toList();
        await client
            .from('habits')
            .delete()
            .eq('user_id', userId)
            .inFilter('id', habitIds);

        print('Deleted ${habitIds.length} challenge habits');
      }
    } catch (e) {
      print('Error removing challenge habits: $e');
      rethrow;
    }
  }
}
