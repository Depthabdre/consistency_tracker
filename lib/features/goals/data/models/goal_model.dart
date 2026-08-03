import 'package:equatable/equatable.dart';

class GoalModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final int targetMinutes;
  final int reminderTimeHour;
  final int reminderTimeMinute;
  final String motivationalQuote;
  final String colorHex;
  final bool isActive;

  const GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMinutes,
    required this.reminderTimeHour,
    required this.reminderTimeMinute,
    required this.motivationalQuote,
    required this.colorHex,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetMinutes': targetMinutes,
      'reminderTimeHour': reminderTimeHour,
      'reminderTimeMinute': reminderTimeMinute,
      'motivationalQuote': motivationalQuote,
      'colorHex': colorHex,
      'isActive': isActive,
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      targetMinutes: json['targetMinutes'] as int? ?? 20,
      reminderTimeHour: json['reminderTimeHour'] as int? ?? 9,
      reminderTimeMinute: json['reminderTimeMinute'] as int? ?? 0,
      motivationalQuote: json['motivationalQuote'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  GoalModel copyWith({
    String? id,
    String? title,
    String? description,
    int? targetMinutes,
    int? reminderTimeHour,
    int? reminderTimeMinute,
    String? motivationalQuote,
    String? colorHex,
    bool? isActive,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      reminderTimeHour: reminderTimeHour ?? this.reminderTimeHour,
      reminderTimeMinute: reminderTimeMinute ?? this.reminderTimeMinute,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
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
        motivationalQuote,
        colorHex,
        isActive,
      ];
}
