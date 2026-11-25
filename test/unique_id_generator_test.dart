import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/utils/unique_id_generator.dart';

void main() {
  group('UniqueIdGenerator', () {
    test('generate / generateSecure / generateWithRandom فرمت معتبر دارند', () {
      for (final id in [
        UniqueIdGenerator.generate(),
        UniqueIdGenerator.generateSecure(),
        UniqueIdGenerator.generateWithRandom(),
      ]) {
        expect(id, startsWith('INNER-'));
        expect(id.length, 14);
        expect(UniqueIdGenerator.isValid(id), isTrue, reason: id);
      }
    });

    test('isValid موارد نامعتبر را رد می‌کند', () {
      expect(UniqueIdGenerator.isValid('INNER-ABCD1234'), isTrue);
      expect(UniqueIdGenerator.isValid('inner-12345678'), isFalse);
      expect(UniqueIdGenerator.isValid('INNER-1234'), isFalse);
      expect(UniqueIdGenerator.isValid('INNER-123456789'), isFalse);
      expect(UniqueIdGenerator.isValid(''), isFalse);
    });
  });
}
