import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/models/offline_operation.dart';

void main() {
  group('OfflineOperation', () {
    test('toMap/fromMap برای همهٔ نوع‌ها بدون تغییر برمی‌گردد', () {
      final ts = DateTime(2026, 1, 2, 3, 4, 5);
      for (final type in OperationType.values) {
        final op = OfflineOperation(
          id: 'id-${type.name}',
          type: type,
          data: {'a': 1, 'nested': {'b': 'x'}},
          timestamp: ts,
          userId: 'u1',
        );
        final back = OfflineOperation.fromMap(op.toMap());
        expect(back.id, op.id);
        expect(back.type, type);
        expect(back.data['a'], 1);
        expect(back.data['nested'], {'b': 'x'});
        expect(back.timestamp, ts);
        expect(back.userId, 'u1');
      }
    });

    test('نوع عملیات با index ذخیره می‌شود (ترتیب enum نباید عوض شود)', () {
      final op = OfflineOperation(
          id: '1',
          type: OperationType.createHabit,
          data: const {},
          timestamp: DateTime(2026),
          userId: 'u');
      expect(op.toMap()['type'], 0);
      expect(OperationType.values.first, OperationType.createHabit);
    });

    test('toString شامل id و userId است', () {
      final op = OfflineOperation(
          id: 'abc',
          type: OperationType.deleteTask,
          data: const {},
          timestamp: DateTime(2026),
          userId: 'user9');
      expect(op.toString(), allOf(contains('abc'), contains('user9')));
    });
  });
}
