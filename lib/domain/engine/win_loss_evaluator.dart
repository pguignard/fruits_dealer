import '../entities/game_mode.dart';
import '../entities/game_result.dart';
import '../entities/game_state.dart';
import '../entities/level_config.dart';

class WinLossEvaluator {
  const WinLossEvaluator();

  GameResult? evaluate({
    required GameState state,
    required LevelConfig level,
    required GameMode mode,
    required int? timeLimitMs,
  }) {
    if (state.cash >= level.objectiveCash) {
      return Victory(turnCount: state.turnCount, elapsedMs: state.elapsedMs);
    }

    if (state.totalAssetsValue < level.initialCash * level.lossThresholdRatio) {
      return DefeatByCollapse(
        turnCount: state.turnCount,
        elapsedMs: state.elapsedMs,
      );
    }

    if ((mode == GameMode.timeLimit || mode == GameMode.timeRun) &&
        timeLimitMs != null &&
        state.elapsedMs >= timeLimitMs) {
      return DefeatByTimeout(
        turnCount: state.turnCount,
        elapsedMs: state.elapsedMs,
      );
    }

    return null;
  }
}
