import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:consistency_tracker/core/services/email_service.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';

void main() {
  late EmailServiceImpl emailService;

  setUp(() {
    emailService = EmailServiceImpl();
  });

  group('EmailService Tests', () {
    final testGoal = GoalModel(
      id: 'g-1',
      title: 'Workout',
      description: 'Daily training',
      targetMinutes: 30,
      reminderTimeHour: 9,
      reminderTimeMinute: 0,
      motivationalQuote: 'Stay strong',
      colorHex: '#53B5EA',
      createdAt: DateTime(2026, 1, 1),
    );

    test(
      'sendAccountabilityCheckIn returns false when accountabilityEmailEnabled is false',
      () async {
        const settings =
            AppSettings.defaults; // accountabilityEmailEnabled is false

        final sent = await emailService.sendAccountabilityCheckIn(
          settings: settings,
          goals: [testGoal],
          todayMinutesByGoalId: {'g-1': 10},
        );

        expect(sent, isFalse);
      },
    );

    test(
      'sendAccountabilityCheckIn returns false when recipient email is empty',
      () async {
        final settings = AppSettings.defaults.copyWith(
          accountabilityEmailEnabled: true,
          accountabilityEmail: '   ',
        );

        final sent = await emailService.sendAccountabilityCheckIn(
          settings: settings,
          goals: [testGoal],
          todayMinutesByGoalId: {'g-1': 10},
        );

        expect(sent, isFalse);
      },
    );

    test(
      'sendAccountabilityCheckIn returns false when all goals targets are met today',
      () async {
        final settings = AppSettings.defaults.copyWith(
          accountabilityEmailEnabled: true,
          accountabilityEmail: 'user@example.com',
        );

        final sent = await emailService.sendAccountabilityCheckIn(
          settings: settings,
          goals: [testGoal],
          todayMinutesByGoalId: {'g-1': 35}, // 35 >= 30 target
        );

        expect(sent, isFalse);
      },
    );

    test(
      'sendAccountabilityCheckIn prevents duplicate sends on the same day',
      () async {
        final settings = AppSettings.defaults.copyWith(
          accountabilityEmailEnabled: true,
          accountabilityEmail: 'user@example.com',
        );

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        emailService.lastSentDateStr = todayStr;

        final sent = await emailService.sendAccountabilityCheckIn(
          settings: settings,
          goals: [testGoal],
          todayMinutesByGoalId: {'g-1': 0},
        );

        expect(sent, isFalse);
      },
    );

    test(
      'sendTestEmail returns false gracefully when recipient is empty',
      () async {
        const settings = AppSettings.defaults;
        final sent = await emailService.sendTestEmail(settings: settings);
        expect(sent, isFalse);
      },
    );
  });
}
