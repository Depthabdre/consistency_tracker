import 'package:equatable/equatable.dart';

class CalendarDayModel extends Equatable {
  final DateTime date;
  final int totalMinutesFocused;
  final int targetMinutes;
  final bool isCompleted;

  const CalendarDayModel({
    required this.date,
    required this.totalMinutesFocused,
    required this.targetMinutes,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalMinutesFocused': totalMinutesFocused,
      'targetMinutes': targetMinutes,
      'isCompleted': isCompleted,
    };
  }

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayModel(
      date: DateTime.parse(json['date'] as String),
      totalMinutesFocused: json['totalMinutesFocused'] as int,
      targetMinutes: json['targetMinutes'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        date,
        totalMinutesFocused,
        targetMinutes,
        isCompleted,
      ];
}
