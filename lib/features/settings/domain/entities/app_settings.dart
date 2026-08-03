import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool autoStartBreaks;
  final bool autoStartFocus;

  const AppSettings({
    required this.focusDurationMinutes,
    required this.breakDurationMinutes,
    required this.soundEnabled,
    required this.notificationsEnabled,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
  });

  static const AppSettings defaults = AppSettings(
    focusDurationMinutes: 25,
    breakDurationMinutes: 5,
    soundEnabled: true,
    notificationsEnabled: true,
    autoStartBreaks: false,
    autoStartFocus: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'focusDurationMinutes': focusDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'soundEnabled': soundEnabled,
      'notificationsEnabled': notificationsEnabled,
      'autoStartBreaks': autoStartBreaks,
      'autoStartFocus': autoStartFocus,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      focusDurationMinutes: json['focusDurationMinutes'] as int? ?? 25,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 5,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartFocus: json['autoStartFocus'] as bool? ?? false,
    );
  }

  AppSettings copyWith({
    int? focusDurationMinutes,
    int? breakDurationMinutes,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? autoStartBreaks,
    bool? autoStartFocus,
  }) {
    return AppSettings(
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
    );
  }

  @override
  List<Object?> get props => [
        focusDurationMinutes,
        breakDurationMinutes,
        soundEnabled,
        notificationsEnabled,
        autoStartBreaks,
        autoStartFocus,
      ];
}
