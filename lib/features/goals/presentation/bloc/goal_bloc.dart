import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/goal_repository.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository goalRepository;

  GoalBloc({required this.goalRepository}) : super(const GoalInitialState()) {
    on<LoadGoalsEvent>(_onLoadGoals);
    on<AddGoalEvent>(_onAddGoal);
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
    result.fold(
      onSuccess: (goals) => emit(GoalLoadedState(goals, todayMinutesByGoalId: currentProgressMap)),
      onFailure: (failure) => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onAddGoal(
    AddGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoadingState());
    final saveResult = await goalRepository.saveGoal(event.goal);
    saveResult.fold(
      onSuccess: (_) => add(const LoadGoalsEvent()),
      onFailure: (failure) => emit(GoalErrorState(failure.message)),
    );
  }

  Future<void> _onDeleteGoal(
    DeleteGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoadingState());
    final deleteResult = await goalRepository.deleteGoal(event.id);
    deleteResult.fold(
      onSuccess: (_) => add(const LoadGoalsEvent()),
      onFailure: (failure) => emit(GoalErrorState(failure.message)),
    );
  }

  void _onUpdateGoalProgress(
    UpdateGoalProgressEvent event,
    Emitter<GoalState> emit,
  ) {
    if (state is GoalLoadedState) {
      final currentState = state as GoalLoadedState;
      final updatedMap = Map<String, int>.from(currentState.todayMinutesByGoalId);
      updatedMap[event.goalId] = event.todayMinutes;

      emit(GoalLoadedState(
        currentState.goals,
        todayMinutesByGoalId: updatedMap,
      ));
    }
  }
}
