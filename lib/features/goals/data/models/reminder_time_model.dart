import 'package:equatable/equatable.dart';

class ReminderTimeModel extends Equatable {
  final int hour;
  final int minute;

  const ReminderTimeModel({required this.hour, required this.minute});

  factory ReminderTimeModel.fromJson(Map<String, dynamic> json) {
    final rawHour = json['hour'];
    final rawMinute = json['minute'];

    final parsedHour = (rawHour is int)
        ? rawHour
        : int.tryParse(rawHour?.toString() ?? '') ?? 9;
    final parsedMinute = (rawMinute is int)
        ? rawMinute
        : int.tryParse(rawMinute?.toString() ?? '') ?? 0;

    return ReminderTimeModel(
      hour: parsedHour.clamp(0, 23),
      minute: parsedMinute.clamp(0, 59),
    );
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  List<Object?> get props => [hour, minute];
}
