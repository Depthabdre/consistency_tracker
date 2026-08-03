import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_settings.dart';
import '../datasources/settings_local_datasource.dart';

abstract class SettingsRepository {
  Future<Result<AppSettings>> getSettings();
  Future<Result<bool>> saveSettings(AppSettings settings);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Result.success(settings);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Result<bool>> saveSettings(AppSettings settings) async {
    try {
      final success = await localDataSource.saveSettings(settings);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to save settings: $e'));
    }
  }
}
