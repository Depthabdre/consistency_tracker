import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/secret_store.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<bool> saveSettings(AppSettings settings);
}

/// Settings live in Hive; the SMTP password is kept in [secrets] (never in
/// the Hive file) when a secret store is provided.
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box settingsBox;
  final SecretStore? secrets;
  static const String key = 'user_app_settings';
  static const String passwordKey = 'smtp_password';

  SettingsLocalDataSourceImpl({required this.settingsBox, this.secrets});

  @override
  Future<AppSettings> getSettings() async {
    final raw = settingsBox.get(key);
    if (raw == null) return AppSettings.defaults;
    final Map<String, dynamic> json = Map<String, dynamic>.from(
      jsonDecode(raw as String) as Map,
    );
    final settings = AppSettings.fromJson(json);
    final store = secrets;
    if (store == null) return settings;

    // One-time migration of a password saved in plain text by older builds.
    if (settings.smtpPassword.isNotEmpty) {
      await store.write(passwordKey, settings.smtpPassword);
      await _writeJson(settings);
      return settings;
    }
    String? password;
    try {
      password = await store.read(passwordKey);
    } catch (_) {}
    return settings.copyWith(smtpPassword: password ?? '');
  }

  @override
  Future<bool> saveSettings(AppSettings settings) async {
    final store = secrets;
    if (store == null) {
      await settingsBox.put(key, jsonEncode(settings.toJson()));
      return true;
    }
    await store.write(passwordKey, settings.smtpPassword);
    await _writeJson(settings);
    return true;
  }

  Future<void> _writeJson(AppSettings settings) => settingsBox.put(
    key,
    jsonEncode(settings.copyWith(smtpPassword: '').toJson()),
  );
}
