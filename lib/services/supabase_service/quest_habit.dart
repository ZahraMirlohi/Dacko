// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): startQuest, debugSession, _parseColor, updateQuestProgress, _updateQuestHabitTitle, _completeQuest…
part of '../supabase_service.dart';

extension SupabaseServiceQuestHabit on SupabaseService {

// lib/services/supabase_service.dart

  Future<void> startQuest(String userId, Quest quest) async {
    try {
      // 1. بررسی وجود ماموریت قبلی
      final existing = await client
          .from('user_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_id', quest.id);

      if (existing.isNotEmpty) {
        if (existing.first['is_completed'] == true) {
          throw Exception('شما قبلاً این ماموریت را تکمیل کرده‌اید! 🏆');
        }
        throw Exception('شما قبلاً این ماموریت را شروع کرده‌اید!');
      }

      // تاریخ امروز (بدون ساعت)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 2. ایجاد عادت ماموریت با فیلدهای سطح
      final habit = Habit(
        id: const Uuid().v4(), // UUID معتبر (ستون uuid در دیتابیس)
        userId: userId,
        title: '🎯 ${quest.title} (0/${quest.targetCount})',
        description: quest.description,
        subHabits: [],
        completedSubHabits: [],
        iconName: quest.icon,
        iconColor: _parseColor(quest.color),
        backgroundColor: 0xFFF5F5F5,
        frequencyType: 'daily',
        dailyIntervalDays: [1],
        weeklyDays: null,
        weeklyIntervalWeeks: 1,
        monthlyDays: null,
        monthlyIntervalMonths: 1,
        timeOfDay: 'morning',
        reminders: [],
        xpReward: 5,
        currentStreak: 0,
        bestStreak: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groupId: null,
        startDate: today,
        endDate: null, // بدون تاریخ پایان (بی‌نهایت)
        challengeId: null,
        questId: quest.id,
        // اضافه کردن فیلدهای سطح از Quest
        fullDescription: quest.fullDescription ?? 'انجام کامل ماموریت',
        halfDescription: quest.halfDescription ?? 'انجام نیمی از ماموریت',
        basicDescription: quest.basicDescription ?? 'انجام حداقل ماموریت',
        targetValue: quest.targetValue ?? '${quest.targetCount} روز',
      );

      // 3. ذخیره عادت در دیتابیس
      await createHabit(habit);
      print('Habit created for quest: ${habit.title}');
      print('Full: ${habit.fullDescription}');
      print('Half: ${habit.halfDescription}');
      print('Basic: ${habit.basicDescription}');
      print('Target: ${habit.targetValue}');

      // 4. ذخیره در LocalStorage
      try {
        final localStorage = LocalStorageService();
        await localStorage.saveHabit(habit);
        print('Habit saved to local storage');
      } catch (e, stk) {
        Log.e('supabase', 'Error saving habit to local storage: $e', error: e, stack: stk);
      }

      // 5. ثبت در user_quests
      await client.from('user_quests').insert({
        'user_id': userId,
        'quest_id': quest.id,
        'habit_id': habit.id,
        'progress': 0,
        'is_completed': false,
        'started_at': today.toIso8601String(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('User quest started: ${quest.title}');
    } catch (e) {
      print('Error starting quest: $e');
      rethrow;
    }
  }

  /// بررسی وضعیت session
  void debugSession() {
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    print('===== SESSION DEBUG =====');
    print('currentUser: ${user?.id}');
    print('currentSession: ${session?.accessToken?.substring(0, 20)}...');
    print('session.expiresAt: ${session?.expiresAt}');
    print('now: ${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
    print('isExpired: ${session?.isExpired}');
    print('=========================');
  }

  int _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return int.parse('FF${colorStr.substring(1)}', radix: 16);
      }
      return 0xFF4A90E2;
    } catch (e, stk) {
      Log.e('supabase', '_parseColor failed', error: e, stack: stk);
      return 0xFF4A90E2;
    }
  }

// lib/services/supabase_service.dart

  Future<Quest?> updateQuestProgress(String userId, String habitId) async {
    try {
      print('===== updateQuestProgress START =====');
      print('userId: $userId');
      print('habitId: $habitId');

      // 1. دریافت عادت
      final habitCheck = await client
          .from('habits')
          .select()
          .eq('id', habitId)
          .eq('user_id', userId)
          .maybeSingle();

      if (habitCheck == null) {
        print('Habit not found: $habitId');
        return null;
      }

      print('Habit found: ${habitCheck['title']}');
      print('Quest ID from habit: ${habitCheck['quest_id']}');

      // 2. دریافت user_quest
      var userQuestResponse = await client
          .from('user_quests')
          .select()
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .eq('is_active', true);

      if (userQuestResponse.isEmpty) {
        final questId = habitCheck['quest_id'];
        if (questId == null) {
          print('No quest_id found for habit: $habitId');
          return null;
        }

        print('Looking for user_quest with quest_id: $questId');
        userQuestResponse = await client
            .from('user_quests')
            .select()
            .eq('user_id', userId)
            .eq('quest_id', questId)
            .eq('is_active', true);
      }

      if (userQuestResponse.isEmpty) {
        print('No user_quest found');
        return null;
      }

      final userQuest = userQuestResponse.first;
      final questId = userQuest['quest_id'];
      final currentProgress = userQuest['progress'] as int? ?? 0;

      // پیشرفت = تعداد روزهای متمایز انجام‌شده (انجام چندباره در یک روز حساب نمی‌شود)
      final doneRows = await client
          .from('habit_completions')
          .select('date')
          .eq('habit_id', habitId);
      final doneDays = <String>{
        for (final r in doneRows) (r['date'] as String).split('T').first,
      };
      final nowD = DateTime.now();
      doneDays.add(
          '${nowD.year.toString().padLeft(4, '0')}-${nowD.month.toString().padLeft(2, '0')}-${nowD.day.toString().padLeft(2, '0')}');
      final newProgress = doneDays.length;
      if (newProgress <= currentProgress) {
        return null; // همان روز، پیشرفت جدیدی ثبت نمی‌شود
      }

      print('Current progress: $currentProgress');
      print('New progress: $newProgress');

      // 3. دریافت اطلاعات ماموریت
      final questResponse =
          await client.from('quests').select().eq('id', questId).single();

      final targetCount = questResponse['target_count'] as int;
      print('Target count: $targetCount');

      // 4. به‌روزرسانی عنوان عادت
      await _updateQuestHabitTitle(habitId, newProgress, targetCount);

      // 5. اگر کامل شده
      if (newProgress >= targetCount) {
        print('Quest completed!');
        final quest = await _completeQuest(
          userId,
          userQuest['id'],
          habitId,
          questResponse,
        );
        return quest;
      } else {
        // 6. به‌روزرسانی progress در دیتابیس (بدون updated_at)
        print('Updating progress to: $newProgress');
        await client.from('user_quests').update({
          'progress': newProgress,
          // حذف updated_at
        }).eq('id', userQuest['id']);

        // 7. به‌روزرسانی LocalStorage
        try {
          final localStorage = LocalStorageService();
          final habits = localStorage.getHabits();
          final index = habits.indexWhere((h) => h.id == habitId);
          if (index != -1) {
            final updatedHabit = Habit(
              id: habits[index].id,
              userId: habits[index].userId,
              title: '🎯 ${questResponse['title']} ($newProgress/$targetCount)',
              description: habits[index].description,
              subHabits: habits[index].subHabits,
              completedSubHabits: habits[index].completedSubHabits,
              iconName: habits[index].iconName,
              iconColor: habits[index].iconColor,
              backgroundColor: habits[index].backgroundColor,
              frequencyType: habits[index].frequencyType,
              dailyIntervalDays: habits[index].dailyIntervalDays,
              weeklyDays: habits[index].weeklyDays,
              weeklyIntervalWeeks: habits[index].weeklyIntervalWeeks,
              monthlyDays: habits[index].monthlyDays,
              monthlyIntervalMonths: habits[index].monthlyIntervalMonths,
              timeOfDay: habits[index].timeOfDay,
              reminders: habits[index].reminders,
              xpReward: habits[index].xpReward,
              currentStreak: habits[index].currentStreak,
              bestStreak: habits[index].bestStreak,
              isActive: habits[index].isActive,
              createdAt: habits[index].createdAt,
              updatedAt: DateTime.now(),
              groupId: habits[index].groupId,
              startDate: habits[index].startDate,
              endDate: habits[index].endDate,
              challengeId: habits[index].challengeId,
              questId: habits[index].questId,
            );
            await localStorage.saveHabit(updatedHabit);
            print('LocalStorage updated');
          }
        } catch (e, stk) {
          Log.e('supabase', 'Error updating local habit title: $e', error: e, stack: stk);
        }

        print('Quest progress updated: $newProgress/$targetCount');
        return null;
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error updating quest progress: $e', error: e, stack: stk);
      return null;
    }
  }

  Future<void> _updateQuestHabitTitle(
    String habitId,
    int progress,
    int target,
  ) async {
    try {
      print(
          '📊 _updateQuestHabitTitle: habitId=$habitId, progress=$progress, target=$target');

      // 1. دریافت عادت از دیتابیس
      final habit = await client
          .from('habits')
          .select('title')
          .eq('id', habitId)
          .maybeSingle();

      if (habit == null) {
        print('Habit not found for title update: $habitId');
        return;
      }

      // 2. استخراج عنوان اصلی (بدون اعداد)
      String originalTitle = habit['title'] ?? 'ماموریت';
      final regex = RegExp(r'\s*\(\d+/\d+\)\s*$');
      originalTitle = originalTitle.replaceAll(regex, '').trim();

      // 3. ساخت عنوان جدید
      final newTitle = '$originalTitle ($progress/$target)';
      print('New title: $newTitle');

      // 4. به‌روزرسانی در دیتابیس
      await client.from('habits').update({
        'title': newTitle,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', habitId);

      print('Habit title updated: $newTitle');

      // 5. به‌روزرسانی در LocalStorage
      try {
        final localStorage = LocalStorageService();
        final localHabits = localStorage.getHabits();
        final index = localHabits.indexWhere((h) => h.id == habitId);

        if (index != -1) {
          final updatedHabit = Habit(
            id: localHabits[index].id,
            userId: localHabits[index].userId,
            title: newTitle,
            description: localHabits[index].description,
            subHabits: localHabits[index].subHabits,
            completedSubHabits: localHabits[index].completedSubHabits,
            iconName: localHabits[index].iconName,
            iconColor: localHabits[index].iconColor,
            backgroundColor: localHabits[index].backgroundColor,
            frequencyType: localHabits[index].frequencyType,
            dailyIntervalDays: localHabits[index].dailyIntervalDays,
            weeklyDays: localHabits[index].weeklyDays,
            weeklyIntervalWeeks: localHabits[index].weeklyIntervalWeeks,
            monthlyDays: localHabits[index].monthlyDays,
            monthlyIntervalMonths: localHabits[index].monthlyIntervalMonths,
            timeOfDay: localHabits[index].timeOfDay,
            reminders: localHabits[index].reminders,
            xpReward: localHabits[index].xpReward,
            currentStreak: localHabits[index].currentStreak,
            bestStreak: localHabits[index].bestStreak,
            isActive: localHabits[index].isActive,
            createdAt: localHabits[index].createdAt,
            updatedAt: DateTime.now(),
            groupId: localHabits[index].groupId,
            startDate: localHabits[index].startDate,
            endDate: localHabits[index].endDate,
            challengeId: localHabits[index].challengeId,
            questId: localHabits[index].questId,
          );
          await localStorage.saveHabit(updatedHabit);
          print('Habit title updated in local storage');
        }
      } catch (e, stk) {
        Log.e('supabase', 'Error updating local habit title: $e', error: e, stack: stk);
      }
    } catch (e, stk) {
      Log.e('supabase', 'Error updating quest habit title: $e', error: e, stack: stk);
    }
  }

  // lib/services/supabase_service.dart

  Future<Quest> _completeQuest(
    String userId,
    String userQuestId,
    String habitId,
    Map<String, dynamic> questData,
  ) async {
    try {
      final now = DateTime.now();

      // 1. به‌روزرسانی user_quests (بدون updated_at)
      await client.from('user_quests').update({
        'progress': questData['target_count'],
        'is_completed': true,
        'completed_at': now.toIso8601String(),
        'is_active': false,
        // حذف updated_at
      }).eq('id', userQuestId);

      // 2. حذف عادت ماموریت
      await deleteHabit(habitId);

      // 3. حذف از LocalStorage
      try {
        final localStorage = LocalStorageService();
        await localStorage.deleteHabit(habitId);
      } catch (e, stk) {
        Log.e('supabase', '_completeQuest failed', error: e, stack: stk);
        // خطا را نادیده بگیر
      }

      // 4. افزودن XP پاداش
      final xpReward = questData['xp_reward'] as int? ?? 0;
      await addXP(userId, xpReward);

      // 5. افزودن مدال
      final badge = questData['badge'] as String? ?? '🎯';
      await _addBadgeToUser(userId, badge, title: questData['title'] as String?);

      final quest = Quest.fromMap(questData, questData['id']);
      return quest;
    } catch (e) {
      print('Error completing quest: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalHabitTitle(String habitId, String newTitle) async {
    try {
      final localStorage = LocalStorageService();
      final localHabits = localStorage.getHabits();
      final index = localHabits.indexWhere((h) => h.id == habitId);

      if (index != -1) {
        final updatedHabit = Habit(
          id: localHabits[index].id,
          userId: localHabits[index].userId,
          title: newTitle,
          description: localHabits[index].description,
          subHabits: localHabits[index].subHabits,
          completedSubHabits: localHabits[index].completedSubHabits,
          iconName: localHabits[index].iconName,
          iconColor: localHabits[index].iconColor,
          backgroundColor: localHabits[index].backgroundColor,
          frequencyType: localHabits[index].frequencyType,
          dailyIntervalDays: localHabits[index].dailyIntervalDays,
          weeklyDays: localHabits[index].weeklyDays,
          weeklyIntervalWeeks: localHabits[index].weeklyIntervalWeeks,
          monthlyDays: localHabits[index].monthlyDays,
          monthlyIntervalMonths: localHabits[index].monthlyIntervalMonths,
          timeOfDay: localHabits[index].timeOfDay,
          reminders: localHabits[index].reminders,
          xpReward: localHabits[index].xpReward,
          currentStreak: localHabits[index].currentStreak,
          bestStreak: localHabits[index].bestStreak,
          isActive: localHabits[index].isActive,
          createdAt: localHabits[index].createdAt,
          updatedAt: DateTime.now(),
          groupId: localHabits[index].groupId,
          startDate: localHabits[index].startDate,
          endDate: localHabits[index].endDate,
          challengeId: localHabits[index].challengeId,
          questId: localHabits[index].questId,
        );
        await localStorage.saveHabit(updatedHabit);
      }
    } catch (e, stk) {
      Log.e('supabase', '_updateLocalHabitTitle failed', error: e, stack: stk);
      // ignore
    }
  }

// lib/services/supabase_service.dart

  Future<void> _addBadgeToUser(String userId, String badge,
      {String? title}) async {
    // نام یکتا برای هر ماموریت، تا مدال‌های هم‌آیکون روی هم نیفتند
    final name = (title == null || title.isEmpty) ? badge : '$badge $title';
    try {
      // بررسی وجود مدال تکراری
      final existing = await client
          .from('user_badges')
          .select()
          .eq('user_id', userId)
          .eq('badge_name', name)
          .maybeSingle();

      if (existing != null) {
        return;
      }

      // ثبت مدال جدید
      await client.from('user_badges').insert({
        'user_id': userId,
        'badge_name': name,
        'badge_icon': badge,
        'badge_type': 'quest',
        'earned_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });
    } catch (e, stk) {
      Log.e('supabase', '_addBadgeToUser failed', error: e, stack: stk);
      // اگر جدول وجود نداشت، خطا را نادیده بگیر
    }
  }

// lib/services/supabase_service.dart

  Future<void> cancelQuest(String userId, String questId) async {
    try {
      print('Cancelling quest: $questId for user: $userId');

      // 1. دریافت user_quest
      final userQuestResponse = await client
          .from('user_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .eq('is_active', true);

      if (userQuestResponse.isEmpty) {
        print('No active user_quest found for quest: $questId');
        return;
      }

      final userQuest = userQuestResponse.first;
      final habitId = userQuest['habit_id'];
      final userQuestId = userQuest['id'];

      // 2. حذف از user_quests
      await client.from('user_quests').delete().eq('id', userQuestId);
      print('User quest removed from database');

      // 3. حذف عادت ماموریت
      if (habitId != null && habitId.isNotEmpty) {
        await deleteHabit(habitId);
        print('Habit deleted from database: $habitId');
      }

      // 4. حذف همه عادت‌های مرتبط با این ماموریت
      await client
          .from('habits')
          .delete()
          .eq('user_id', userId)
          .eq('quest_id', questId);
      print('All quest habits removed from database');

      // 5. حذف از LocalStorage
      try {
        final localStorage = LocalStorageService();

        // حذف عادت از LocalStorage
        if (habitId != null && habitId.isNotEmpty) {
          await localStorage.deleteHabit(habitId);
          print('Habit removed from LocalStorage: $habitId');
        }

        // حذف همه عادت‌های مرتبط با این ماموریت از LocalStorage
        final localHabits = localStorage.getHabits();
        final updatedHabits =
            localHabits.where((h) => h.questId != questId).toList();
        await localStorage.saveHabits(updatedHabits);
        print('All quest habits removed from LocalStorage');
      } catch (e, stk) {
        Log.e('supabase', 'Error removing from LocalStorage: $e', error: e, stack: stk);
      }

      print('Quest cancelled successfully: $questId');
    } catch (e) {
      print('Error cancelling quest: $e');
      rethrow;
    }
  }

  // ==================== Daily Spark ====================

  Future<List<Map<String, dynamic>>> getDailySpark() async {
    try {
      final response =
          await client.from('daily_spark').select().eq('is_active', true);

      return response;
    } catch (e, stk) {
      Log.e('supabase', 'getDailySpark failed', error: e, stack: stk);
      return [];
    }
  }
}
