abstract class RoundingRule {
  const RoundingRule();

  int roundQuantity(double rawQuantity);
  int roundPrice(double rawPrice);

  static RoundingRule fromId(String id) {
    return switch (id) {
      'multiples_of_10' => const MultiplesOfTenRule(),
      'multiples_of_5' => const MultiplesOfFiveRule(),
      'integers_up_to_20' => const IntegersUpToTwentyRule(),
      'free_integers' => const FreeIntegersRule(),
      _ => throw ArgumentError.value(id, 'id', 'Identifiant de règle inconnu'),
    };
  }
}

int _roundToMultiple(double value, int multiple, int minimum) {
  final rounded = (value / multiple).round() * multiple;
  return rounded < minimum ? minimum : rounded;
}

class MultiplesOfTenRule extends RoundingRule {
  const MultiplesOfTenRule();

  @override
  int roundQuantity(double rawQuantity) => _roundToMultiple(rawQuantity, 10, 10);

  @override
  int roundPrice(double rawPrice) => _roundToMultiple(rawPrice, 10, 10);
}

class MultiplesOfFiveRule extends RoundingRule {
  const MultiplesOfFiveRule();

  @override
  int roundQuantity(double rawQuantity) => _roundToMultiple(rawQuantity, 5, 5);

  @override
  int roundPrice(double rawPrice) => _roundToMultiple(rawPrice, 5, 5);
}

class IntegersUpToTwentyRule extends RoundingRule {
  const IntegersUpToTwentyRule();

  @override
  int roundQuantity(double rawQuantity) {
    final rounded = rawQuantity.round().clamp(1, 20);
    return rounded;
  }

  @override
  int roundPrice(double rawPrice) {
    final rounded = rawPrice.round().clamp(1, 20);
    return rounded;
  }
}

class FreeIntegersRule extends RoundingRule {
  const FreeIntegersRule();

  @override
  int roundQuantity(double rawQuantity) {
    final rounded = rawQuantity.round();
    return rounded < 1 ? 1 : rounded;
  }

  @override
  int roundPrice(double rawPrice) {
    final rounded = rawPrice.round();
    return rounded < 1 ? 1 : rounded;
  }
}
