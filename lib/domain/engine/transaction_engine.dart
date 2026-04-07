import '../entities/game_state.dart';
import '../entities/offer.dart';

class TransactionEngine {
  const TransactionEngine();

  GameState applyOffer(GameState state, Offer offer) {
    return switch (offer) {
      BuyOffer() => _applyBuy(state, offer),
      SellOffer() => _applySell(state, offer),
    };
  }

  GameState _applyBuy(GameState state, BuyOffer offer) {
    final newStock = Map<String, int>.of(state.stock);
    newStock[offer.fruitId] = (newStock[offer.fruitId] ?? 0) + offer.quantity;

    return state.copyWith(
      cash: state.cash - offer.totalPrice,
      stock: newStock,
      turnCount: state.turnCount + 1,
      currentBuyOffers: const [],
      currentSellOffers: const [],
    );
  }

  GameState _applySell(GameState state, SellOffer offer) {
    final newStock = Map<String, int>.of(state.stock);
    newStock[offer.fruitId] = (newStock[offer.fruitId] ?? 0) - offer.quantity;

    return state.copyWith(
      cash: state.cash + offer.totalPrice,
      stock: newStock,
      turnCount: state.turnCount + 1,
      currentBuyOffers: const [],
      currentSellOffers: const [],
    );
  }
}
