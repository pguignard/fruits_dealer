import 'dart:math';

import '../entities/fruit.dart';
import '../entities/game_state.dart';
import '../entities/level_config.dart';
import '../entities/offer.dart';
import 'rounding_rules.dart';

class OfferGenerator {
  OfferGenerator({
    required this.roundingRule,
    required this.random,
  });

  final RoundingRule roundingRule;
  final Random random;

  ({List<BuyOffer> buys, List<SellOffer> sells}) generate({
    required GameState state,
    required LevelConfig level,
  }) {
    final buys = _generateBuyOffers(state, level);
    final sells = _generateSellOffers(state, level);
    return (buys: buys, sells: sells);
  }

  // ── Buy offers ────────────────────────────────────────────────

  List<BuyOffer> _generateBuyOffers(GameState state, LevelConfig level) {
    // Design choice: with zero cash no buy is feasible.
    // The game screen will naturally display only sell offers.
    if (state.cash <= 0) return [];

    final template = _pickTemplate(level.buyTemplates);
    final offers = <BuyOffer>[];

    for (final percentage in template) {
      final fruit = _pickRandom(level.fruits);
      offers.add(_buildBuyOffer(fruit, percentage, state.cash, level.fruits));
    }

    offers.shuffle(random);
    return offers;
  }

  /// Produces a feasible BuyOffer for [fruit] at [percentage] of its
  /// reference price, within [availableCash].
  ///
  /// Strategy when the initial offer is too expensive:
  /// 1. Reduce quantity to the maximum affordable.
  /// 2. Fall back to the cheapest fruit in the level.
  /// 3. Ultimate degraded offer: 1 unit, price capped to cash.
  BuyOffer _buildBuyOffer(
    Fruit fruit,
    int percentage,
    int availableCash,
    List<Fruit> allFruits,
  ) {
    final baseRawQty = 5.0 + random.nextInt(16); // [5..20]

    final result = _tryFitBuy(fruit, percentage, baseRawQty, availableCash);
    if (result != null) return result;

    // Fall back to cheapest fruit
    if (allFruits.length > 1) {
      final cheapest = allFruits.reduce((a, b) => a.price <= b.price ? a : b);
      if (cheapest.id != fruit.id) {
        final fallback =
            _tryFitBuy(cheapest, percentage, baseRawQty, availableCash);
        if (fallback != null) return fallback;
      }
    }

    // Degraded fallback: 1 unit at whatever cash is available.
    // Reached only when cash is extremely low relative to all fruit
    // prices — the game's loss-threshold should end the round before this.
    final target = allFruits.reduce((a, b) => a.price <= b.price ? a : b);
    return BuyOffer(
      fruitId: target.id,
      quantity: 1,
      totalPrice: max(1, availableCash),
    );
  }

  /// Tries to build a BuyOffer for [fruit] that fits within [availableCash].
  /// Returns `null` if even 1 unit exceeds the budget after rounding.
  BuyOffer? _tryFitBuy(
    Fruit fruit,
    int percentage,
    double baseRawQty,
    int availableCash,
  ) {
    final effectiveUnit = fruit.price * percentage / 100.0;

    // Zero-percent template or zero-price fruit: offer is essentially free
    if (effectiveUnit <= 0) {
      return BuyOffer(
        fruitId: fruit.id,
        quantity: roundingRule.roundQuantity(baseRawQty),
        totalPrice: 1,
      );
    }

    // Happy path: full rounded quantity
    var qty = roundingRule.roundQuantity(baseRawQty);
    var price = roundingRule.roundPrice(qty * effectiveUnit);
    if (price <= availableCash) {
      return BuyOffer(fruitId: fruit.id, quantity: qty, totalPrice: price);
    }

    // Reduce: compute maximum affordable raw quantity, then round
    final maxRaw = availableCash / effectiveUnit;
    qty = roundingRule.roundQuantity(maxRaw);
    price = roundingRule.roundPrice(qty * effectiveUnit);
    if (price <= availableCash) {
      return BuyOffer(fruitId: fruit.id, quantity: qty, totalPrice: price);
    }

    // Rounding pushed us over budget; bypass the rule with floor
    qty = max(1, maxRaw.floor());
    price = roundingRule.roundPrice(qty * effectiveUnit);
    if (price <= availableCash) {
      return BuyOffer(fruitId: fruit.id, quantity: qty, totalPrice: price);
    }

    return null;
  }

  // ── Sell offers ───────────────────────────────────────────────

  List<SellOffer> _generateSellOffers(GameState state, LevelConfig level) {
    final available =
        level.fruits.where((f) => (state.stock[f.id] ?? 0) > 0).toList();

    // Design choice: no stock at all → no feasible sell offer.
    // The game screen will naturally display only buy offers.
    if (available.isEmpty) return [];

    final template = _pickTemplate(level.sellTemplates);
    final offers = <SellOffer>[];

    for (final percentage in template) {
      final fruit = _pickRandom(available);
      final stock = state.stock[fruit.id] ?? 0;
      offers.add(_buildSellOffer(fruit, percentage, stock));
    }

    offers.shuffle(random);
    return offers;
  }

  SellOffer _buildSellOffer(Fruit fruit, int percentage, int availableStock) {
    final effectiveUnit = fruit.price * percentage / 100.0;

    // Base quantity in [5..20] capped to available stock
    final rawQty = min(5.0 + random.nextInt(16), availableStock.toDouble());
    var qty = roundingRule.roundQuantity(rawQty);

    // Stock constraint takes priority over rounding-rule minimum
    if (qty > availableStock) qty = availableStock;
    if (qty < 1) qty = 1;

    var totalPrice = roundingRule.roundPrice(qty * effectiveUnit);
    if (totalPrice < 1) totalPrice = 1;

    return SellOffer(fruitId: fruit.id, quantity: qty, totalPrice: totalPrice);
  }

  // ── Helpers ───────────────────────────────────────────────────

  List<int> _pickTemplate(List<List<int>> templates) =>
      templates[random.nextInt(templates.length)];

  T _pickRandom<T>(List<T> list) => list[random.nextInt(list.length)];
}
