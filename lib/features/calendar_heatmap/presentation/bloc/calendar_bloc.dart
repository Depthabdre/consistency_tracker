import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/calendar_day_model.dart';
import '../../data/repositories/calendar_repository.dart';
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
        final streak = _calculateCurrentStreak(entries);
        emit(CalendarLoadedState(entries: entries, currentStreak: streak));
      },
      onFailure: (failure) => emit(CalendarErrorState(failure.message)),
    );
  }

  int _calculateCurrentStreak(List<CalendarDayModel> entries) {
    if (entries.isEmpty) return 0;
    entries.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();

    for (final entry in entries) {
      if (entry.isCompleted) {
        streak++;
      } else {
        // If entry is today and not yet done, don't break streak yet
        final isToday =
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day;
        if (!isToday) break;
      }
    }
    return streak;
  }
}
