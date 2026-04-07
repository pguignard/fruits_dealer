import '../entities/game_mode.dart';

abstract class ScoreRepository {
  Future<int?> getBestScore(String levelId, GameMode mode);
  Future<void> saveScore(String levelId, GameMode mode, int score);
}
