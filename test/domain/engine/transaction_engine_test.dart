import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/engine/transaction_engine.dart';
import 'package:fruits_trader/domain/entities/game_state.dart';
import 'package:fruits_trader/domain/entities/offer.dart';

GameState _baseState({
  int cash = 200,
  Map<String, int>? stock,
  Map<String, int>? currentPrices,
  int turnCount = 0,
  int elapsedMs = 1000,
}) {
  return GameState(
    cash: cash,
    stock: stock ?? {'apple': 10},
    currentPrices: currentPrices ?? {'apple': 2},
    turnCount: turnCount,
    elapsedMs: elapsedMs,
    currentBuyOffers: const [
      BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8),
    ],
    currentSellOffers: const [
      SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7),
    ],
  );
}

void main() {
  const engine = TransactionEngine();

  group('TransactionEngine — BuyOffer', () {
    test('le cash diminue du totalPrice', () {
      final state = _baseState(cash: 200);
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(state, offer);
      expect(result.cash, equals(192));
    });

    test('le stock du fruit augmente de la quantite', () {
      final state = _baseState(stock: {'apple': 10});
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(state, offer);
      expect(result.stock['apple'], equals(15));
    });

    test('le turnCount est incremente de 1', () {
      final state = _baseState(turnCount: 3);
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(state, offer);
      expect(result.turnCount, equals(4));
    });

    test('elapsedMs est inchange', () {
      final state = _baseState(elapsedMs: 5000);
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(state, offer);
      expect(result.elapsedMs, equals(5000));
    });

    test('les offres courantes sont videes', () {
      final state = _baseState();
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(state, offer);
      expect(result.currentBuyOffers, isEmpty);
      expect(result.currentSellOffers, isEmpty);
    });

    test('achat d\'un fruit absent du stock l\'initialise correctement', () {
      final state = _baseState(stock: {'apple': 10});
      const offer = BuyOffer(fruitId: 'orange', quantity: 3, totalPrice: 15);
      final result = engine.applyOffer(state, offer);
      expect(result.stock['orange'], equals(3));
      expect(result.stock['apple'], equals(10));
    });

    test('currentPrices est inchange', () {
      final state = _baseState(currentPrices: {'apple': 2, 'orange': 5});
      const offer = BuyOffer(fruitId: 'apple', quantity: 2, totalPrice: 4);
      final result = engine.applyOffer(state, offer);
      expect(result.currentPrices, equals({'apple': 2, 'orange': 5}));
    });
  });

  group('TransactionEngine — SellOffer', () {
    test('le cash augmente du totalPrice', () {
      final state = _baseState(cash: 50);
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final result = engine.applyOffer(state, offer);
      expect(result.cash, equals(57));
    });

    test('le stock du fruit diminue de la quantite', () {
      final state = _baseState(stock: {'apple': 10});
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final result = engine.applyOffer(state, offer);
      expect(result.stock['apple'], equals(7));
    });

    test('le turnCount est incremente de 1', () {
      final state = _baseState(turnCount: 5);
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final result = engine.applyOffer(state, offer);
      expect(result.turnCount, equals(6));
    });

    test('elapsedMs est inchange', () {
      final state = _baseState(elapsedMs: 12000);
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final result = engine.applyOffer(state, offer);
      expect(result.elapsedMs, equals(12000));
    });

    test('les offres courantes sont videes', () {
      final state = _baseState();
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final result = engine.applyOffer(state, offer);
      expect(result.currentBuyOffers, isEmpty);
      expect(result.currentSellOffers, isEmpty);
    });
  });

  group('TransactionEngine — etat initial complexe', () {
    test('plusieurs fruits : seul le fruit concerne est modifie (achat)', () {
      final state = _baseState(
        cash: 300,
        stock: {'apple': 10, 'orange': 5, 'banana': 20},
        currentPrices: {'apple': 2, 'orange': 5, 'banana': 3},
      );
      const offer = BuyOffer(fruitId: 'orange', quantity: 4, totalPrice: 18);
      final result = engine.applyOffer(state, offer);

      expect(result.cash, equals(282));
      expect(result.stock['orange'], equals(9));
      expect(result.stock['apple'], equals(10));
      expect(result.stock['banana'], equals(20));
    });

    test('plusieurs fruits : seul le fruit concerne est modifie (vente)', () {
      final state = _baseState(
        cash: 100,
        stock: {'apple': 10, 'orange': 5, 'banana': 20},
        currentPrices: {'apple': 2, 'orange': 5, 'banana': 3},
      );
      const offer = SellOffer(fruitId: 'banana', quantity: 8, totalPrice: 26);
      final result = engine.applyOffer(state, offer);

      expect(result.cash, equals(126));
      expect(result.stock['banana'], equals(12));
      expect(result.stock['apple'], equals(10));
      expect(result.stock['orange'], equals(5));
    });

    test('plusieurs transactions successives sont coherentes', () {
      var state = _baseState(
        cash: 200,
        stock: {'apple': 10},
        turnCount: 0,
      );
      const buy = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      const sell = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);

      state = engine.applyOffer(state, buy);
      state = engine.applyOffer(state, sell);

      expect(state.cash, equals(199));
      expect(state.stock['apple'], equals(12));
      expect(state.turnCount, equals(2));
    });
  });

  group('TransactionEngine — immutabilite', () {
    test('l\'etat original n\'est pas modifie apres un BuyOffer', () {
      final original = _baseState(cash: 200, stock: {'apple': 10}, turnCount: 0);
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      engine.applyOffer(original, offer);

      expect(original.cash, equals(200));
      expect(original.stock['apple'], equals(10));
      expect(original.turnCount, equals(0));
    });

    test('l\'etat original n\'est pas modifie apres un SellOffer', () {
      final original = _baseState(cash: 50, stock: {'apple': 10}, turnCount: 2);
      const offer = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      engine.applyOffer(original, offer);

      expect(original.cash, equals(50));
      expect(original.stock['apple'], equals(10));
      expect(original.turnCount, equals(2));
    });

    test('modifier le stock du resultat ne modifie pas l\'etat original', () {
      final original = _baseState(stock: {'apple': 10});
      const offer = BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8);
      final result = engine.applyOffer(original, offer);

      // La map renvoyée est une copie : la modifier ne doit pas affecter original
      (result.stock as Map<String, int>)['apple'] = 999;
      expect(original.stock['apple'], equals(10));
    });
  });
}
