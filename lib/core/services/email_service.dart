import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../features/goals/data/models/goal_model.dart';
import '../../features/settings/domain/entities/app_settings.dart';

abstract class EmailService {
  Future<bool> sendTestEmail({required AppSettings settings});
  Future<bool> sendAccountabilityCheckIn({
    required AppSettings settings,
    required List<GoalModel> goals,
    required Map<String, int> todayMinutesByGoalId,
  });
  String? get lastSentDateStr;
}

class EmailServiceImpl implements EmailService {
  static const String lastSentDateKey = 'last_accountability_email_date';
  final Box<dynamic>? _settingsBox;
  String? _lastSentDateStr;

  EmailServiceImpl({Box<dynamic>? settingsBox}) : _settingsBox = settingsBox {
    _lastSentDateStr = _settingsBox?.get(lastSentDateKey) as String?;
  }

  @override
  String? get lastSentDateStr => _lastSentDateStr;

  // Package-private setter for testing
  set lastSentDateStr(String? date) => _lastSentDateStr = date;

  SmtpServer _buildSmtpServer(AppSettings settings) {
    final host = settings.smtpHost.isNotEmpty
        ? settings.smtpHost
        : 'smtp.gmail.com';
    final port = settings.smtpPort > 0 ? settings.smtpPort : 587;
    final username = settings.smtpUsername.isNotEmpty
        ? settings.smtpUsername
        : (settings.accountabilityEmail.trim().isNotEmpty
              ? settings.accountabilityEmail.trim()
              : null);
    final password = settings.smtpPassword.isNotEmpty
        ? settings.smtpPassword
        : null;

    if (host.contains('gmail.com') && username != null && password != null) {
      return gmail(username, password);
    }

    return SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: settings.smtpUseSsl,
      allowInsecure: true,
    );
  }

  @override
  Future<bool> sendTestEmail({required AppSettings settings}) async {
    final recipient = settings.accountabilityEmail.trim();
    if (recipient.isEmpty) return false;

    try {
      final smtpServer = _buildSmtpServer(settings);
      final fromAddress = settings.smtpUsername.isNotEmpty
          ? settings.smtpUsername
          : 'no-reply@consistencytracker.app';

      final message = Message()
        ..from = Address(fromAddress, 'Consistency Tracker')
        ..recipients.add(recipient)
        ..subject = 'Consistency Tracker: Test Notification'
        ..text =
            'Hello!\n\nThis is a test notification from your Consistency Tracker app. '
            'Your accountability email service is successfully configured and ready to keep you on track.\n\n'
            'Keep building your consistency!';

      await send(message, smtpServer);
      return true;
    } catch (_) {
      // Gracefully handle failure without crashing
      return false;
    }
  }

  @override
  Future<bool> sendAccountabilityCheckIn({
    required AppSettings settings,
    required List<GoalModel> goals,
    required Map<String, int> todayMinutesByGoalId,
  }) async {
    if (!settings.accountabilityEmailEnabled) return false;
    final recipient = settings.accountabilityEmail.trim();
    if (recipient.isEmpty) return false;

    // Prevent duplicate sends for today
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastSentDateStr == todayStr) return false;

    if (goals.isEmpty) return false;

    // Determine uncompleted goals
    final uncompletedGoals = goals.where((g) {
      final done = todayMinutesByGoalId[g.id] ?? 0;
      return done < g.targetMinutes;
    }).toList();

    // If all daily targets are completed, no accountability warning needed
    if (uncompletedGoals.isEmpty) return false;

    try {
      final smtpServer = _buildSmtpServer(settings);
      final fromAddress = settings.smtpUsername.isNotEmpty
          ? settings.smtpUsername
          : 'accountability@consistencytracker.app';

      final dateFormatted = DateFormat.yMMMMd().format(DateTime.now());
      final StringBuffer summary = StringBuffer();
      summary.writeln('Daily Focus Accountability Check-in - $dateFormatted\n');
      summary.writeln(
        'You missed your target focus minutes for the following goals today:\n',
      );

      for (final goal in uncompletedGoals) {
        final focused = todayMinutesByGoalId[goal.id] ?? 0;
        summary.writeln(
          ' • ${goal.title}: Focused $focused/${goal.targetMinutes} mins',
        );
        if (goal.motivationalQuote.isNotEmpty) {
          summary.writeln('   "${goal.motivationalQuote}"');
        }
      }

      summary.writeln(
        '\nTomorrow is another opportunity to strengthen your consistency streak. '
        'Take a few minutes before bed to plan tomorrow\'s focus session.',
      );

      final message = Message()
        ..from = Address(fromAddress, 'Consistency Tracker')
        ..recipients.add(recipient)
        ..subject = 'Consistency Tracker: Daily Check-in ($dateFormatted)'
        ..text = summary.toString();

      await send(message, smtpServer);
      _lastSentDateStr = todayStr;
      await _settingsBox?.put(lastSentDateKey, todayStr);
      return true;
    } catch (_) {
      // Gracefully handle failure without crashing
      return false;
    }
  }
}
