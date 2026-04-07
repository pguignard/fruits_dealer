sealed class Offer {
  const Offer({
    required this.fruitId,
    required this.quantity,
    required this.totalPrice,
  });

  final String fruitId;
  final int quantity;
  final int totalPrice;
}

final class BuyOffer extends Offer {
  const BuyOffer({
    required super.fruitId,
    required super.quantity,
    required super.totalPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuyOffer &&
          other.fruitId == fruitId &&
          other.quantity == quantity &&
          other.totalPrice == totalPrice);

  @override
  int get hashCode => Object.hash(fruitId, quantity, totalPrice);

  @override
  String toString() =>
      'BuyOffer(fruitId: $fruitId, quantity: $quantity, totalPrice: $totalPrice)';
}

final class SellOffer extends Offer {
  const SellOffer({
    required super.fruitId,
    required super.quantity,
    required super.totalPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SellOffer &&
          other.fruitId == fruitId &&
          other.quantity == quantity &&
          other.totalPrice == totalPrice);

  @override
  int get hashCode => Object.hash(fruitId, quantity, totalPrice);

  @override
  String toString() =>
      'SellOffer(fruitId: $fruitId, quantity: $quantity, totalPrice: $totalPrice)';
}
