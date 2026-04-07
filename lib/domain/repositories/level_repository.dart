import '../entities/level_config.dart';

abstract class LevelRepository {
  Future<List<LevelConfig>> loadAllLevels();
  Future<LevelConfig> loadLevel(String id);
}
