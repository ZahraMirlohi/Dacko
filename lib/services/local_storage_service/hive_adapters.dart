// ignore_for_file: invalid_use_of_protected_member
// بخشی از local_storage_service.dart (بدون تغییر رفتار): HabitAdapter, TaskAdapter, ReminderAdapter, QuestAdapter, PackageAdapter, PackageHabitAdapter
part of '../local_storage_service.dart';


// ==================== Hive Adapters ====================

// lib/services/local_storage_service.dart

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    DateTime parseDate(String dateStr) {
      try {
        if (dateStr.isEmpty) return DateTime.now();
        return DateTime.parse(dateStr);
      } catch (e, stk) {
        Log.e('local_storage', 'read failed', error: e, stack: stk);
        return DateTime.now();
      }
    }

    // ترتیب خواندن باید دقیقاً مثل write باشد (timer_setting آخر نوشته می‌شود)
    String? optStr() {
      final v = reader.readString();
      return v.isEmpty ? null : v;
    }

    final id = reader.readString();
    final userId = reader.readString();
    final title = reader.readString();
    final description = reader.readString();
    final subHabits = reader.readList().cast<String>();
    final completedSubHabits = reader.readList().cast<String>();
    final iconName = reader.readString();
    final iconColor = reader.readInt();
    final backgroundColor = reader.readInt();
    final frequencyType = reader.readString();
    final dailyIntervalDays = reader.readList().cast<int>();
    final weeklyDays = reader.readList().cast<int>();
    final weeklyIntervalWeeks = reader.readInt();
    final monthlyDays = reader.readList().cast<int>();
    final monthlyIntervalMonths = reader.readInt();
    final timeOfDay = reader.readString();
    final reminders = reader.readList().cast<Reminder>();
    final xpReward = reader.readInt();
    final currentStreak = reader.readInt();
    final bestStreak = reader.readInt();
    final isActive = reader.readBool();
    final createdAt = parseDate(reader.readString());
    final updatedAt = parseDate(reader.readString());
    final groupId = optStr();
    final startStr = optStr();
    final endStr = optStr();
    final challengeId = optStr();
    final questId = optStr();
    final targetValue = optStr();
    final fullDescription = optStr();
    final halfDescription = optStr();
    final basicDescription = optStr();

    TimerSetting? timerSetting;
    try {
      final timerSettingMap = reader.readMap();
      if (timerSettingMap.isNotEmpty) {
        final Map<String, dynamic> convertedMap = {};
        timerSettingMap.forEach((key, value) {
          convertedMap[key.toString()] = value;
        });
        timerSetting = TimerSetting.fromMap(convertedMap);
      }
    } catch (e, stk) {
      Log.e('local_storage', 'Error reading timer_setting: $e', error: e, stack: stk);
    }

    return Habit(
      id: id,
      userId: userId,
      title: title,
      description: description,
      subHabits: subHabits,
      completedSubHabits: completedSubHabits,
      iconName: iconName,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      frequencyType: frequencyType,
      dailyIntervalDays: dailyIntervalDays,
      weeklyDays: weeklyDays,
      weeklyIntervalWeeks: weeklyIntervalWeeks,
      monthlyDays: monthlyDays,
      monthlyIntervalMonths: monthlyIntervalMonths,
      timeOfDay: timeOfDay,
      reminders: reminders,
      xpReward: xpReward,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      groupId: groupId,
      startDate: startStr == null ? null : parseDate(startStr),
      endDate: endStr == null ? null : parseDate(endStr),
      challengeId: challengeId,
      questId: questId,
      timerSetting: timerSetting,
      targetValue: targetValue,
      fullDescription: fullDescription,
      halfDescription: halfDescription,
      basicDescription: basicDescription,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeList(obj.subHabits);
    writer.writeList(obj.completedSubHabits);
    writer.writeString(obj.iconName);
    writer.writeInt(obj.iconColor);
    writer.writeInt(obj.backgroundColor);
    writer.writeString(obj.frequencyType);
    writer.writeList(obj.dailyIntervalDays ?? []);
    writer.writeList(obj.weeklyDays ?? []);
    writer.writeInt(obj.weeklyIntervalWeeks ?? 1);
    writer.writeList(obj.monthlyDays ?? []);
    writer.writeInt(obj.monthlyIntervalMonths ?? 1);
    writer.writeString(obj.timeOfDay);
    writer.writeList(obj.reminders);
    writer.writeInt(obj.xpReward);
    writer.writeInt(obj.currentStreak);
    writer.writeInt(obj.bestStreak);
    writer.writeBool(obj.isActive);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeString(obj.groupId ?? '');
    writer.writeString(obj.startDate?.toIso8601String() ?? '');
    writer.writeString(obj.endDate?.toIso8601String() ?? '');
    writer.writeString(obj.challengeId ?? '');
    writer.writeString(obj.questId ?? '');
    writer.writeString(obj.targetValue ?? '');
    writer.writeString(obj.fullDescription ?? '');
    writer.writeString(obj.halfDescription ?? '');
    writer.writeString(obj.basicDescription ?? '');

    // نوشتن timer_setting
    if (obj.timerSetting != null) {
      writer.writeMap(obj.timerSetting!.toMap());
    } else {
      writer.writeMap({});
    }
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      userId: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      subTasks: reader.readList().cast<String>(),
      completedSubTasks: reader.readList().cast<String>(),
      dueDate: _readOptDate(reader),
      isCompleted: reader.readBool(),
      xpReward: reader.readInt(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeList(obj.subTasks);
    writer.writeList(obj.completedSubTasks);
    writer.writeString(obj.dueDate?.toIso8601String() ?? '');
    writer.writeBool(obj.isCompleted);
    writer.writeInt(obj.xpReward);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 2;

  @override
  Reminder read(BinaryReader reader) {
    return Reminder(
      id: reader.readString(),
      hour: reader.readInt(),
      minute: reader.readInt(),
      isEnabled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.hour);
    writer.writeInt(obj.minute);
    writer.writeBool(obj.isEnabled);
  }
}

class QuestAdapter extends TypeAdapter<Quest> {
  @override
  final int typeId = 3;

  @override
  Quest read(BinaryReader reader) {
    return Quest(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      icon: reader.readString(),
      color: reader.readString(),
      xpReward: reader.readInt(),
      badge: reader.readString(),
      targetCount: reader.readInt(),
      isActive: reader.readBool(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Quest obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.icon);
    writer.writeString(obj.color);
    writer.writeInt(obj.xpReward);
    writer.writeString(obj.badge);
    writer.writeInt(obj.targetCount);
    writer.writeBool(obj.isActive);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}

class PackageAdapter extends TypeAdapter<Package> {
  @override
  final int typeId = 4;

  @override
  Package read(BinaryReader reader) {
    return Package(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      icon: reader.readString(),
      color: reader.readString(),
      backgroundColor: reader.readString(),
      category: reader.readString(),
      habits: reader.readList().cast<PackageHabit>(),
      isActive: reader.readBool(),
      xpReward: reader.readInt(),
      badge: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Package obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.icon);
    writer.writeString(obj.color);
    writer.writeString(obj.backgroundColor);
    writer.writeString(obj.category);
    writer.writeList(obj.habits);
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.xpReward);
    writer.writeString(obj.badge);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}

class PackageHabitAdapter extends TypeAdapter<PackageHabit> {
  @override
  final int typeId = 5;

  @override
  PackageHabit read(BinaryReader reader) {
    return PackageHabit(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      iconName: reader.readString(),
      iconColor: reader.readInt(),
      backgroundColor: reader.readInt(),
      frequencyType: reader.readString(),
      weeklyDays: reader.readList().cast<int>(),
      monthlyDays: reader.readList().cast<int>(),
      dailyIntervalDays: reader.readInt(),
      timeOfDay: reader.readString(),
      xpReward: reader.readInt(),
      subHabits: reader.readList().cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PackageHabit obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.iconName);
    writer.writeInt(obj.iconColor);
    writer.writeInt(obj.backgroundColor);
    writer.writeString(obj.frequencyType);
    writer.writeList(obj.weeklyDays ?? []);
    writer.writeList(obj.monthlyDays ?? []);
    writer.writeInt(obj.dailyIntervalDays ?? 1);
    writer.writeString(obj.timeOfDay);
    writer.writeInt(obj.xpReward);
    writer.writeList(obj.subHabits);
  }
}

class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = 6;

  @override
  OfflineOperation read(BinaryReader reader) {
    return OfflineOperation(
      id: reader.readString(),
      type: OperationType.values[reader.readInt()],
      data: reader.readMap().cast<String, dynamic>(),
      timestamp: DateTime.parse(reader.readString()),
      userId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.type.index);
    writer.writeMap(obj.data);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.userId);
  }
}

DateTime? _readOptDate(BinaryReader reader) {
  final v = reader.readString();
  return v.isEmpty ? null : DateTime.tryParse(v);
}