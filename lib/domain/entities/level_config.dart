import 'fruit.dart';

class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.displayName,
    required this.difficulty,
    required this.fruits,
    required this.initialCash,
    required this.initialStock,
    required this.objectiveCash,
    required this.lossThresholdRatio,
    required this.offersPerSide,
    required this.buyTemplates,
    required this.sellTemplates,
    required this.roundingRule,
  });

  final String id;
  final String displayName;
  final int difficulty;
  final List<Fruit> fruits;
  final int initialCash;
  final Map<String, int> initialStock;
  final int objectiveCash;
  final double lossThresholdRatio;
  final int offersPerSide;
  final List<List<int>> buyTemplates;
  final List<List<int>> sellTemplates;
  final String roundingRule;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LevelConfig && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LevelConfig(id: $id, displayName: $displayName, difficulty: $difficulty)';
}
