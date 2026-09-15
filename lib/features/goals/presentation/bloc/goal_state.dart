import 'package:equatable/equatable.dart';
import '../../data/models/goal_model.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

class GoalInitialState extends GoalState {
  const GoalInitialState();
}

class GoalLoadingState extends GoalState {
  const GoalLoadingState();
}

class GoalLoadedState extends GoalState {
  final List<GoalModel> goals;
  final Map<String, int> todayMinutesByGoalId;

  const GoalLoadedState(this.goals, {this.todayMinutesByGoalId = const {}});

  @override
  List<Object?> get props => [goals, todayMinutesByGoalId];
}

class GoalErrorState extends GoalState {
  final String message;

  const GoalErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
