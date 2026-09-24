import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository goalRepository;
  final NotificationRepository? notificationRepository;
  final CalendarRepository? calendarRepository;

  GoalBloc({
    required this.goalRepository,
    this.notificationRepository,
    this.calendarRepository,
  }) : super(const GoalInitialState()) {
    on<LoadGoalsEvent>(_onLoadGoals);
    on<AddGoalEvent>(_onAddGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<RestoreGoalEvent>(_onRestoreGoal);
    on<UpdateGoalProgressEvent>(_onUpdateGoalProgress);
  }

  Future<void> _onLoadGoals(
    LoadGoalsEvent event,
    Emitter<GoalState> emit,
  ) async {
    // Calendar is the source of truth when available, so start fresh to avoid
    // carrying yesterday's minutes across midnight.
    final currentProgressMap =
        calendarRepository == null && state is GoalLoadedState
        ? Map<String, int>.from((state as GoalLoadedState).todayMinutesByGoalId)
        : <String, int>{};
    final entriesMap = <String, List<CalendarDayModel>>{};

    emit(const GoalLoadingState());
    final result = await goalRepository.getGoals();
    await result.fold(
      onSuccess: (goals) async {
        final sortedGoals = List<GoalModel>.from(goals)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (calendarRepository != null) {
          final now = DateTime.now();
          for (final goal in sortedGoals) {
            final entriesRes = await calendarRepository!.getCalendarEntries(
              goal.id,
            );
            entriesRes.fold(
              onSuccess: (entries) {
                entriesMap[goal.id] = List.unmodifiable(entries);
                for (final entry in entries) {
                  if (entry.date.year == now.year &&
                      entry.date.month == now.month &&
                      entry.date.day == now.day) {
                    currentProgressMap[goal.id] = entry.totalMinutesFocused;
                    break;
                  }
                }
              },
              onFailure: (_) {},
            );
          }
        }
        emit(
          GoalLoadedState(
            sortedGoals,
            todayMinutesByGoalId: currentProgressMap,
            entriesByGoalId: entriesMap,
          ),
        );
      },
      onFailure: (failure) async => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onAddGoal(AddGoalEvent event, Emitter<GoalState> emit) async {
    emit(const GoalLoadingState());
    final saveResult = await goalRepository.saveGoal(event.goal);
    await saveResult.fold(
      onSuccess: (_) async {
        if (notificationRepository != null) {
          await notificationRepository!.scheduleGoalReminders(event.goal);
        }
        add(const LoadGoalsEvent());
      },
      onFailure: (failure) async => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onUpdateGoal(
    UpdateGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    final saveResult = await goalRepository.saveGoal(event.goal);
    await saveResult.fold(
      onSuccess: (_) async {
        if (notificationRepository != null) {
          await notificationRepository!.cancelGoalReminders(event.goal.id);
          await notificationRepository!.scheduleGoalReminders(event.goal);
        }
        if (state is GoalLoadedState) {
          final currentState = state as GoalLoadedState;
          final updatedGoals = currentState.goals.map((g) {
            return g.id == event.goal.id ? event.goal : g;
          }).toList();
          emit(
            GoalLoadedState(
              updatedGoals,
              todayMinutesByGoalId: currentState.todayMinutesByGoalId,
              entriesByGoalId: currentState.entriesByGoalId,
            ),
          );
        } else {
          emit(const GoalLoadingState());
          add(const LoadGoalsEvent());
        }
      },
      onFailure: (failure) async => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onDeleteGoal(
    DeleteGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoadingState());
    final deleteResult = await goalRepository.deleteGoal(event.id);
    await deleteResult.fold(
      onSuccess: (_) async {
        if (notificationRepository != null) {
          await notificationRepository!.cancelGoalReminders(event.id);
        }
        if (calendarRepository != null) {
          await calendarRepository!.clearEntries(event.id);
        }
        add(const LoadGoalsEvent());
      },
      onFailure: (failure) async => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onRestoreGoal(
    RestoreGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    final saveResult = await goalRepository.saveGoal(event.goal);
    await saveResult.fold(
      onSuccess: (_) async {
        if (calendarRepository != null) {
          for (final day in event.history) {
            await calendarRepository!.saveCalendarDay(event.goal.id, day);
          }
        }
        if (notificationRepository != null) {
          await notificationRepository!.scheduleGoalReminders(event.goal);
        }
        add(const LoadGoalsEvent());
      },
      onFailure: (failure) async => emit(GoalErrorState(failure.message)),
    );
  }

  void _onUpdateGoalProgress(
    UpdateGoalProgressEvent event,
    Emitter<GoalState> emit,
  ) {
    if (state is GoalLoadedState) {
      final currentState = state as GoalLoadedState;
      final updatedMap = Map<String, int>.from(
        currentState.todayMinutesByGoalId,
      );
      updatedMap[event.goalId] = event.todayMinutes;

      final updatedEntries = Map<String, List<CalendarDayModel>>.from(
        currentState.entriesByGoalId,
      );
      final goal = currentState.goals
          .where((g) => g.id == event.goalId)
          .firstOrNull;
      if (goal != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayEntry = CalendarDayModel(
          date: today,
          totalMinutesFocused: event.todayMinutes,
          targetMinutes: goal.targetMinutes,
          isCompleted: event.todayMinutes >= goal.targetMinutes,
        );
        updatedEntries[event.goalId] = List.unmodifiable([
          ...currentState
              .entriesFor(event.goalId)
              .where(
                (e) =>
                    e.date.year != today.year ||
                    e.date.month != today.month ||
                    e.date.day != today.day,
              ),
          todayEntry,
        ]);
      }

      emit(
        GoalLoadedState(
          currentState.goals,
          todayMinutesByGoalId: updatedMap,
          entriesByGoalId: updatedEntries,
        ),
      );
    }
  }
}
