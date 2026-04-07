class Fruit {
  const Fruit({
    required this.id,
    required this.displayName,
    required this.price,
  });

  final String id;
  final String displayName;
  final int price;

  Fruit copyWith({
    String? id,
    String? displayName,
    int? price,
  }) {
    return Fruit(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Fruit && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Fruit(id: $id, displayName: $displayName, price: $price)';
}
