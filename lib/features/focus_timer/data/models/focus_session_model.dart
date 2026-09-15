import 'package:equatable/equatable.dart';

class FocusSessionModel extends Equatable {
  final String id;
  final String goalId;
  final int durationMinutes;
  final DateTime timestamp;
  final bool completedTargetMet;

  const FocusSessionModel({
    required this.id,
    required this.goalId,
    required this.durationMinutes,
    required this.timestamp,
    required this.completedTargetMet,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'durationMinutes': durationMinutes,
      'timestamp': timestamp.toIso8601String(),
      'completedTargetMet': completedTargetMet,
    };
  }

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) {
    return FocusSessionModel(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      durationMinutes: json['durationMinutes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      completedTargetMet: json['completedTargetMet'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    goalId,
    durationMinutes,
    timestamp,
    completedTargetMet,
  ];
}
