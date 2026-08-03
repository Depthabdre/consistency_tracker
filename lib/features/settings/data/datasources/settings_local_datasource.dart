import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<bool> saveSettings(AppSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box settingsBox;
  static const String key = 'user_app_settings';

  SettingsLocalDataSourceImpl({required this.settingsBox});

  @override
  Future<AppSettings> getSettings() async {
    final raw = settingsBox.get(key);
    if (raw == null) {
      return AppSettings.defaults;
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(
      jsonDecode(raw as String) as Map,
    );
    return AppSettings.fromJson(json);
  }

  @override
  Future<bool> saveSettings(AppSettings settings) async {
    await settingsBox.put(key, jsonEncode(settings.toJson()));
    return true;
  }
}
