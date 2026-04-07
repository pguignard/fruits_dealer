import 'offer.dart';

class GameState {
  const GameState({
    required this.cash,
    required this.stock,
    required this.currentPrices,
    required this.turnCount,
    required this.elapsedMs,
    required this.currentBuyOffers,
    required this.currentSellOffers,
  });

  final int cash;
  final Map<String, int> stock;
  final Map<String, int> currentPrices;
  final int turnCount;
  final int elapsedMs;
  final List<BuyOffer> currentBuyOffers;
  final List<SellOffer> currentSellOffers;

  int get totalAssetsValue {
    var stockValue = 0;
    for (final entry in stock.entries) {
      final price = currentPrices[entry.key] ?? 0;
      stockValue += entry.value * price;
    }
    return cash + stockValue;
  }

  GameState copyWith({
    int? cash,
    Map<String, int>? stock,
    Map<String, int>? currentPrices,
    int? turnCount,
    int? elapsedMs,
    List<BuyOffer>? currentBuyOffers,
    List<SellOffer>? currentSellOffers,
  }) {
    return GameState(
      cash: cash ?? this.cash,
      stock: stock ?? this.stock,
      currentPrices: currentPrices ?? this.currentPrices,
      turnCount: turnCount ?? this.turnCount,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      currentBuyOffers: currentBuyOffers ?? this.currentBuyOffers,
      currentSellOffers: currentSellOffers ?? this.currentSellOffers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameState &&
          other.cash == cash &&
          _mapsEqual(other.stock, stock) &&
          _mapsEqual(other.currentPrices, currentPrices) &&
          other.turnCount == turnCount &&
          other.elapsedMs == elapsedMs &&
          _listsEqual(other.currentBuyOffers, currentBuyOffers) &&
          _listsEqual(other.currentSellOffers, currentSellOffers));

  @override
  int get hashCode => Object.hash(
        cash,
        Object.hashAll(stock.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(
            currentPrices.entries.map((e) => Object.hash(e.key, e.value))),
        turnCount,
        elapsedMs,
        Object.hashAll(currentBuyOffers),
        Object.hashAll(currentSellOffers),
      );

  @override
  String toString() => 'GameState(cash: $cash, turnCount: $turnCount, '
      'elapsedMs: $elapsedMs, totalAssetsValue: $totalAssetsValue)';
}

bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
