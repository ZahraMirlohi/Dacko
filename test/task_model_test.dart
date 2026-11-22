import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/features/arena/models/task_model.dart';

Task _task({DateTime? due, List<String>? subs, List<String>? done}) => Task(
      id: 't1',
      userId: 'u1',
      title: 'Test',
      dueDate: due,
      subTasks: subs ?? const [],
      completedSubTasks: done ?? const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Task', () {
    test('isForDate فقط تاریخ را مقایسه می‌کند، نه ساعت', () {
      final t = _task(due: DateTime(2026, 5, 10, 23, 59));
      expect(t.isForDate(DateTime(2026, 5, 10, 0, 1)), isTrue);
      expect(t.isForDate(DateTime(2026, 5, 11)), isFalse);
      expect(t.isForDate(DateTime(2025, 5, 10)), isFalse);
    });

    test('بدون dueDate برای هیچ روزی نیست', () {
      expect(_task().isForDate(DateTime.now()), isFalse);
      expect(_task().isForToday(), isFalse);
    });

    test('isForToday برای امروز درست است', () {
      expect(_task(due: DateTime.now()).isForToday(), isTrue);
    });

    test('progressPercent و completedCount', () {
      expect(_task().progressPercent, 0);
      final t = _task(subs: ['a', 'b', 'c', 'd'], done: ['a']);
      expect(t.completedCount, 1);
      expect(t.progressPercent, 0.25);
    });

    test('toMap کلیدهای دیتابیس را دارد', () {
      final m = _task(due: DateTime(2026, 5, 10)).toMap();
      expect(m['user_id'], 'u1');
      expect(m['title'], 'Test');
      expect(m['xp_reward'], 10);
      expect(m['is_completed'], false);
      expect(m['due_date'], isNotNull);
    });

    test('fromMap مقادیر را می‌خواند و پیش‌فرض می‌گذارد', () {
      final t = Task.fromMap('id9', {
        'userId': 'u2',
        'title': 'T',
        'subTasks': ['a'],
        'dueDate': '2026-01-02T00:00:00.000',
      });
      expect(t.id, 'id9');
      expect(t.userId, 'u2');
      expect(t.subTasks, ['a']);
      expect(t.dueDate!.year, 2026);
      expect(t.xpReward, 10);
      expect(t.isCompleted, isFalse);
    });

    test('تاریخ خراب باعث کرش نمی‌شود و به الان برمی‌گردد', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final t = Task.fromMap('x', {'createdAt': 'not-a-date'});
      expect(t.createdAt.isAfter(before), isTrue);
    });
  });
}
