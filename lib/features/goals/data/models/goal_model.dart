import 'package:equatable/equatable.dart';
import 'reminder_time_model.dart';

class GoalModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final int targetMinutes;
  final int reminderTimeHour;
  final int reminderTimeMinute;
  final List<ReminderTimeModel> reminderTimes;
  final String motivationalQuote;
  final String colorHex;
  final DateTime createdAt;
  final bool isActive;

  /// Days the goal is scheduled (1 = Monday … 7 = Sunday). Others are rest days.
  final List<int> activeWeekdays;

  static const List<int> everyDay = [1, 2, 3, 4, 5, 6, 7];

  const GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMinutes,
    required this.reminderTimeHour,
    required this.reminderTimeMinute,
    this.reminderTimes = const [],
    required this.motivationalQuote,
    required this.colorHex,
    required this.createdAt,
    this.isActive = true,
    this.activeWeekdays = everyDay,
  });

  bool isActiveOn(DateTime day) => activeWeekdays.contains(day.weekday);

  /// Scheduled on [day]: on or after creation and not a rest day.
  bool isScheduledOn(DateTime day) {
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return !created.isAfter(DateTime(day.year, day.month, day.day)) &&
        isActiveOn(day);
  }

  bool get hasRestDays => activeWeekdays.length < 7;

  String get scheduleLabel {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (!hasRestDays) return 'Every day';
    final days = activeWeekdays.toSet();
    if (days.length == 5 && days.containsAll([1, 2, 3, 4, 5])) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.containsAll([6, 7])) return 'Weekends';
    return activeWeekdays.map((d) => names[d - 1]).join(', ');
  }

  static List<int> _parseWeekdays(dynamic raw) {
    if (raw is! List) return everyDay;
    final days =
        raw
            .map((e) => _parseInt(e, 0))
            .where((d) => d >= 1 && d <= 7)
            .toSet()
            .toList()
          ..sort();
    return days.isEmpty ? everyDay : days;
  }

  List<ReminderTimeModel> get activeReminderTimes {
    if (reminderTimes.isNotEmpty) {
      return reminderTimes;
    }
    return [
      ReminderTimeModel(hour: reminderTimeHour, minute: reminderTimeMinute),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetMinutes': targetMinutes,
      'reminderTimeHour': reminderTimeHour,
      'reminderTimeMinute': reminderTimeMinute,
      'reminderTimes': activeReminderTimes.map((r) => r.toJson()).toList(),
      'motivationalQuote': motivationalQuote,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'activeWeekdays': activeWeekdays,
    };
  }

  static int _parseInt(dynamic val, int defaultValue) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final hour = _parseInt(json['reminderTimeHour'], 9);
    final minute = _parseInt(json['reminderTimeMinute'], 0);

    List<ReminderTimeModel> parsedReminders = [];
    if (json['reminderTimes'] is List) {
      final rawList = json['reminderTimes'] as List;
      parsedReminders = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => ReminderTimeModel.fromJson(item))
          .toList();
    }

    if (parsedReminders.isEmpty) {
      parsedReminders = [ReminderTimeModel(hour: hour, minute: minute)];
    }

    return GoalModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Target Goal',
      description: json['description'] as String? ?? '',
      targetMinutes: _parseInt(json['targetMinutes'], 20),
      reminderTimeHour: hour,
      reminderTimeMinute: minute,
      reminderTimes: parsedReminders,
      motivationalQuote: json['motivationalQuote'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      activeWeekdays: _parseWeekdays(json['activeWeekdays']),
    );
  }

  GoalModel copyWith({
    String? id,
    String? title,
    String? description,
    int? targetMinutes,
    int? reminderTimeHour,
    int? reminderTimeMinute,
    List<ReminderTimeModel>? reminderTimes,
    String? motivationalQuote,
    String? colorHex,
    DateTime? createdAt,
    bool? isActive,
    List<int>? activeWeekdays,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      reminderTimeHour: reminderTimeHour ?? this.reminderTimeHour,
      reminderTimeMinute: reminderTimeMinute ?? this.reminderTimeMinute,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    targetMinutes,
    reminderTimeHour,
    reminderTimeMinute,
    reminderTimes,
    motivationalQuote,
    colorHex,
    createdAt,
    isActive,
    activeWeekdays,
  ];
}
