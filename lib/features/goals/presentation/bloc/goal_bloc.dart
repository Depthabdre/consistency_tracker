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
  }

  Future<void> _onLoadGoals(
    LoadGoalsEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoadingState());
    final result = await goalRepository.getGoals();
    result.fold(
      onSuccess: (goals) => emit(GoalLoadedState(goals)),
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
}
