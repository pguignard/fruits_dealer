sealed class GameResult {
  const GameResult({
    required this.turnCount,
    required this.elapsedMs,
  });

  final int turnCount;
  final int elapsedMs;
}

final class Victory extends GameResult {
  const Victory({
    required super.turnCount,
    required super.elapsedMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Victory &&
          other.turnCount == turnCount &&
          other.elapsedMs == elapsedMs);

  @override
  int get hashCode => Object.hash(runtimeType, turnCount, elapsedMs);

  @override
  String toString() =>
      'Victory(turnCount: $turnCount, elapsedMs: $elapsedMs)';
}

final class DefeatByCollapse extends GameResult {
  const DefeatByCollapse({
    required super.turnCount,
    required super.elapsedMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefeatByCollapse &&
          other.turnCount == turnCount &&
          other.elapsedMs == elapsedMs);

  @override
  int get hashCode => Object.hash(runtimeType, turnCount, elapsedMs);

  @override
  String toString() =>
      'DefeatByCollapse(turnCount: $turnCount, elapsedMs: $elapsedMs)';
}

final class DefeatByTimeout extends GameResult {
  const DefeatByTimeout({
    required super.turnCount,
    required super.elapsedMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefeatByTimeout &&
          other.turnCount == turnCount &&
          other.elapsedMs == elapsedMs);

  @override
  int get hashCode => Object.hash(runtimeType, turnCount, elapsedMs);

  @override
  String toString() =>
      'DefeatByTimeout(turnCount: $turnCount, elapsedMs: $elapsedMs)';
}
