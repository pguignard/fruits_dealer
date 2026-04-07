import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/engine/offer_generator.dart';
import 'package:fruits_trader/domain/engine/rounding_rules.dart';
import 'package:fruits_trader/domain/entities/fruit.dart';
import 'package:fruits_trader/domain/entities/game_state.dart';
import 'package:fruits_trader/domain/entities/level_config.dart';

// ── Shared fixtures ─────────────────────────────────────────────

const _apple = Fruit(id: 'apple', displayName: 'Pomme', price: 10);
const _orange = Fruit(id: 'orange', displayName: 'Orange', price: 5);

final _level = LevelConfig(
  id: 'test',
  displayName: 'Test',
  difficulty: 1,
  fruits: const [_apple, _orange],
  initialCash: 500,
  initialStock: const {'apple': 50, 'orange': 50},
  objectiveCash: 1000,
  lossThresholdRatio: 0.5,
  offersPerSide: 4,
  buyTemplates: const [
    [80, 90, 95, 110],
  ],
  sellTemplates: const [
    [120, 105, 100, 85],
  ],
  roundingRule: 'free_integers',
);

GameState _state({
  int cash = 500,
  Map<String, int> stock = const {'apple': 50, 'orange': 50},
}) {
  return GameState(
    cash: cash,
    stock: stock,
    currentPrices: const {'apple': 10, 'orange': 5},
    turnCount: 0,
    elapsedMs: 0,
    currentBuyOffers: const [],
    currentSellOffers: const [],
  );
}

OfferGenerator _generator({int seed = 42, RoundingRule? rule}) {
  return OfferGenerator(
    roundingRule: rule ?? const FreeIntegersRule(),
    random: Random(seed),
  );
}

// ── Tests ───────────────────────────────────────────────────────

