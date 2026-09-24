import 'dart:convert';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/data/repositories/goal_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exports and imports goals with their full calendar history as JSON.
class BackupService {
  BackupService({
    required this.goalRepository,
    required this.calendarRepository,
    this.notificationRepository,
  });

  static const String format = 'consistency-backup';
  static const int version = 1;

  final GoalRepository goalRepository;
  final CalendarRepository calendarRepository;
  final NotificationRepository? notificationRepository;

  Future<String> exportJson({DateTime? now}) async {
    final list = (await goalRepository.getGoals()).fold(
      onSuccess: (g) => g,
      onFailure: (f) => throw Exception(f.message),
    );

    final exported = <Map<String, dynamic>>[];
    for (final goal in list) {
      final entries = (await calendarRepository.getCalendarEntries(
        goal.id,
      )).fold(onSuccess: (e) => e, onFailure: (_) => <CalendarDayModel>[]);
      exported.add({
        ...goal.toJson(),
        'history': [for (final e in entries) e.toJson()],
      });
    }

    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'goals': exported,
    });
  }

  /// Parses a backup without writing anything; throws [BackupFormatException].
  List<(GoalModel, List<CalendarDayModel>)> parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('This file isn’t valid JSON.');
    }
    if (decoded is! Map || decoded['format'] != format) {
      throw const BackupFormatException(
        'This file isn’t a Consistency backup.',
      );
    }
    final rawGoals = decoded['goals'];
    if (rawGoals is! List) {
      throw const BackupFormatException('The backup contains no goals.');
    }

    final parsed = <(GoalModel, List<CalendarDayModel>)>[];
    for (final raw in rawGoals.whereType<Map>()) {
      final json = Map<String, dynamic>.from(raw);
      final goal = GoalModel.fromJson(json);
      if (goal.id.isEmpty) continue;
      final history = <CalendarDayModel>[];
      for (final day
          in (json['history'] as List? ?? const []).whereType<Map>()) {
        try {
          history.add(
            CalendarDayModel.fromJson(Map<String, dynamic>.from(day)),
          );
        } catch (_) {
          // Skip malformed days rather than rejecting the whole backup.
        }
      }
      parsed.add((goal, history));
    }
    return parsed;
  }

  /// Writes parsed goals; existing goals with the same ID are overwritten.
  Future<int> restore(List<(GoalModel, List<CalendarDayModel>)> items) async {
    for (final (goal, history) in items) {
      await goalRepository.saveGoal(goal);
      for (final day in history) {
        await calendarRepository.saveCalendarDay(goal.id, day);
      }
      if (notificationRepository != null) {
        await notificationRepository!.cancelGoalReminders(goal.id);
        await notificationRepository!.scheduleGoalReminders(goal);
      }
    }
    return items.length;
  }
}
