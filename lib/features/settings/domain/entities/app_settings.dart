import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool escalationRemindersEnabled;
  final String accountabilityEmail;
  final bool accountabilityEmailEnabled;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final bool smtpUseSsl;

  const AppSettings({
    required this.focusDurationMinutes,
    required this.breakDurationMinutes,
    required this.soundEnabled,
    required this.notificationsEnabled,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.escalationRemindersEnabled = true,
    this.accountabilityEmail = '',
    this.accountabilityEmailEnabled = false,
    this.smtpHost = 'smtp.gmail.com',
    this.smtpPort = 587,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.smtpUseSsl = false,
  });

  static const AppSettings defaults = AppSettings(
    focusDurationMinutes: 25,
    breakDurationMinutes: 5,
    soundEnabled: true,
    notificationsEnabled: true,
    autoStartBreaks: false,
    autoStartFocus: false,
    escalationRemindersEnabled: true,
    accountabilityEmail: '',
    accountabilityEmailEnabled: false,
    smtpHost: 'smtp.gmail.com',
    smtpPort: 587,
    smtpUsername: '',
    smtpPassword: '',
    smtpUseSsl: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'focusDurationMinutes': focusDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'soundEnabled': soundEnabled,
      'notificationsEnabled': notificationsEnabled,
      'autoStartBreaks': autoStartBreaks,
      'autoStartFocus': autoStartFocus,
      'escalationRemindersEnabled': escalationRemindersEnabled,
      'accountabilityEmail': accountabilityEmail,
      'accountabilityEmailEnabled': accountabilityEmailEnabled,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smtpUsername': smtpUsername,
      'smtpPassword': smtpPassword,
      'smtpUseSsl': smtpUseSsl,
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
      escalationRemindersEnabled:
          json['escalationRemindersEnabled'] as bool? ?? true,
      accountabilityEmail: json['accountabilityEmail'] as String? ?? '',
      accountabilityEmailEnabled:
          json['accountabilityEmailEnabled'] as bool? ?? false,
      smtpHost: json['smtpHost'] as String? ?? 'smtp.gmail.com',
      smtpPort: json['smtpPort'] as int? ?? 587,
      smtpUsername: json['smtpUsername'] as String? ?? '',
      smtpPassword: json['smtpPassword'] as String? ?? '',
      smtpUseSsl: json['smtpUseSsl'] as bool? ?? false,
    );
  }

  AppSettings copyWith({
    int? focusDurationMinutes,
    int? breakDurationMinutes,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? escalationRemindersEnabled,
    String? accountabilityEmail,
    bool? accountabilityEmailEnabled,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    bool? smtpUseSsl,
  }) {
    return AppSettings(
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      escalationRemindersEnabled:
          escalationRemindersEnabled ?? this.escalationRemindersEnabled,
      accountabilityEmail: accountabilityEmail ?? this.accountabilityEmail,
      accountabilityEmailEnabled:
          accountabilityEmailEnabled ?? this.accountabilityEmailEnabled,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpUseSsl: smtpUseSsl ?? this.smtpUseSsl,
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
    escalationRemindersEnabled,
    accountabilityEmail,
    accountabilityEmailEnabled,
    smtpHost,
    smtpPort,
    smtpUsername,
    smtpPassword,
    smtpUseSsl,
  ];
}