void main() {
  group('OfferGenerator — nominal', () {
    test('retourne le bon nombre d\'offres de chaque cote', () {
      final gen = _generator();
      final result = gen.generate(state: _state(), level: _level);
      expect(result.buys.length, equals(4));
      expect(result.sells.length, equals(4));
    });

    test('toutes les offres d\'achat respectent la contrainte de cash', () {
      final gen = _generator();
      final state = _state(cash: 100);
      final result = gen.generate(state: state, level: _level);
      for (final offer in result.buys) {
        expect(offer.totalPrice, lessThanOrEqualTo(100),
            reason: '$offer depasse le cash');
      }
    });

    test('toutes les offres de vente respectent la contrainte de stock', () {
      final gen = _generator();
      final state = _state(stock: {'apple': 8, 'orange': 3});
      final result = gen.generate(state: state, level: _level);
      for (final offer in result.sells) {
        final stock = state.stock[offer.fruitId] ?? 0;
        expect(offer.quantity, lessThanOrEqualTo(stock),
            reason: '${offer.fruitId}: qty ${offer.quantity} > stock $stock');
      }
    });

    test('avec la meme seed, deux appels produisent les memes offres', () {
      final gen1 = _generator(seed: 123);
      final gen2 = _generator(seed: 123);
      final state = _state();
      final r1 = gen1.generate(state: state, level: _level);
      final r2 = gen2.generate(state: state, level: _level);
      expect(r1.buys, equals(r2.buys));
      expect(r1.sells, equals(r2.sells));
    });

    test('les fruitId des offres appartiennent aux fruits du niveau', () {
      final gen = _generator();
      final result = gen.generate(state: _state(), level: _level);
      final validIds = _level.fruits.map((f) => f.id).toSet();
      for (final offer in [...result.buys, ...result.sells]) {
        expect(validIds.contains(offer.fruitId), isTrue,
            reason: '${offer.fruitId} absent du niveau');
      }
    });

    test('les quantites et prix sont strictement positifs', () {
      final gen = _generator();
      final result = gen.generate(state: _state(), level: _level);
      for (final offer in [...result.buys, ...result.sells]) {
        expect(offer.quantity, greaterThanOrEqualTo(1));
        expect(offer.totalPrice, greaterThanOrEqualTo(1));
      }
    });
  });

  group('OfferGenerator — qualite du gameplay', () {
    // Single fruit + high cash to avoid reduction, for clean ratio analysis
    final singleFruitLevel = LevelConfig(
      id: 'single',
      displayName: 'Single',
      difficulty: 1,
      fruits: const [
        Fruit(id: 'apple', displayName: 'Pomme', price: 100),
      ],
      initialCash: 50000,
      initialStock: const {'apple': 200},
      objectiveCash: 100000,
      lossThresholdRatio: 0.5,
      offersPerSide: 4,
      buyTemplates: const [
        [80, 90, 95, 110],
      ],
      sellTemplates: const [
        [120, 105, 100, 85],
      ],
      roundingRule: 'free_integers',
    );

    test('les prix unitaires effectifs des achats refletent les pourcentages', () {
      final gen = _generator();
      final state = GameState(
        cash: 50000,
        stock: const {'apple': 200},
        currentPrices: const {'apple': 100},
        turnCount: 0,
        elapsedMs: 0,
        currentBuyOffers: const [],
        currentSellOffers: const [],
      );
      final result = gen.generate(state: state, level: singleFruitLevel);

      const fruitPrice = 100;
      final actualPercentages = result.buys
          .map((o) => o.totalPrice / o.quantity / fruitPrice * 100)
          .toList()
        ..sort();
      final expected = [80.0, 90.0, 95.0, 110.0]..sort();

      for (var i = 0; i < actualPercentages.length; i++) {
        expect(actualPercentages[i], closeTo(expected[i], 5),
            reason:
                'Buy ratio $i: ${actualPercentages[i]} not close to ${expected[i]}');
      }
    });

    test('les prix unitaires effectifs des ventes refletent les pourcentages', () {
      final gen = _generator();
      final state = GameState(
        cash: 50000,
        stock: const {'apple': 200},
        currentPrices: const {'apple': 100},
        turnCount: 0,
        elapsedMs: 0,
        currentBuyOffers: const [],
        currentSellOffers: const [],
      );
      final result = gen.generate(state: state, level: singleFruitLevel);

      const fruitPrice = 100;
      final actualPercentages = result.sells
          .map((o) => o.totalPrice / o.quantity / fruitPrice * 100)
          .toList()
        ..sort();
      final expected = [85.0, 100.0, 105.0, 120.0]..sort();

      for (var i = 0; i < actualPercentages.length; i++) {
        expect(actualPercentages[i], closeTo(expected[i], 5),
            reason:
                'Sell ratio $i: ${actualPercentages[i]} not close to ${expected[i]}');
      }
    });

    test('au moins une offre d\'achat rentable quand le template en contient', () {
      final gen = _generator();
      final result = gen.generate(state: _state(), level: _level);

      // Template [80, 90, 95, 110]: 80% and 90% are below market → profitable
      final hasProfitable = result.buys.any((offer) {
        final fruit = _level.fruits.firstWhere((f) => f.id == offer.fruitId);
        return offer.totalPrice / offer.quantity < fruit.price;
      });
      expect(hasProfitable, isTrue);
    });

    test('au moins une offre de vente rentable quand le template en contient', () {
      final gen = _generator();
      final result = gen.generate(state: _state(), level: _level);

      // Template [120, 105, 100, 85]: 120% and 105% are above market → profitable
      final hasProfitable = result.sells.any((offer) {
        final fruit = _level.fruits.firstWhere((f) => f.id == offer.fruitId);
        return offer.totalPrice / offer.quantity > fruit.price;
      });
      expect(hasProfitable, isTrue);
    });
  });

  group('OfferGenerator — cas limites', () {
    test('cash tres bas (10\$) : offres d\'achat realisables', () {
      final gen = _generator();
      final state = _state(cash: 10);
      final result = gen.generate(state: state, level: _level);
      expect(result.buys, isNotEmpty);
      for (final offer in result.buys) {
        expect(offer.totalPrice, lessThanOrEqualTo(10));
        expect(offer.quantity, greaterThanOrEqualTo(1));
      }
    });

    test('cash tres bas avec MultiplesOfTenRule : offres realisables', () {
      final gen = _generator(rule: const MultiplesOfTenRule());
      final state = _state(cash: 15);
      final result = gen.generate(state: state, level: _level);
      expect(result.buys, isNotEmpty);
      for (final offer in result.buys) {
        expect(offer.totalPrice, lessThanOrEqualTo(15));
      }
    });

    test('stock vide pour tous les fruits : liste de vente vide', () {
      final gen = _generator();
      final state = _state(stock: {'apple': 0, 'orange': 0});
      final result = gen.generate(state: state, level: _level);
      expect(result.sells, isEmpty);
      expect(result.buys, isNotEmpty);
    });

    test('cash zero : liste d\'achat vide', () {
      final gen = _generator();
      final state = _state(cash: 0);
      final result = gen.generate(state: state, level: _level);
      expect(result.buys, isEmpty);
      expect(result.sells, isNotEmpty);
    });

    test('stock partiel : seuls les fruits avec stock > 0 en vente', () {
      final gen = _generator();
      final state = _state(stock: {'apple': 15, 'orange': 0});
      final result = gen.generate(state: state, level: _level);
      for (final offer in result.sells) {
        expect(offer.fruitId, equals('apple'));
        expect(offer.quantity, lessThanOrEqualTo(15));
      }
    });

    test('stock de 1 par fruit : quantites de vente plafonnees a 1', () {
      final gen = _generator();
      final state = _state(stock: {'apple': 1, 'orange': 1});
      final result = gen.generate(state: state, level: _level);
      for (final offer in result.sells) {
        expect(offer.quantity, equals(1));
      }
    });

    test('stock modeste : contrainte respectee sur plusieurs seeds', () {
      for (var seed = 0; seed < 20; seed++) {
        final gen = _generator(seed: seed);
        final state = _state(stock: {'apple': 4, 'orange': 6});
        final result = gen.generate(state: state, level: _level);
        for (final offer in result.sells) {
          final stock = state.stock[offer.fruitId]!;
          expect(offer.quantity, lessThanOrEqualTo(stock),
              reason: 'seed=$seed ${offer.fruitId}: '
                  'qty ${offer.quantity} > stock $stock');
        }
      }
    });

    test('cash modeste : contrainte respectee sur plusieurs seeds', () {
      for (var seed = 0; seed < 20; seed++) {
        final gen = _generator(seed: seed);
        final state = _state(cash: 25);
        final result = gen.generate(state: state, level: _level);
        for (final offer in result.buys) {
          expect(offer.totalPrice, lessThanOrEqualTo(25),
              reason: 'seed=$seed $offer depasse le cash');
        }
      }
    });

    test('avec MultiplesOfTenRule et cash large, quantites multiples de 10', () {
      final gen = _generator(rule: const MultiplesOfTenRule());
      final state = _state(cash: 5000, stock: {'apple': 100, 'orange': 100});
      final result = gen.generate(state: state, level: _level);
      for (final offer in result.buys) {
        expect(offer.quantity % 10, equals(0),
            reason: 'Buy qty ${offer.quantity} pas multiple de 10');
      }
    });

    test('plusieurs templates : les deux sont utilises avec des seeds differentes', () {
      final multiTemplateLevel = LevelConfig(
        id: 'multi',
        displayName: 'Multi',
        difficulty: 1,
        fruits: const [_apple],
        initialCash: 10000,
        initialStock: const {'apple': 100},
        objectiveCash: 20000,
        lossThresholdRatio: 0.5,
        offersPerSide: 2,
        buyTemplates: const [
          [80, 120],
          [50, 150],
        ],
        sellTemplates: const [
          [90, 110],
        ],
        roundingRule: 'free_integers',
      );

      final state = GameState(
        cash: 10000,
        stock: const {'apple': 100},
        currentPrices: const {'apple': 10},
        turnCount: 0,
        elapsedMs: 0,
        currentBuyOffers: const [],
        currentSellOffers: const [],
      );

      final allBuyPrices = <int>{};
      for (var seed = 0; seed < 50; seed++) {
        final gen = _generator(seed: seed);
        final result = gen.generate(state: state, level: multiTemplateLevel);
        for (final offer in result.buys) {
          allBuyPrices.add(offer.totalPrice);
        }
      }
      // With enough seeds, both templates should produce distinct prices
      expect(allBuyPrices.length, greaterThan(2));
    });
  });
}
