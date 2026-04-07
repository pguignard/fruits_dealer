import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/engine/win_loss_evaluator.dart';
import 'package:fruits_trader/domain/entities/game_mode.dart';
import 'package:fruits_trader/domain/entities/game_result.dart';
import 'package:fruits_trader/domain/entities/game_state.dart';
import 'package:fruits_trader/domain/entities/level_config.dart';
import 'package:fruits_trader/domain/entities/fruit.dart';

// Niveau de référence : initialCash=100, objectiveCash=200, lossThresholdRatio=0.5
// Seuil d'effondrement = 100 * 0.5 = 50
final _level = LevelConfig(
  id: 'test',
  displayName: 'Test',
  difficulty: 1,
  fruits: const [Fruit(id: 'apple', displayName: 'Pomme', price: 2)],
  initialCash: 100,
  initialStock: const {'apple': 10},
  objectiveCash: 200,
  lossThresholdRatio: 0.5,
  offersPerSide: 2,
  buyTemplates: const [[90, 110]],
  sellTemplates: const [[110, 90]],
  roundingRule: 'free_integers',
);

GameState _state({
  int cash = 120,
  Map<String, int>? stock,
  Map<String, int>? currentPrices,
  int turnCount = 5,
  int elapsedMs = 3000,
}) {
  return GameState(
    cash: cash,
    stock: stock ?? const {'apple': 10},
    currentPrices: currentPrices ?? const {'apple': 2},
    turnCount: turnCount,
    elapsedMs: elapsedMs,
    currentBuyOffers: const [],
    currentSellOffers: const [],
  );
}

