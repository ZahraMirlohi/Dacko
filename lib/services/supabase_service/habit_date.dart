// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): client, _client, isOnline, ensureValidSession, login, signup…
part of '../supabase_service.dart';

extension SupabaseServiceHabitDate on SupabaseService {

  SupabaseClient get client => Supabase.instance.client;

  /// Alias برای استفاده در متدهای جدید (سازگاری)
  SupabaseClient get _client => client;

  Future<bool> isOnline() async {
    try {
      if (kIsWeb) {
        return true;
      }
      final result = await InternetConnectionChecker().hasConnection;
      return result;
    } catch (e, stk) {
      Log.e('supabase', 'isOnline failed', error: e, stack: stk);
      return true;
    }
  }

  Future<bool> ensureValidSession() async {
    try {
      // چند بار تلاش کن تا از refresh در پس‌زمینه مطمئن بشی
      for (int i = 0; i < 5; i++) {
        final session = client.auth.currentSession;
        if (session != null) {
          print('[SESSION] Valid for user: ${session.user.id}');
          return true;
        }
        print('[SESSION] Attempt ${i + 1}/5: waiting for auto-refresh...');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('[SESSION] No session after 5 retries');
      return false;
    } catch (e, stk) {
      Log.e('supabase', '[SESSION] Error: $e', error: e, stack: stk);
      return false;
    }
  }

  // ==================== Auth ====================

  Future<AuthResponse> login(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // دیگر نیازی به ذخیره دستی session نیست
    return response;
  }

  Future<AuthResponse> signup(
    String email,
    String password,
    String name,
  ) async {
    final uniqueId = UniqueIdGenerator.generateSecure();
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'email': email,
        'unique_id': uniqueId,
      },
    );
    // دیگر نیازی به ذخیره دستی session نیست
    return response;
  }

  Future<void> logout() async {
    await client.auth.signOut();
    _cachedUser = null;
    _userCacheTime = null;
  }

  // متد getCurrentUser را می‌توان ساده‌تر کرد
  Future<User?> getCurrentUser() async {
    // کش نمی‌کنیم: currentUser محلی و آنی است و با تعویض حساب باید همان لحظه عوض شود
    final user = client.auth.currentUser;
    _cachedUser = user;
    _userCacheTime = user == null ? null : DateTime.now();
    return user;
  }

  void clearUserCache() {
    _cachedUser = null;
    _userCacheTime = null;
  }

  // ==================== Profiles ====================

  Future<void> createProfile(String userId, String email, String name) async {
    // تولید ID یکتا برای پروفایل
    final uniqueId = UniqueIdGenerator.generateSecure();

    await client.from('profiles').insert({
      'user_id': userId,
      'email': email,
      'name': name,
      'unique_id': uniqueId, // ذخیره unique_id
      'total_xp': 0,
    });
  }

  Future<Map<String, dynamic>?> getHabit(String habitId) async {
    try {
      print('Getting habit with ID: $habitId');

      final response =
          await client.from('habits').select().eq('id', habitId).maybeSingle();

      if (response == null) {
        print('Habit not found: $habitId');
        return null;
      }

      print('Habit found: ${response['title']}');
      return response;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting habit: $e', error: e, stack: stk);
      return null;
    }
  }

  // lib/services/supabase_service.dart

  /// گرفتن زمان رکورد شده یک عادت در یک تاریخ مشخص
  Future<int?> getHabitTimeOnDate({
    required String habitId,
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      final response = await client
          .from('habit_time_tracking')
          .select('total_seconds')
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response != null && response['total_seconds'] != null) {
        return response['total_seconds'] as int;
      }
      return null;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting habit time: $e', error: e, stack: stk);
      return null;
    }
  }

  /// لغو تیک عادت و برگرداندن «دقیقاً همان XP» که برای آن روز داده شده بود.
  /// برمی‌گرداند چند XP کم شد (۰ اگر تیکی ثبت نشده بود).
  Future<int> uncompleteHabitAndRefundXp({
    required String habitId,
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = _getDateString(date);
    int refund = 0;
    try {
      final prev = await client
          .from('habit_completions')
          .select('completion_level')
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();
      if (prev != null) {
        int xpReward = 10;
        try {
          final habit = await getHabit(habitId);
          xpReward = (habit?['xp_reward'] as int?) ?? 10;
        } catch (err, stk) { Log.w('supabase', 'uncompleteHabitAndRefundXp ignored error', error: err, stack: stk); }
        // تیک ساده (بدون سطح) یعنی کامل
        final raw = prev['completion_level'];
        final lv = CompletionLevelExtension.fromString(
            (raw == null ? 'full' : raw.toString()));
        refund = (xpReward * lv.xpMultiplier / 100).round();
      }
    } catch (err, stk) { Log.w('supabase', 'uncompleteHabitAndRefundXp ignored error', error: err, stack: stk); }

    await markHabitCompletedOnDate(habitId, userId, date, false);
    if (refund > 0) await removeXP(userId, refund);
    return refund;
  }

// اصلاح متد markHabitCompletedWithLevel - حذف onConflict
  Future<void> markHabitCompletedWithLevel({
    required String habitId,
    required String userId,
    required DateTime date,
    required CompletionLevel level,
  }) async {
    try {
      final dateStr = _getDateString(date);
      final now = DateTime.now();

      // 1. دریافت عادت و محاسبه XP
      int xpReward = 10;
      try {
        final habit = await getHabit(habitId);
        if (habit != null) {
          xpReward = habit['xp_reward'] as int? ?? 10;
        }
      } catch (e, stk) {
        Log.e('supabase', 'Could not get habit, using default XP: $e', error: e, stack: stk);
      }

      final xpEarned = (xpReward * level.xpMultiplier / 100).round();

      // XP قبلاً داده‌شدهٔ همین روز (اگر بود) تا فقط «تفاوت» اعمال شود
      int previousXp = 0;
      try {
        final prev = await client
            .from('habit_completions')
            .select('completion_level')
            .eq('habit_id', habitId)
            .eq('user_id', userId)
            .eq('date', dateStr)
            .maybeSingle();
        if (prev != null) {
          final lv = CompletionLevelExtension.fromString(
              (prev['completion_level'] ?? 'full').toString());
          previousXp = (xpReward * lv.xpMultiplier / 100).round();
        }
      } catch (err, stk) { Log.w('supabase', 'markHabitCompletedWithLevel ignored error', error: err, stack: stk); }
      final xpDelta = xpEarned - previousXp;

      // 2. حذف رکورد قبلی
      await client
          .from('habit_completions')
          .delete()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('date', dateStr);

      // 3. درج رکورد جدید
      await client.from('habit_completions').insert({
        'habit_id': habitId,
        'user_id': userId,
        'date': dateStr,
        'completion_level': level.toString().split('.').last,
        'completed_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      // 4. اجرای همزمان دو عملیات
      await Future.wait([
        if (xpDelta > 0) addXP(userId, xpDelta),
        if (xpDelta < 0) removeXP(userId, -xpDelta),
        updateUserStreak(userId),
      ]);

      print(
          '✅ Habit completed with level: ${level.displayName} (+$xpEarned XP)');
    } catch (e) {
      print('Error marking habit with level: $e');
      rethrow;
    }
  }

// متد دریافت تاریخچه تکمیل عادت با سطح (اصلاح شده)
  Future<List<HabitCompletion>> getHabitCompletionsWithLevel({
    required String habitId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ساخت کوئری با ترتیب صحیح
      var query = client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId);

      // اضافه کردن فیلترهای تاریخ با استفاده از filter
      if (startDate != null) {
        final startStr = _getDateString(startDate);
        query = query.filter('date', 'gte', startStr);
      }
      if (endDate != null) {
        final endStr = _getDateString(endDate);
        query = query.filter('date', 'lte', endStr);
      }

      // مرتب‌سازی در انتها
      final response = await query.order('date', ascending: true);

      return response.map((data) => HabitCompletion.fromMap(data)).toList();
    } catch (e, stk) {
      Log.e('supabase', 'Error getting habit completions with level: $e', error: e, stack: stk);
      return [];
    }
  }

// lib/services/supabase_service.dart

// متد دریافت داده‌های نمودار برای یک عادت (نسخه نهایی)
  Future<List<Map<String, dynamic>>> getHabitChartData({
    required String habitId,
    required String userId,
  }) async {
    try {
      // محاسبه دقیق روزهای ماه جاری
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;

      final startDate = firstDayOfMonth;
      final endDate = lastDayOfMonth;

      print(
          '📊 Chart date range: $startDate to $endDate (${daysInMonth} days)');

      // دریافت تکمیل‌های عادت در بازه ماه جاری
      final completions = await getHabitCompletionsWithLevel(
        habitId: habitId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      print('Found ${completions.length} completions for this month');

      // ساخت داده‌های نمودار
      final List<Map<String, dynamic>> chartData = [];

      for (int i = 0; i < daysInMonth; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = _getDateString(date);

        // پیدا کردن تکمیل برای این روز
        final completion = completions.firstWhere(
          (c) =>
              c.date.year == date.year &&
              c.date.month == date.month &&
              c.date.day == date.day,
          orElse: () => HabitCompletion(
            id: '',
            habitId: habitId,
            userId: userId,
            date: date,
            level: CompletionLevel.full,
            completedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        chartData.add({
          'date': dateStr,
          'day': i + 1,
          'level': completion.level.toString().split('.').last,
          'level_display': completion.level.displayName,
          'emoji': completion.level.emoji,
          'isCompleted': completion.id.isNotEmpty,
        });
      }

      print('Chart data built with ${chartData.length} days');
      return chartData;
    } catch (e, stk) {
      Log.e('supabase', 'Error getting chart data: $e', error: e, stack: stk);
      return [];
    }
  }

  // ==================== Habits ====================

  Future<List<Habit>> getHabits(String userId) async {
    if (!await isOnline()) {
      return [];
    }

    try {
      final response = await client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map((data) => Habit.fromMap(data['id'], _convertKeys(data)))
          .toList();
    } catch (e, stk) {
      Log.e('supabase', 'getHabits failed', error: e, stack: stk);
      return [];
    }
  }

  /// نسخهٔ «سخت‌گیر»: روی خطا throw می‌کند تا همگام‌سازی نتواند «خطا» را با «لیست خالی» اشتباه بگیرد.
  Future<List<Habit>> getHabitsStrict(String userId) async {
    final response = await client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response
        .map((data) => Habit.fromMap(data['id'], _convertKeys(data)))
        .toList();
  }

  Future<List<Task>> getTasksStrict(String userId) async {
    final response = await client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response
        .map((data) => Task.fromMap(data['id'], _convertKeys(data)))
        .toList();
  }

  Future<void> createHabit(Habit habit) async {
    final data = habit.toMap();
    data.remove('id');
    // شناسهٔ UUID ساخته‌شده در برنامه (برای کار آفلاین) حفظ می‌شود
    if (SupabaseService._uuidRe.hasMatch(habit.id)) data['id'] = habit.id;
    await client.from('habits').upsert(data);
  }

  Future<void> updateHabit(Habit habit) async {
    final data = habit.toMap();
    data.remove('id');
    await client.from('habits').update(data).eq('id', habit.id);
  }

  Future<void> deleteHabit(String habitId) async {
    await client.from('habits').delete().eq('id', habitId);
  }

  // ==================== Tasks ====================

  Future<List<Task>> getTasks(String userId) async {
    if (!await isOnline()) {
      return [];
    }

    try {
      final response = await client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map((data) => Task.fromMap(data['id'], _convertKeys(data)))
          .toList();
    } catch (e, stk) {
      Log.e('supabase', 'getTasks failed', error: e, stack: stk);
      return [];
    }
  }

  Future<void> createTask(Task task) async {
    final data = task.toMap();
    data.remove('id');
    if (SupabaseService._uuidRe.hasMatch(task.id)) data['id'] = task.id;
    await client.from('tasks').upsert(data);
  }

  Future<void> updateTask(Task task) async {
    final data = task.toMap();
    data.remove('id');
    await client.from('tasks').update(data).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await client.from('tasks').delete().eq('id', taskId);
  }

  // ==================== Habit Completions ====================

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// همهٔ عادت‌های تکمیل‌شدهٔ یک روز در «یک» درخواست (به‌جای یک درخواست برای هر عادت).
  /// در خطا null برمی‌گرداند تا صدا زننده بداند داده معتبر نیست.
  Future<Set<String>?> getCompletedHabitIdsOnDate(
      String userId, DateTime date) async {
    try {
      final rows = await client
          .from('habit_completions')
          .select('habit_id')
          .eq('user_id', userId)
          .eq('date', _getDateString(date));
      return rows.map<String>((r) => r['habit_id'].toString()).toSet();
    } catch (err, stk) {
      Log.w('supabase', 'getCompletedHabitIdsOnDate ignored error', error: err, stack: stk);
      return null;
    }
  }

  /// زمان ثبت‌شدهٔ همهٔ عادت‌ها در یک روز (habitId -> ثانیه) در یک درخواست
  Future<Map<String, int>> getHabitTimesOnDate(
      String userId, DateTime date) async {
    try {
      final rows = await client
          .from('habit_time_tracking')
          .select('habit_id,total_seconds')
          .eq('user_id', userId)
          .eq('date', date.toIso8601String().split('T').first);
      final out = <String, int>{};
      for (final r in rows) {
        final sec = r['total_seconds'];
        if (sec is int && sec > 0) out[r['habit_id'].toString()] = sec;
      }
      return out;
    } catch (err, stk) {
      Log.w('supabase', 'getHabitTimesOnDate ignored error', error: err, stack: stk);
      return {};
    }
  }

  Future<bool> isHabitCompletedOnDate(
    String habitId,
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = _getDateString(date);
      final response = await client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .eq('date', dateStr);

      return response.isNotEmpty;
    } catch (e, stk) {
      Log.e('supabase', 'isHabitCompletedOnDate failed', error: e, stack: stk);
      return false;
    }
  }

  Future<void> markHabitCompletedOnDate(
    String habitId,
    String userId,
    DateTime date,
    bool completed,
  ) async {
    try {
      final dateStr = _getDateString(date);

      if (completed) {
        final existing = await client
            .from('habit_completions')
            .select()
            .eq('habit_id', habitId)
            .eq('user_id', userId)
            .eq('date', dateStr);

        if (existing.isEmpty) {
          await client.from('habit_completions').insert({
            'habit_id': habitId,
            'user_id': userId,
            'date': dateStr,
          });

          if (await isOnline()) {
            await _updateChallengeProgressForHabit(userId, habitId);
          }
        }
      } else {
        await client
            .from('habit_completions')
            .delete()
            .eq('habit_id', habitId)
            .eq('user_id', userId)
            .eq('date', dateStr);

        if (await isOnline()) {
          await _updateChallengeProgressForHabit(userId, habitId);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
