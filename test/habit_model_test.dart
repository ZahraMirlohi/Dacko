import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/features/arena/models/habit_model.dart';

Habit _habit({
  bool isActive = true,
  String frequencyType = 'daily',
  List<int>? weeklyDays,
  List<int>? monthlyDays,
  DateTime? startDate,
  DateTime? endDate,
  String? challengeId,
  String? questId,
}) =>
    Habit(
      id: 'h1',
      userId: 'u1',
      title: 'Habit',
      isActive: isActive,
      frequencyType: frequencyType,
      weeklyDays: weeklyDays,
      monthlyDays: monthlyDays,
      startDate: startDate,
      endDate: endDate,
      challengeId: challengeId,
      questId: questId,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Habit.shouldDoOnDate', () {
    test('روزانه (پیش‌فرض) هر روز انجام می‌شود', () {
      final h = _habit();
      expect(h.shouldDoOnDate(DateTime(2026, 3, 3)), isTrue);
      expect(h.shouldDoOnDate(DateTime(2026, 3, 4)), isTrue);
    });

    test('عادت غیرفعال هیچ‌وقت نمایش داده نمی‌شود', () {
      expect(_habit(isActive: false).shouldDoOnDate(DateTime(2026, 3, 3)),
          isFalse);
    });

    test('قبل از startDate نیست، از خودِ startDate هست', () {
      final h = _habit(startDate: DateTime(2026, 6, 1));
      expect(h.shouldDoOnDate(DateTime(2026, 5, 31)), isFalse);
      expect(h.shouldDoOnDate(DateTime(2026, 6, 1)), isTrue);
    });

    test('چالش بعد از endDate نیست، در روز endDate هست', () {
      final h = _habit(challengeId: 'c1', endDate: DateTime(2026, 6, 10));
      expect(h.shouldDoOnDate(DateTime(2026, 6, 10)), isTrue);
      expect(h.shouldDoOnDate(DateTime(2026, 6, 11)), isFalse);
    });

    test('هفتگی: شنبه=۰ (۲۱ نوامبر ۲۰۲۶ شنبه است)', () {
      final h = _habit(frequencyType: 'weekly', weeklyDays: [0]);
      expect(h.shouldDoOnDate(DateTime(2026, 11, 21)), isTrue); // شنبه
      expect(h.shouldDoOnDate(DateTime(2026, 11, 22)), isFalse); // یکشنبه
    });

    test('هفتگی بدون روز انتخابی هرگز نیست', () {
      expect(
          _habit(frequencyType: 'weekly').shouldDoOnDate(DateTime(2026, 11, 21)),
          isFalse);
    });

    test('ماهانه بر اساس روز ماهِ شمسی (۲۰ مارس ۲۰۲۴ = اول فروردین ۱۴۰۳)', () {
      final h = _habit(frequencyType: 'monthly', monthlyDays: [1]);
      expect(h.shouldDoOnDate(DateTime(2024, 3, 20)), isTrue);
      expect(h.shouldDoOnDate(DateTime(2024, 3, 21)), isFalse);
    });

    test('ماموریت (questId) همیشه فعال است', () {
      final h = _habit(
          frequencyType: 'weekly', weeklyDays: [0], questId: 'q1');
      expect(h.shouldDoOnDate(DateTime(2026, 11, 22)), isTrue);
    });
  });

  group('Habit.isNotExpired', () {
    test('بدون endDate منقضی نمی‌شود', () {
      expect(_habit().isNotExpired(), isTrue);
    });

    test('endDate گذشته منقضی است، آینده نه', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 1));
      expect(_habit(endDate: past).isNotExpired(), isFalse);
      expect(_habit(endDate: future).isNotExpired(), isTrue);
    });

    test('ماموریت هیچ‌وقت منقضی نمی‌شود', () {
      final past = DateTime.now().subtract(const Duration(days: 30));
      expect(_habit(endDate: past, questId: 'q').isNotExpired(), isTrue);
    });
  });
}
