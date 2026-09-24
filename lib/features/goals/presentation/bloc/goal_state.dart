import 'package:equatable/equatable.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
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
  final Map<String, List<CalendarDayModel>> entriesByGoalId;

  const GoalLoadedState(
    this.goals, {
    this.todayMinutesByGoalId = const {},
    this.entriesByGoalId = const {},
  });

  int todayMinutesFor(String goalId) => todayMinutesByGoalId[goalId] ?? 0;

  List<CalendarDayModel> entriesFor(String goalId) =>
      entriesByGoalId[goalId] ?? const [];

  @override
  List<Object?> get props => [goals, todayMinutesByGoalId, entriesByGoalId];
}

class GoalErrorState extends GoalState {
  final String message;

  const GoalErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
