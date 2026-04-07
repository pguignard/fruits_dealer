import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/engine/rounding_rules.dart';

void main() {
  group('MultiplesOfTenRule', () {
    const rule = MultiplesOfTenRule();

    group('roundQuantity', () {
      test('valeur inferieure au minimum retourne 10', () {
        expect(rule.roundQuantity(0), equals(10));
        expect(rule.roundQuantity(3.0), equals(10));
        expect(rule.roundQuantity(4.9), equals(10));
      });

      test('arrondit au multiple de 10 le plus proche vers le bas', () {
        expect(rule.roundQuantity(12.0), equals(10));
        expect(rule.roundQuantity(14.9), equals(10));
      });

      test('arrondit au multiple de 10 le plus proche vers le haut', () {
        expect(rule.roundQuantity(15.0), equals(20));
        expect(rule.roundQuantity(17.0), equals(20));
        expect(rule.roundQuantity(25.0), equals(30));
      });

      test('valeur exactement multiple de 10', () {
        expect(rule.roundQuantity(10.0), equals(10));
        expect(rule.roundQuantity(50.0), equals(50));
        expect(rule.roundQuantity(100.0), equals(100));
      });
    });

    group('roundPrice', () {
      test('valeur inferieure au minimum retourne 10', () {
        expect(rule.roundPrice(0), equals(10));
        expect(rule.roundPrice(4.0), equals(10));
      });

      test('arrondit au multiple de 10 le plus proche', () {
        expect(rule.roundPrice(23.0), equals(20));
        expect(rule.roundPrice(26.0), equals(30));
        expect(rule.roundPrice(55.0), equals(60));
      });

      test('valeur exactement multiple de 10', () {
        expect(rule.roundPrice(80.0), equals(80));
      });
    });
  });

  group('MultiplesOfFiveRule', () {
    const rule = MultiplesOfFiveRule();

    group('roundQuantity', () {
      test('valeur inferieure au minimum retourne 5', () {
        expect(rule.roundQuantity(0), equals(5));
        expect(rule.roundQuantity(2.0), equals(5));
        expect(rule.roundQuantity(2.4), equals(5));
      });

      test('arrondit au multiple de 5 le plus proche vers le bas', () {
        expect(rule.roundQuantity(7.0), equals(5));
        expect(rule.roundQuantity(12.0), equals(10));
      });

      test('arrondit au multiple de 5 le plus proche vers le haut', () {
        expect(rule.roundQuantity(8.0), equals(10));
        expect(rule.roundQuantity(13.0), equals(15));
      });

      test('valeur exactement multiple de 5', () {
        expect(rule.roundQuantity(5.0), equals(5));
        expect(rule.roundQuantity(25.0), equals(25));
      });
    });

    group('roundPrice', () {
      test('valeur inferieure au minimum retourne 5', () {
        expect(rule.roundPrice(1.0), equals(5));
      });

      test('arrondit au multiple de 5 le plus proche', () {
        expect(rule.roundPrice(17.0), equals(15));
        expect(rule.roundPrice(18.0), equals(20));
        expect(rule.roundPrice(22.5), equals(25));
      });
    });
  });

  group('IntegersUpToTwentyRule', () {
    const rule = IntegersUpToTwentyRule();

    group('roundQuantity', () {
      test('valeur inferieure ou egale a zero retourne 1', () {
        expect(rule.roundQuantity(0), equals(1));
        expect(rule.roundQuantity(0.4), equals(1));
      });

      test('arrondit a l\'entier le plus proche', () {
        expect(rule.roundQuantity(3.4), equals(3));
        expect(rule.roundQuantity(3.5), equals(4));
        expect(rule.roundQuantity(7.9), equals(8));
      });

      test('valeur dans la plage [1, 20] retourne l\'entier arrondi', () {
        expect(rule.roundQuantity(10.0), equals(10));
        expect(rule.roundQuantity(19.6), equals(20));
      });

      test('valeur superieure a 20 est plafonnee a 20', () {
        expect(rule.roundQuantity(21.0), equals(20));
        expect(rule.roundQuantity(100.0), equals(20));
      });
    });

    group('roundPrice', () {
      test('plafonnee a 20', () {
        expect(rule.roundPrice(50.0), equals(20));
      });

      test('minimum 1', () {
        expect(rule.roundPrice(0.3), equals(1));
      });

      test('arrondit correctement dans la plage', () {
        expect(rule.roundPrice(12.5), equals(13));
        expect(rule.roundPrice(15.0), equals(15));
      });
    });
  });

  group('FreeIntegersRule', () {
    const rule = FreeIntegersRule();

    group('roundQuantity', () {
      test('valeur inferieure ou egale a zero retourne 1', () {
        expect(rule.roundQuantity(0), equals(1));
        expect(rule.roundQuantity(0.4), equals(1));
      });

      test('arrondit a l\'entier le plus proche sans plafond', () {
        expect(rule.roundQuantity(3.4), equals(3));
        expect(rule.roundQuantity(3.5), equals(4));
        expect(rule.roundQuantity(50.0), equals(50));
        expect(rule.roundQuantity(999.7), equals(1000));
      });
    });

    group('roundPrice', () {
      test('minimum 1', () {
        expect(rule.roundPrice(0.2), equals(1));
      });

      test('arrondit a l\'entier le plus proche sans plafond', () {
        expect(rule.roundPrice(7.4), equals(7));
        expect(rule.roundPrice(7.5), equals(8));
        expect(rule.roundPrice(200.0), equals(200));
      });
    });
  });

  group('RoundingRule.fromId', () {
    test('retourne MultiplesOfTenRule pour "multiples_of_10"', () {
      expect(RoundingRule.fromId('multiples_of_10'), isA<MultiplesOfTenRule>());
    });

    test('retourne MultiplesOfFiveRule pour "multiples_of_5"', () {
      expect(RoundingRule.fromId('multiples_of_5'), isA<MultiplesOfFiveRule>());
    });

    test('retourne IntegersUpToTwentyRule pour "integers_up_to_20"', () {
      expect(
        RoundingRule.fromId('integers_up_to_20'),
        isA<IntegersUpToTwentyRule>(),
      );
    });

    test('retourne FreeIntegersRule pour "free_integers"', () {
      expect(RoundingRule.fromId('free_integers'), isA<FreeIntegersRule>());
    });

    test('lance ArgumentError pour un id inconnu', () {
      expect(
        () => RoundingRule.fromId('invalid_rule'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