void main() {
  const evaluator = WinLossEvaluator();

  group('Partie en cours — retourne null', () {
    test('cash sous objectif, actifs au-dessus du seuil, pas de limite de temps', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isNull);
    });

    test('mode timeLimit mais temps non ecoule', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 4000),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isNull);
    });

    test('mode timeRun mais temps non ecoule', () {
      final result = evaluator.evaluate(
        state: _state(cash: 150, elapsedMs: 5000),
        level: _level,
        mode: GameMode.timeRun,
        timeLimitMs: 30000,
      );
      expect(result, isNull);
    });
  });

  group('Victoire', () {
    test('cash atteint exactement objectiveCash', () {
      final result = evaluator.evaluate(
        state: _state(cash: 200),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<Victory>());
    });

    test('cash depasse objectiveCash', () {
      final result = evaluator.evaluate(
        state: _state(cash: 250),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<Victory>());
    });

    test('Victory porte les bons turnCount et elapsedMs', () {
      final result = evaluator.evaluate(
        state: _state(cash: 200, turnCount: 12, elapsedMs: 8000),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<Victory>());
      final victory = result! as Victory;
      expect(victory.turnCount, equals(12));
      expect(victory.elapsedMs, equals(8000));
    });

    test('Victory fonctionne aussi en mode timeLimit', () {
      final result = evaluator.evaluate(
        state: _state(cash: 200, elapsedMs: 9500),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isA<Victory>());
    });
  });

  group('Priorite : Victoire > Effondrement', () {
    test('cash atteint objectif meme si totalAssetsValue sous le seuil', () {
      // cash = 200 (objectif atteint), stock = 0 => totalAssetsValue = 200
      // Mais si on force stock vide et cash bas sur totalAssets : ici c'est
      // impossible en meme temps ; on teste le cas ou cash >= objectif
      // et totalAssetsValue serait < seuil si le stock n'existait pas.
      // On cree un etat ou cash = objectiveCash et stock = 0 :
      // totalAssetsValue = 200, seuil = 50 => pas d'effondrement ici.
      // Pour forcer le conflit, on prend un objectif tres bas :
      final lowObjectiveLevel = LevelConfig(
        id: 'low',
        displayName: 'Low',
        difficulty: 1,
        fruits: const [Fruit(id: 'apple', displayName: 'Pomme', price: 2)],
        initialCash: 1000,
        initialStock: const {'apple': 0},
        objectiveCash: 10,      // objectif tres bas
        lossThresholdRatio: 0.9, // seuil tres haut : 1000 * 0.9 = 900
        offersPerSide: 2,
        buyTemplates: const [[90, 110]],
        sellTemplates: const [[110, 90]],
        roundingRule: 'free_integers',
      );
      // cash=10 (objectif atteint), totalAssetsValue=10 < 900 (seuil d'effondrement)
      final state = _state(cash: 10, stock: {}, currentPrices: {});
      final result = evaluator.evaluate(
        state: state,
        level: lowObjectiveLevel,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<Victory>());
    });
  });

  group('Defaite par effondrement', () {
    test('totalAssetsValue tombe strictement sous le seuil', () {
      // seuil = 100 * 0.5 = 50 ; cash=20, stock vide => totalAssetsValue=20
      final result = evaluator.evaluate(
        state: _state(cash: 20, stock: {}, currentPrices: {}),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<DefeatByCollapse>());
    });

    test('totalAssetsValue exactement egal au seuil ne declenche pas d\'effondrement', () {
      // seuil = 50 ; cash=50, stock vide => totalAssetsValue=50 (pas < 50)
      final result = evaluator.evaluate(
        state: _state(cash: 50, stock: {}, currentPrices: {}),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isNull);
    });

    test('DefeatByCollapse porte les bons turnCount et elapsedMs', () {
      final result = evaluator.evaluate(
        state: _state(cash: 20, stock: {}, currentPrices: {}, turnCount: 8, elapsedMs: 6000),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: null,
      );
      expect(result, isA<DefeatByCollapse>());
      final defeat = result! as DefeatByCollapse;
      expect(defeat.turnCount, equals(8));
      expect(defeat.elapsedMs, equals(6000));
    });
  });

  group('Defaite par expiration', () {
    test('mode timeLimit, temps exactement atteint', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 10000),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isA<DefeatByTimeout>());
    });

    test('mode timeLimit, temps depasse', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 12000),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isA<DefeatByTimeout>());
    });

    test('mode timeRun, temps ecoule', () {
      final result = evaluator.evaluate(
        state: _state(cash: 150, elapsedMs: 30000),
        level: _level,
        mode: GameMode.timeRun,
        timeLimitMs: 30000,
      );
      expect(result, isA<DefeatByTimeout>());
    });

    test('DefeatByTimeout porte les bons turnCount et elapsedMs', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 10000, turnCount: 7),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isA<DefeatByTimeout>());
      final defeat = result! as DefeatByTimeout;
      expect(defeat.turnCount, equals(7));
      expect(defeat.elapsedMs, equals(10000));
    });

    test('timeLimitMs null en mode timeLimit ne declenche pas de timeout', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 99999),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: null,
      );
      expect(result, isNull);
    });
  });

  group('Priorite : Effondrement > Expiration', () {
    test('effondrement et temps ecoule => DefeatByCollapse', () {
      // totalAssetsValue=20 < 50 (seuil), ET elapsedMs >= timeLimitMs
      final result = evaluator.evaluate(
        state: _state(cash: 20, stock: {}, currentPrices: {}, elapsedMs: 10000),
        level: _level,
        mode: GameMode.timeLimit,
        timeLimitMs: 10000,
      );
      expect(result, isA<DefeatByCollapse>());
    });
  });

  group('Mode tranquille — le temps n\'est jamais une cause de defaite', () {
    test('elapsedMs depasse timeLimitMs en mode tranquille => null', () {
      final result = evaluator.evaluate(
        state: _state(cash: 120, elapsedMs: 99999),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: 10000,
      );
      expect(result, isNull);
    });

    test('elapsedMs tres grand, cash loin de l\'objectif => null', () {
      final result = evaluator.evaluate(
        state: _state(cash: 130, elapsedMs: 1000000),
        level: _level,
        mode: GameMode.tranquille,
        timeLimitMs: 5000,
      );
      expect(result, isNull);
    });
  });
}
