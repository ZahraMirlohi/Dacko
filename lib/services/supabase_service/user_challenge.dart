// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): getRealParticipantsCount, getUserChallenges, getUserChallengeProgressDetails, checkExpiredChallenges, removeChallengeDay, checkAndUpdateUserChallenges…
part of '../supabase_service.dart';

extension SupabaseServiceUserChallenge on SupabaseService {

  Future<int> getRealParticipantsCount(String challengeId) async {
    try {
      final response = await client
          .from('user_challenges')
          .select('id')
          .eq('challenge_id', challengeId);

      return response.length;
    } catch (e, stk) {
      Log.e('supabase', 'getRealParticipantsCount failed', error: e, stack: stk);
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    if (!await isOnline()) {
      print('Offline - skipping getUserChallenges');
      return [];
    }

    try {
      // همه چالش‌های کاربر رو بگیر (حتی اونایی که is_active = false)
      final response =
          await client.from('user_challenges').select().eq('user_id', userId);

      List<Map<String, dynamic>> result = [];
      for (var item in response) {
        final challengeId = item['challenge_id'];
        if (challengeId != null) {
          final challenge = await getChallengeById(challengeId);
          if (challenge != null) {
            final data = Map<String, dynamic>.from(challenge);
            data['userProgressId'] = item['id'];
            data['progress'] = item['progress'] ?? 0;
            data['isCompleted'] = item['is_completed'] ?? false;
            data['status'] = item['status'] ?? 'active';
            data['is_active'] = item['is_active'] ?? true;
            data['challenge_start_date'] = item['challenge_start_date'];
            data['challenge_end_date'] = item['challenge_end_date'];
            data['user_challenge_id'] = item['id'];
            result.add(data);
          }
        }
      }

      print('Found ${result.length} user challenges');
      return result;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting user challenges: $e', error: e, stack: stk);
      return [];
    }
  }

// lib/services/supabase_service.dart

  Future<Map<String, int>> getUserChallengeProgressDetails(
    String userId,
    String challengeId,
  ) async {
    try {
      // 1. دریافت اطلاعات چالش
      final challengeResponse = await client
          .from('challenges')
          .select('challenge_duration')
          .eq('id', challengeId)
          .maybeSingle();

      if (challengeResponse == null) {
        return {'completedDays': 0, 'totalDays': 0};
      }

      final totalDays = challengeResponse['challenge_duration'] as int? ?? 7;

      // 2. دریافت user_challenge برای این کاربر
      final userChallenge = await client
          .from('user_challenges')
          .select(
            'challenge_start_date, challenge_end_date, progress, is_completed, status',
          )
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      if (userChallenge == null) {
        return {'completedDays': 0, 'totalDays': totalDays};
      }

      // 3. اگر چالش کامل شده، progress رو برگردون
      if (userChallenge['is_completed'] == true) {
        return {
          'completedDays': userChallenge['progress'] as int? ?? totalDays,
          'totalDays': totalDays,
        };
      }

      // 4. دریافت تاریخ‌های تکمیل شده
      final completions = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      if (completions.isEmpty) {
        return {'completedDays': 0, 'totalDays': totalDays};
      }

      // 5. محاسبه روزهای تکمیل شده - فقط روزهای معتبر
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // دریافت محدوده چالش
      final startDate = DateTime.parse(userChallenge['challenge_start_date']);
      final start = DateTime(startDate.year, startDate.month, startDate.day);

      final endDate = DateTime.parse(userChallenge['challenge_end_date']);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      // فقط روزهایی که در محدوده چالش هستند و از امروز گذشته نیستند
      int completedDays = 0;
      final Set<String> uniqueDates = {};

      for (var completion in completions) {
        final completionDate = DateTime.parse(completion['date'] as String);
        final compDate = DateTime(
          completionDate.year,
          completionDate.month,
          completionDate.day,
        );

        // بررسی محدوده
        if (compDate.isBefore(start) || compDate.isAfter(end)) {
          continue;
        }

        // بررسی اینکه تاریخ آینده نباشد
        if (compDate.isAfter(today)) {
          continue;
        }

        // حذف تکراری‌ها
        final dateKey = compDate.toIso8601String().split('T').first;
        if (!uniqueDates.contains(dateKey)) {
          uniqueDates.add(dateKey);
          completedDays++;
        }
      }

      // اطمینان از اینکه از totalDays بیشتر نشود
      if (completedDays > totalDays) {
        completedDays = totalDays;
      }

      print('Challenge progress: $completedDays / $totalDays days');
      print(
          '📅 Total completions: ${completions.length}, Unique: ${uniqueDates.length}');

      return {'completedDays': completedDays, 'totalDays': totalDays};
    } catch (e, stk) {
      Log.e('supabase', 'Error getting challenge progress: $e', error: e, stack: stk);
      return {'completedDays': 0, 'totalDays': 0};
    }
  }

  // بررسی چالش‌های منقضی شده
  Future<void> checkExpiredChallenges(String userId) async {
    try {
      final now = DateTime.now();

      // دریافت چالش‌های فعال کاربر
      final userChallenges = await client
          .from('user_challenges')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_completed', false);

      if (userChallenges.isEmpty) return;

      for (var userChallenge in userChallenges) {
        final challengeId = userChallenge['challenge_id'];

        // دریافت اطلاعات چالش
        final challengeResponse = await client
            .from('challenges')
            .select('*')
            .eq('id', challengeId)
            .maybeSingle();

        if (challengeResponse == null) continue;

        final challenge = challengeResponse;

        // بررسی تاریخ پایان ثبت‌نام
        final registrationEnd = challenge['registration_end_date'] != null
            ? DateTime.parse(challenge['registration_end_date'])
            : null;

        // بررسی تاریخ پایان چالش
        final challengeEnd = userChallenge['challenge_end_date'] != null
            ? DateTime.parse(userChallenge['challenge_end_date'])
            : null;

        // اگر تاریخ ثبت‌نام گذشته باشد
        if (registrationEnd != null && registrationEnd.isBefore(now)) {
          await client.from('user_challenges').update({
            'is_active': false,
            'status': 'expired',
            'updated_at': now.toIso8601String(),
          }).eq('id', userChallenge['id']);

          print('Challenge expired: ${challenge['title']}');
        }

        // اگر تاریخ پایان چالش گذشته باشد و کامل نشده
        if (challengeEnd != null &&
            challengeEnd.isBefore(now) &&
            userChallenge['is_completed'] == false) {
          await client.from('user_challenges').update({
            'is_active': false,
            'status': 'failed',
            'completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }).eq('id', userChallenge['id']);

          print('Challenge ended without completion: ${challenge['title']}');
        }
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error checking expired challenges: $e', error: e, stack: stk);
    }
  }
  // lib/services/supabase_service.dart

  // حذف تکمیل روزانه چالش
  Future<void> removeChallengeDay({
    required String userId,
    required String challengeId,
    required DateTime date,
  }) async {
    try {
      // 1. بررسی اینکه آیا کاربر این چالش رو دارد
      final userChallenge = await client
          .from('user_challenges')
          .select('id, is_active, is_completed')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .eq('is_active', true)
          .eq('is_completed', false)
          .maybeSingle();

      if (userChallenge == null) {
        print('User is not active in this challenge: $challengeId');
        return;
      }

      // 2. حذف تکمیل روزانه
      final dateStr = date.toIso8601String().split('T').first;
      await client
          .from('challenge_completions')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .eq('date', dateStr);

      // 3. به‌روزرسانی progress در user_challenges
      final completionsCount = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      final completedDays = completionsCount.length;

      await client.from('user_challenges').update({
        'progress': completedDays,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userChallenge['id']);

      print('Challenge day removed: $challengeId - Now $completedDays days');
    } catch (e, stk) {
      Log.e('supabase', 'Error removing challenge day: $e', error: e, stack: stk);
    }
  }

  // بررسی و بروزرسانی وضعیت چالش‌های کاربر
  Future<void> checkAndUpdateUserChallenges(String userId) async {
    try {
      final userChallenges = await client
          .from('user_challenges')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_completed', false);

      if (userChallenges.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool needRefresh = false;

      for (var userChallenge in userChallenges) {
        final challengeId = userChallenge['challenge_id'];

        final challengeResponse = await client
            .from('challenges')
            .select('*')
            .eq('id', challengeId)
            .maybeSingle();

        if (challengeResponse == null) continue;

        final challenge = challengeResponse;
        final userChallengeId = userChallenge['id'];
        final challengeDuration = challenge['challenge_duration'] as int? ?? 7;

        // تاریخ شروع چالش
        DateTime startDate;
        if (userChallenge['challenge_start_date'] != null) {
          startDate = DateTime.parse(userChallenge['challenge_start_date']);
        } else if (userChallenge['joined_at'] != null) {
          startDate = DateTime.parse(userChallenge['joined_at']);
        } else {
          startDate = today;
        }

        final start = DateTime(startDate.year, startDate.month, startDate.day);

        // محاسبه روزهای گذشته از شروع چالش
        final daysSinceStart = today.difference(start).inDays + 1;

        // اگر کاربر تمام روزهای چالش را انجام داده باشد
        if (daysSinceStart >= challengeDuration) {
          final completedDays = await _getUserCompletedDaysForChallenge(
            userId,
            challengeId,
          );

          if (completedDays >= challengeDuration) {
            // چالش با موفقیت کامل شده
            await _completeChallenge(userId, userChallengeId, challenge);
            needRefresh = true;
          } else {
            // چالش ناموفق (همه روزها رو انجام نداده)
            await _failChallenge(userId, userChallengeId, challenge);
            needRefresh = true;
          }
          continue;
        }

        // بررسی آخرین روز انجام شده
        final lastCompletedDate = await _getLastCompletedDate(
          userId,
          challengeId,
        );

        if (lastCompletedDate != null) {
          final lastDate = DateTime(
            lastCompletedDate.year,
            lastCompletedDate.month,
            lastCompletedDate.day,
          );
          final daysGap = today.difference(lastDate).inDays;

          // اگر بیش از 1 روز از آخرین انجام گذشته باشد
          if (daysGap > 1) {
            // استریک شکسته شده، چالش ناموفق
            await _failChallenge(userId, userChallengeId, challenge);
            needRefresh = true;
          }
        }
      }

      if (needRefresh) {
        await _refreshUserChallenges(userId);
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error checking user challenges: $e', error: e, stack: stk);
    }
  }

  // دریافت آخرین روز تکمیل شده
  Future<DateTime?> _getLastCompletedDate(
    String userId,
    String challengeId,
  ) async {
    try {
      final completions = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .order('date', ascending: false)
          .limit(1);

      if (completions.isNotEmpty) {
        return DateTime.parse(completions.first['date'] as String);
      }
      return null;
    } catch (e, stk) {
      Log.e('supabase', '_getLastCompletedDate failed', error: e, stack: stk);
      return null;
    }
  }

  // دریافت تعداد روزهای تکمیل شده برای یک چالش
  Future<int> _getUserCompletedDaysForChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      final completions = await client
          .from('challenge_completions')
          .select('date')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);

      return completions.length;
    } catch (e, stk) {
      Log.e('supabase', '_getUserCompletedDaysForChallenge failed', error: e, stack: stk);
      return 0;
    }
  }

// lib/services/supabase_service.dart

  Future<void> _failChallenge(
    String userId,
    String userChallengeId,
    Map<String, dynamic> challenge,
  ) async {
    final now = DateTime.now();
    final challengeId = challenge['id'];

    // 1. حذف کامل از user_challenges
    await client.from('user_challenges').delete().eq('id', userChallengeId);

    // 2. حذف رکوردهای challenge_completions
    await client
        .from('challenge_completions')
        .delete()
        .eq('user_id', userId)
        .eq('challenge_id', challengeId);

    print('Challenge completions cleared after failure');

    // 3. حذف عادت‌های چالش
    try {
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
    } catch (e, stk) {
      Log.e('supabase', 'Error removing challenge habits: $e', error: e, stack: stk);
    }

    // 4. حذف از LocalStorage
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

    print('Challenge failed and removed: ${challenge['title']}');
  }

// متد جدید برای بررسی روزانه استریک چالش‌ها
  Future<void> checkUserChallengeStreak(String userId) async {
    try {
      final userChallenges = await client
          .from('user_challenges')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_completed', false);

      if (userChallenges.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var userChallenge in userChallenges) {
        final challengeId = userChallenge['challenge_id'];

        // دریافت اطلاعات چالش
        final challenge = await getChallengeById(challengeId);
        if (challenge == null) continue;

        // دریافت آخرین روز تکمیل شده
        final lastCompleted = await _getLastCompletedDate(userId, challengeId);

        if (lastCompleted != null) {
          final lastDate = DateTime(
            lastCompleted.year,
            lastCompleted.month,
            lastCompleted.day,
          );
          final daysGap = today.difference(lastDate).inDays;

          // اگر بیش از 1 روز از آخرین انجام گذشته باشد شکست
          if (daysGap > 1) {
            print(
                '❌ Streak broken for challenge: $challengeId (gap: $daysGap days)');
            await _failChallenge(userId, userChallenge['id'], challenge);

            // بعد از شکست، از حلقه خارج شو (چالش غیرفعال شده)
            continue;
          }
        }

        // بررسی تاریخ پایان چالش
        if (userChallenge['challenge_end_date'] != null) {
          final endDate = DateTime.parse(userChallenge['challenge_end_date']);
          if (endDate.isBefore(now)) {
            // اگر تاریخ پایان گذشته، چک کن که کامل شده یا نه
            final completedDays = await _getUserCompletedDaysForChallenge(
              userId,
              challengeId,
            );
            final totalDays = challenge['challenge_duration'] as int? ?? 7;

            if (completedDays < totalDays) {
              print('Challenge expired without completion: $challengeId');
              await _failChallenge(userId, userChallenge['id'], challenge);
            }
          }
        }
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error checking user challenge streak: $e', error: e, stack: stk);
    }
  }

  // lib/services/supabase_service.dart

// متد جدید برای بررسی عادت‌های شکست خورده در پایان روز
  Future<void> checkFailedHabits(String userId) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().split('T').first;

      // دریافت تمام عادت‌های فعال کاربر
      final habits = await getHabits(userId);
      final activeHabits = habits.where((h) => h.isActive).toList();

      for (var habit in activeHabits) {
        // بررسی اینکه آیا عادت باید در دیروز انجام می‌شده
        if (!habit.shouldDoOnDate(yesterday)) continue;

        // بررسی اینکه آیا عادت در دیروز تکمیل شده
        final isCompleted = await isHabitCompletedOnDate(
          habit.id,
          userId,
          yesterday,
        );

        if (!isCompleted) {
          // اگر تکمیل نشده، به عنوان شکست خورده ثبت کن
          // اما فقط اگر چالش یا ماموریت نباشد
          if (habit.challengeId == null && habit.questId == null) {
            // ثبت در جدول habit_failures (اگر وجود دارد)
            // یا به‌روزرسانی استریک
            print('Habit failed: ${habit.title} on $yesterdayStr');

            // به‌روزرسانی استریک کاربر
            await updateUserStreak(userId);
          }
        }
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error checking failed habits: $e', error: e, stack: stk);
    }
  }

// متد برای اجرای بررسی روزانه (در زمان بیدار شدن اپ)
  Future<void> runDailyCheck(String userId) async {
    try {
      // 1. بررسی چالش‌ها
      await checkUserChallengeStreak(userId);

      // 2. بررسی عادت‌های شکست خورده
      await checkFailedHabits(userId);

      // 3. به‌روزرسانی استریک
      await updateUserStreak(userId);

      print('Daily check completed for user: $userId');
    } catch (e, stk) {
      Log.e('supabase', 'Error in daily check: $e', error: e, stack: stk);
    }
  }

// اضافه کردن تایمر برای بررسی دوره‌ای
  void startStreakCheckTimer(String userId) {
    // هر 6 ساعت یکبار بررسی کن
    Timer.periodic(const Duration(hours: 6), (timer) {
      checkUserChallengeStreak(userId);
    });
  }
}
