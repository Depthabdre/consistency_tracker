import 'package:equatable/equatable.dart';

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
