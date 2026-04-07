import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/entities/fruit.dart';

void main() {
  group('Fruit', () {
    const apple = Fruit(id: 'apple', displayName: 'Pomme', price: 2);
    const orange = Fruit(id: 'orange', displayName: 'Orange', price: 5);

    group('égalité', () {
      test('deux instances avec le même id sont égales', () {
        const same = Fruit(id: 'apple', displayName: 'Autre nom', price: 99);
        expect(apple, equals(same));
      });

      test('deux instances avec des ids différents ne sont pas égales', () {
        expect(apple, isNot(equals(orange)));
      });

      test('hashCode identique pour même id', () {
        const same = Fruit(id: 'apple', displayName: 'X', price: 1);
        expect(apple.hashCode, equals(same.hashCode));
      });
    });

    group('copyWith', () {
      test('sans argument retourne un fruit avec les mêmes valeurs', () {
        final copy = apple.copyWith();
        expect(copy.id, equals(apple.id));
        expect(copy.displayName, equals(apple.displayName));
        expect(copy.price, equals(apple.price));
      });

      test('met à jour uniquement le price', () {
        final updated = apple.copyWith(price: 10);
        expect(updated.id, equals('apple'));
        expect(updated.displayName, equals('Pomme'));
        expect(updated.price, equals(10));
      });

      test('met à jour uniquement le displayName', () {
        final updated = apple.copyWith(displayName: 'Apple');
        expect(updated.displayName, equals('Apple'));
        expect(updated.price, equals(apple.price));
      });

      test('met à jour tous les champs', () {
        final updated = apple.copyWith(
          id: 'banana',
          displayName: 'Banane',
          price: 3,
        );
        expect(updated.id, equals('banana'));
        expect(updated.displayName, equals('Banane'));
        expect(updated.price, equals(3));
      });

      test("copyWith ne modifie pas l'original", () {
        apple.copyWith(price: 999);
        expect(apple.price, equals(2));
      });
    });
  });
}
