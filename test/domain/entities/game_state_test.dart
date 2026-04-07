import 'package:flutter_test/flutter_test.dart';
import 'package:fruits_trader/domain/entities/game_state.dart';
import 'package:fruits_trader/domain/entities/offer.dart';

GameState _emptyState({
  int cash = 0,
  Map<String, int>? stock,
  Map<String, int>? currentPrices,
  int turnCount = 0,
  int elapsedMs = 0,
}) {
  return GameState(
    cash: cash,
    stock: stock ?? {},
    currentPrices: currentPrices ?? {},
    turnCount: turnCount,
    elapsedMs: elapsedMs,
    currentBuyOffers: const [],
    currentSellOffers: const [],
  );
}

void main() {
  group('GameState.totalAssetsValue', () {
    test('sans stock retourne uniquement le cash', () {
      final state = _emptyState(cash: 150);
      expect(state.totalAssetsValue, equals(150));
    });

    test('avec un seul fruit calcule cash + stock * prix', () {
      final state = _emptyState(
        cash: 100,
        stock: {'apple': 10},
        currentPrices: {'apple': 2},
      );
      expect(state.totalAssetsValue, equals(120));
    });

    test('avec plusieurs fruits cumule la valeur de tous les fruits', () {
      final state = _emptyState(
        cash: 50,
        stock: {'apple': 10, 'orange': 5, 'banana': 20},
        currentPrices: {'apple': 2, 'orange': 5, 'banana': 3},
      );
      // 50 + (10*2) + (5*5) + (20*3) = 50 + 20 + 25 + 60 = 155
      expect(state.totalAssetsValue, equals(155));
    });

    test('un fruit absent de currentPrices compte pour zéro', () {
      final state = _emptyState(
        cash: 100,
        stock: {'apple': 10, 'unknown': 5},
        currentPrices: {'apple': 2},
      );
      // 100 + 10*2 + 5*0 = 120
      expect(state.totalAssetsValue, equals(120));
    });

    test('stock vide avec des prix définis retourne uniquement le cash', () {
      final state = _emptyState(
        cash: 200,
        currentPrices: {'apple': 5, 'orange': 3},
      );
      expect(state.totalAssetsValue, equals(200));
    });
  });

  group('GameState.copyWith', () {
    final base = GameState(
      cash: 100,
      stock: const {'apple': 10},
      currentPrices: const {'apple': 2},
      turnCount: 3,
      elapsedMs: 5000,
      currentBuyOffers: const [
        BuyOffer(fruitId: 'apple', quantity: 5, totalPrice: 8),
      ],
      currentSellOffers: const [],
    );

    test('sans argument retourne un état identique', () {
      final copy = base.copyWith();
      expect(copy.cash, equals(base.cash));
      expect(copy.turnCount, equals(base.turnCount));
      expect(copy.elapsedMs, equals(base.elapsedMs));
    });

    test('met à jour uniquement le cash', () {
      final updated = base.copyWith(cash: 200);
      expect(updated.cash, equals(200));
      expect(updated.turnCount, equals(base.turnCount));
      expect(updated.stock, equals(base.stock));
    });

    test('met à jour uniquement le turnCount', () {
      final updated = base.copyWith(turnCount: 10);
      expect(updated.turnCount, equals(10));
      expect(updated.cash, equals(base.cash));
    });

    test('met à jour le stock', () {
      final updated = base.copyWith(stock: {'apple': 20, 'orange': 5});
      expect(updated.stock['apple'], equals(20));
      expect(updated.stock['orange'], equals(5));
      expect(updated.cash, equals(base.cash));
    });

    test('met à jour elapsedMs et les offres en même temps', () {
      const newBuy = BuyOffer(fruitId: 'orange', quantity: 2, totalPrice: 9);
      const newSell = SellOffer(fruitId: 'apple', quantity: 3, totalPrice: 7);
      final updated = base.copyWith(
        elapsedMs: 9000,
        currentBuyOffers: [newBuy],
        currentSellOffers: [newSell],
      );
      expect(updated.elapsedMs, equals(9000));
      expect(updated.currentBuyOffers, equals([newBuy]));
      expect(updated.currentSellOffers, equals([newSell]));
    });

    test("copyWith ne modifie pas l'original", () {
      base.copyWith(cash: 9999, turnCount: 99);
      expect(base.cash, equals(100));
      expect(base.turnCount, equals(3));
    });

    test('totalAssetsValue reflète le nouvel état après copyWith', () {
      final updated = base.copyWith(
        cash: 0,
        stock: {'apple': 5},
        currentPrices: {'apple': 4},
      );
      expect(updated.totalAssetsValue, equals(20));
    });
  });
}
