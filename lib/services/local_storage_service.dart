// lib/services/local_storage_service.dart

import '/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/arena/models/habit_model.dart';
import '../features/arena/models/task_model.dart';
import '../features/explore/models/quest_model.dart';
import '../features/explore/models/package_model.dart';
import '../features/explore/models/package_habit_model.dart';
import 'package:path_provider/path_provider.dart';
import '../models/offline_operation.dart';
import '../features/arena/models/timer_setting.dart';

part 'local_storage_service/hive_adapters.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _habitsBoxName = 'habits';
  static const String _tasksBoxName = 'tasks';
  static const String _questsBoxName = 'quests';
  static const String _packagesBoxName = 'packages';
  static const String _settingsBoxName = 'settings';
  static const String _userProfileBoxName = 'user_profile';
  static const String _offlineBoxName = 'offline_operations';
  static const String _challengesBoxName = 'challenges';
  static const String _userChallengesBoxName = 'user_challenges';

  late Box _habitsBox;
  late Box _tasksBox;
  late Box _questsBox;
  late Box _packagesBox;
  late Box _settingsBox;
  late Box _userProfileBox;
  late Box _offlineBox;
  late Box _challengesBox;
  late Box _userChallengesBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // ثبت Adapterها
      try {
        Hive.registerAdapter(HabitAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(TaskAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(QuestAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(PackageAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(PackageHabitAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(ReminderAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }
      try {
        Hive.registerAdapter(OfflineOperationAdapter());
      } catch (e, stk) { Log.e('local_storage', 'init failed', error: e, stack: stk); }

      // متد کمکی برای باز کردن Box با مدیریت خطا
      _habitsBox = await _openBoxWithFallback(_habitsBoxName);
      _tasksBox = await _openBoxWithFallback(_tasksBoxName);
      _questsBox = await _openBoxWithFallback(_questsBoxName);
      _packagesBox = await _openBoxWithFallback(_packagesBoxName);
      _settingsBox = await _openBoxWithFallback(_settingsBoxName);
      _userProfileBox = await _openBoxWithFallback(_userProfileBoxName);
      _offlineBox = await _openBoxWithFallback(_offlineBoxName);
      _challengesBox = await _openBoxWithFallback(_challengesBoxName);
      _userChallengesBox = await _openBoxWithFallback(_userChallengesBoxName);

      await _runMigrations();

      _isInitialized = true;
      print('LocalStorageService initialized successfully');
      print('   - Offline operations: ${_offlineBox.length}');
    } catch (e) {
      print('LocalStorageService init error: $e');
      _isInitialized = true;
      rethrow;
    }
  }

  Future<Box> _openBoxWithFallback(String boxName) async {
    try {
      return await Hive.openBox(boxName);
    } catch (e) {
      if (boxName == _offlineBoxName) {
        // صف آفلاین کار ذخیره‌نشدهٔ کاربر است؛ یک بار دیگر بدون حذف تلاش می‌کنیم
        try {
          return await Hive.openBox(boxName, crashRecovery: true);
        } catch (err, stk) { Log.w('local_storage', '_openBoxWithFallback ignored error', error: err, stack: stk); }
      }
      print(
        'Error opening $boxName box, attempting to delete and recreate...',
      );
      try {
        // بررسی وجود فایل قبل از حذف
        final path = await _getBoxPath(boxName);
        if (path != null) {
          try {
            await Hive.deleteBoxFromDisk(boxName);
            print('Deleted $boxName box successfully');
          } catch (deleteError, stk) {
            // اگر فایل وجود نداشت، خطا رو نادیده بگیر
            Log.e('local_storage', 'Could not delete $boxName (may not exist): $deleteError', error: deleteError, stack: stk);
          }
        }
      } catch (e, stk) {
        Log.e('local_storage', 'Error checking/deleting $boxName: $e', error: e, stack: stk);
      }
      return await Hive.openBox(boxName);
    }
  }

  Future<String?> _getBoxPath(String boxName) async {
    try {
      // در اندروید و iOS
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$boxName.lock';
      return path;
    } catch (e, stk) {
      Log.e('local_storage', '_getBoxPath failed', error: e, stack: stk);
      return null;
    }
  }

  bool get isInitialized => _isInitialized;

  // lib/services/local_storage_service.dart

  // متد کمکی برای تبدیل ایمن تاریخ
  DateTime? _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e, stk) {
      Log.e('local_storage', '_safeParseDate failed', error: e, stack: stk);
      print('Error parsing date: $dateStr');
      return null;
    }
  }

  // متد کمکی برای تبدیل ایمن تاریخ با مقدار پیش‌فرض
  DateTime _safeParseDateWithDefault(String? dateStr, DateTime defaultValue) {
    if (dateStr == null || dateStr.isEmpty) return defaultValue;
    try {
      return DateTime.parse(dateStr);
    } catch (e, stk) {
      Log.e('local_storage', '_safeParseDateWithDefault failed', error: e, stack: stk);
      print('Error parsing date: $dateStr, using default');
      return defaultValue;
    }
  }

  // ==================== Habit Operations ====================

  Future<void> saveHabits(List<Habit> habits) async {
    try {
      await _habitsBox.put('user_habits', habits);
      NotificationService.instance.refreshSoon(); // یادآورها با تغییر عادت‌ها هماهنگ شوند
    } catch (e) {
      print('Error saving habits: $e');
      rethrow;
    }
  }

  List<Habit> getHabits() {
    try {
      if (!_isInitialized) return [];
      final data = _habitsBox.get('user_habits');
      if (data == null) return [];
      return (data as List).cast<Habit>();
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting habits: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<void> saveHabit(Habit habit) async {
    try {
      final habits = getHabits();
      final index = habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        habits[index] = habit;
      } else {
        habits.add(habit);
      }
      await saveHabits(habits);
    } catch (e) {
      print('Error saving habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final habits = getHabits();
      habits.removeWhere((h) => h.id == habitId);
      await saveHabits(habits);
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }

  // ==================== Task Operations ====================

  Future<void> saveTasks(List<Task> tasks) async {
    try {
      await _tasksBox.put('user_tasks', tasks);
    } catch (e) {
      print('Error saving tasks: $e');
      rethrow;
    }
  }

  List<Task> getTasks() {
    try {
      if (!_isInitialized) return [];
      final data = _tasksBox.get('user_tasks');
      if (data == null) return [];
      return (data as List).cast<Task>();
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting tasks: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<void> saveTask(Task task) async {
    try {
      final tasks = getTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
      await saveTasks(tasks);
    } catch (e) {
      print('Error saving task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final tasks = getTasks();
      tasks.removeWhere((t) => t.id == taskId);
      await saveTasks(tasks);
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // ==================== Quest Operations ====================

  Future<void> saveQuests(List<Quest> quests) async {
    try {
      await _questsBox.put('available_quests', quests);
    } catch (e) {
      print('Error saving quests: $e');
      rethrow;
    }
  }

  List<Quest> getQuests() {
    try {
      if (!_isInitialized) return [];
      final data = _questsBox.get('available_quests');
      if (data == null) return [];
      return (data as List).cast<Quest>();
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting quests: $e', error: e, stack: stk);
      return [];
    }
  }

  // ==================== Package Operations ====================

  Future<void> savePackages(List<Package> packages) async {
    try {
      await _packagesBox.put('available_packages', packages);
    } catch (e) {
      print('Error saving packages: $e');
      rethrow;
    }
  }

  List<Package> getPackages() {
    try {
      if (!_isInitialized) return [];
      final data = _packagesBox.get('available_packages');
      if (data == null) return [];
      return (data as List).cast<Package>();
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting packages: $e', error: e, stack: stk);
      return [];
    }
  }

  // ==================== Profile Operations ====================

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      await _userProfileBox.put('profile', profile);
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? getUserProfile() {
    try {
      if (!_isInitialized) return null;
      return _userProfileBox.get('profile');
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting profile: $e', error: e, stack: stk);
      return null;
    }
  }

  Future<void> deleteUserProfile() async {
    try {
      await _userProfileBox.delete('profile');
    } catch (e) {
      print('Error deleting profile: $e');
      rethrow;
    }
  }

  // ==================== Challenges Operations ====================

  Future<void> saveChallenges(List<Map<String, dynamic>> challenges) async {
    try {
      await _challengesBox.put('challenges', challenges);
    } catch (e) {
      print('Error saving challenges: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> getChallenges() {
    try {
      if (!_isInitialized) return [];
      final data = _challengesBox.get('challenges');
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting challenges: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<void> saveUserChallenges(
    List<Map<String, dynamic>> userChallenges,
  ) async {
    try {
      await _userChallengesBox.put('user_challenges', userChallenges);
    } catch (e) {
      print('Error saving user challenges: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> getUserChallenges() {
    try {
      if (!_isInitialized) return [];
      final data = _userChallengesBox.get('user_challenges');
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting user challenges: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<void> updateChallengeStatus(String challengeId, bool isJoined) async {
    try {
      final challenges = getChallenges();
      final index = challenges.indexWhere((c) => c['id'] == challengeId);
      if (index != -1) {
        challenges[index]['isJoined'] = isJoined;
        await saveChallenges(challenges);
      }
    } catch (e) {
      print('Error updating challenge status: $e');
      rethrow;
    }
  }

  // ==================== Offline Operations ====================

  Future<void> addOfflineOperation(OfflineOperation operation) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await _offlineBox.add(operation.toMap());
      print('Offline operation added: ${operation.type} (${operation.id})');
      print('   - Total operations: ${_offlineBox.length}');
    } catch (e) {
      print('Error adding offline operation: $e');
      rethrow;
    }
  }

  List<OfflineOperation> getOfflineOperations() {
    try {
      if (!_isInitialized) return [];
      final List<OfflineOperation> operations = [];
      for (var key in _offlineBox.keys) {
        final data = _offlineBox.get(key);
        if (data != null) {
          try {
            operations.add(OfflineOperation.fromMap(data));
          } catch (e, stk) {
            Log.e('local_storage', 'Error parsing offline operation: $e', error: e, stack: stk);
          }
        }
      }
      return operations;
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting offline operations: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<void> removeOfflineOperation(String id) async {
    try {
      for (var key in _offlineBox.keys) {
        final data = _offlineBox.get(key);
        if (data != null && data['id'] == id) {
          await _offlineBox.delete(key);
          print('Offline operation removed: $id');
          break;
        }
      }
    } catch (e) {
      print('Error removing offline operation: $e');
      rethrow;
    }
  }

  Future<void> clearOfflineOperations() async {
    try {
      await _offlineBox.clear();
      print('All offline operations cleared');
    } catch (e) {
      print('Error clearing offline operations: $e');
      rethrow;
    }
  }

  Future<void> removeOfflineOperationsByType(OperationType type) async {
    try {
      final List<dynamic> keysToRemove = [];
      for (var key in _offlineBox.keys) {
        final data = _offlineBox.get(key);
        if (data != null && data['type'] == type.index) {
          keysToRemove.add(key);
        }
      }
      for (var key in keysToRemove) {
        await _offlineBox.delete(key);
      }
      print('Removed ${keysToRemove.length} operations of type $type');
    } catch (e) {
      print('Error removing operations by type: $e');
      rethrow;
    }
  }

  int get offlineOperationsCount {
    try {
      if (!_isInitialized) return 0;
      return _offlineBox.length;
    } catch (e, stk) {
      Log.e('local_storage', 'removeOfflineOperationsByType failed', error: e, stack: stk);
      return 0;
    }
  }

  bool hasOfflineOperations() {
    return offlineOperationsCount > 0;
  }

  // ==================== Settings ====================

  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      print('Error saving setting: $e');
      rethrow;
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      if (!_isInitialized) return defaultValue;
      return _settingsBox.get(key, defaultValue: defaultValue);
    } catch (e, stk) {
      Log.e('local_storage', 'Error getting setting: $e', error: e, stack: stk);
      return defaultValue;
    }
  }

  Future<void> removeSetting(String key) async {
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      print('Error removing setting: $e');
      rethrow;
    }
  }

  // ==================== Utility ====================

  Future<void> clearAll() async {
    try {
      await _habitsBox.clear();
      await _tasksBox.clear();
      await _questsBox.clear();
      await _packagesBox.clear();
      await _settingsBox.clear();
      await _userProfileBox.clear();
      await _offlineBox.clear();
      await _challengesBox.clear();
      await _userChallengesBox.clear();
      print('All local data cleared');
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }


  // ═══════════════════════════════════════════════════════════
  // مهاجرت ساختار داده (Schema migrations)
  // ═══════════════════════════════════════════════════════════
  // هر بار ساختار ذخیره‌سازی عوض شد، currentSchemaVersion را +1 کنید و
  // یک case به _migrateStep اضافه کنید. نسخه در SharedPreferences ذخیره می‌شود
  // (نه در Hive) تا با پاک شدن جعبه‌ها از بین نرود.
  static const int currentSchemaVersion = 3;
  static const String _schemaVersionKey = 'hive_schema_version';

  Future<void> _runMigrations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var version = prefs.getInt(_schemaVersionKey) ?? 1;
      while (version < currentSchemaVersion) {
        await _migrateStep(version);
        version++;
        await prefs.setInt(_schemaVersionKey, version);
        debugPrint('Hive migrated to schema v$version');
      }
    } catch (e, stk) {
      // مهاجرت نباید جلوی بالا آمدن برنامه را بگیرد؛ داده‌ها از سرور دوباره همگام می‌شوند
      Log.e('local_storage', 'Hive migration error: $e', error: e, stack: stk);
    }
  }

  Future<void> _migrateStep(int from) async {
    switch (from) {
      case 1:
        // v1 v2: داده‌های کش‌شده (عادت، کار، ماموریت، بسته، چالش) را پاک می‌کنیم تا
        // با ساختار و کدگذاری جدید روزهای هفته از سرور تازه بیایند.
        // صف عملیات آفلاین و پروفایل دست نمی‌خورند تا کار ذخیره‌نشدهٔ کاربر گم نشود.
        await _habitsBox.clear();
        await _tasksBox.clear();
        await _questsBox.clear();
        await _packagesBox.clear();
        await _challengesBox.clear();
        await _userChallengesBox.clear();
        break;
      case 2:
        // v2 v3: روزهای هفته شنبه=۰ شد و داده‌های سرور با SQL اصلاح می‌شوند؛
        // کش دوباره از سرور پر شود (صف آفلاین دست‌نخورده می‌ماند).
        await _habitsBox.clear();
        break;
    }
  }

  /// پاک کردن کامل داده‌های کاربر (هنگام خروج یا حذف حساب)؛ پروفایل هم پاک می‌شود
  /// تا کاربر بعدی روی همین گوشی داده‌های قبلی را نبیند.
  Future<void> clearAllUserData() async {
    await _habitsBox.clear();
    await _tasksBox.clear();
    await _questsBox.clear();
    await _packagesBox.clear();
    await _settingsBox.clear();
    await _userProfileBox.clear();
    await _offlineBox.clear();
    await _challengesBox.clear();
    await _userChallengesBox.clear();
  }

  /// هنگام ورود با حساب دیگر: داده‌های کاربر قبلی (بدون تنظیمات ظاهری) پاک می‌شود
  Future<void> clearForUserSwitch() async {
    await _habitsBox.clear();
    await _tasksBox.clear();
    await _questsBox.clear();
    await _packagesBox.clear();
    await _userProfileBox.clear();
    await _offlineBox.clear();
    await _challengesBox.clear();
    await _userChallengesBox.clear();
  }

  Future<void> clearAllDataExceptProfile() async {
    try {
      final profile = getUserProfile();
      await _habitsBox.clear();
      await _tasksBox.clear();
      await _questsBox.clear();
      await _packagesBox.clear();
      await _settingsBox.clear();
      await _offlineBox.clear();
      await _challengesBox.clear();
      await _userChallengesBox.clear();
      if (profile != null) {
        await saveUserProfile(profile);
      }
      print('All data except profile cleared');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      await Hive.deleteBoxFromDisk(_habitsBoxName);
      await Hive.deleteBoxFromDisk(_tasksBoxName);
      await Hive.deleteBoxFromDisk(_questsBoxName);
      await Hive.deleteBoxFromDisk(_packagesBoxName);
      await Hive.deleteBoxFromDisk(_settingsBoxName);
      await Hive.deleteBoxFromDisk(_userProfileBoxName);
      await Hive.deleteBoxFromDisk(_offlineBoxName);
      await Hive.deleteBoxFromDisk(_challengesBoxName);
      await Hive.deleteBoxFromDisk(_userChallengesBoxName);
      print('Database reset successfully');
    } catch (e, stk) {
      Log.e('local_storage', 'Error resetting database: $e', error: e, stack: stk);
    }
  }

  // ==================== Debug ====================

  void printDebugInfo() {
    print('LocalStorage Debug Info:');
    print('   - Initialized: $_isInitialized');
    print('   - Habits: ${getHabits().length}');
    print('   - Tasks: ${getTasks().length}');
    print('   - Quests: ${getQuests().length}');
    print('   - Packages: ${getPackages().length}');
    print('   - Profile: ${getUserProfile() != null ? "Yes" : "No"}');
    print('   - Challenges: ${getChallenges().length}');
    print('   - User Challenges: ${getUserChallenges().length}');
    print('   - Offline Operations: $offlineOperationsCount');
  }
}
