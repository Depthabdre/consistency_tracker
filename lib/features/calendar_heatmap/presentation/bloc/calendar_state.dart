import 'package:equatable/equatable.dart';
import '../../data/models/calendar_day_model.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitialState extends CalendarState {
  const CalendarInitialState();
}

class CalendarLoadingState extends CalendarState {
  const CalendarLoadingState();
}

class CalendarLoadedState extends CalendarState {
  final List<CalendarDayModel> entries;
  final int currentStreak;

  const CalendarLoadedState({
    required this.entries,
    required this.currentStreak,
  });

  @override
  List<Object?> get props => [entries, currentStreak];
}

class CalendarErrorState extends CalendarState {
  final String message;

  const CalendarErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
