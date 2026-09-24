import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../domain/streak_calculator.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository calendarRepository;

  CalendarBloc({required this.calendarRepository})
    : super(const CalendarInitialState()) {
    on<LoadCalendarEntriesEvent>(_onLoadEntries);
  }

  Future<void> _onLoadEntries(
    LoadCalendarEntriesEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoadingState());
    final result = await calendarRepository.getCalendarEntries(event.goalId);

    result.fold(
      onSuccess: (entries) {
        final streak = calculateCurrentStreak(entries);
        emit(CalendarLoadedState(entries: entries, currentStreak: streak));
      },
      onFailure: (failure) => emit(CalendarErrorState(failure.message)),
    );
  }
}
