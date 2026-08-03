import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings Entity & JSON Tests', () {
    const settings = AppSettings(
      focusDurationMinutes: 25,
      breakDurationMinutes: 5,
      soundEnabled: true,
      notificationsEnabled: true,
      autoStartBreaks: false,
      autoStartFocus: false,
    );

    test('Positive: should serialize and deserialize AppSettings cleanly', () {
      final json = settings.toJson();
      final fromJson = AppSettings.fromJson(json);

      expect(fromJson, equals(settings));
      expect(json['focusDurationMinutes'], equals(25));
      expect(json['breakDurationMinutes'], equals(5));
      expect(json['soundEnabled'], isTrue);
    });

    test('Positive: copyWith returns updated settings instance', () {
      final updated = settings.copyWith(focusDurationMinutes: 30, soundEnabled: false);

      expect(updated.focusDurationMinutes, equals(30));
      expect(updated.soundEnabled, isFalse);
      expect(updated.breakDurationMinutes, equals(5));
    });

    test('Edge Case: fromJson with empty map returns defaults', () {
      final fromEmpty = AppSettings.fromJson({});

      expect(fromEmpty, equals(AppSettings.defaults));
      expect(fromEmpty.focusDurationMinutes, equals(25));
      expect(fromEmpty.breakDurationMinutes, equals(5));
    });

    test('Negative: copyWith without parameters returns identical instance', () {
      final copied = settings.copyWith();
      expect(copied, equals(settings));
    });
  });
}
