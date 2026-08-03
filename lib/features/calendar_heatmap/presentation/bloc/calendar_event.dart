import 'package:equatable/equatable.dart';
import '../../data/models/calendar_day_model.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class LoadCalendarEntriesEvent extends CalendarEvent {
  final String goalId;

  const LoadCalendarEntriesEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class ToggleCalendarDayTickEvent extends CalendarEvent {
  final String goalId;
  final CalendarDayModel day;

  const ToggleCalendarDayTickEvent({
    required this.goalId,
    required this.day,
  });

  @override
  List<Object?> get props => [goalId, day];
}
