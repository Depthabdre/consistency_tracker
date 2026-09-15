import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
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
    on<UpdateGoalProgressEvent>(_onUpdateGoalProgress);
  }

  Future<void> _onLoadGoals(
    LoadGoalsEvent event,
    Emitter<GoalState> emit,
  ) async {
    final currentProgressMap = state is GoalLoadedState
        ? Map<String, int>.from((state as GoalLoadedState).todayMinutesByGoalId)
        : <String, int>{};

    emit(const GoalLoadingState());
    final result = await goalRepository.getGoals();
    await result.fold(
      onSuccess: (goals) async {
        if (calendarRepository != null) {
          final now = DateTime.now();
          for (final goal in goals) {
            final entriesRes = await calendarRepository!.getCalendarEntries(
              goal.id,
            );
            entriesRes.fold(
              onSuccess: (entries) {
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
        emit(GoalLoadedState(goals, todayMinutesByGoalId: currentProgressMap));
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

      emit(
        GoalLoadedState(currentState.goals, todayMinutesByGoalId: updatedMap),
      );
    }
  }
}
