import 'package:equatable/equatable.dart';
import '../../data/models/goal_model.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoalsEvent extends GoalEvent {
  const LoadGoalsEvent();
}

class AddGoalEvent extends GoalEvent {
  final GoalModel goal;

  const AddGoalEvent(this.goal);

  @override
  List<Object?> get props => [goal];
}

class DeleteGoalEvent extends GoalEvent {
  final String id;

  const DeleteGoalEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateGoalProgressEvent extends GoalEvent {
  final String goalId;
  final int todayMinutes;

  const UpdateGoalProgressEvent({
    required this.goalId,
    required this.todayMinutes,
  });

  @override
  List<Object?> get props => [goalId, todayMinutes];
}
