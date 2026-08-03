import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../reusable_widgets/goal_card_widget.dart';
import 'add_edit_goal_page.dart';

class GoalsListPage extends StatelessWidget {
  final Function(GoalModel goal) onStartFocus;
  final Function(GoalModel goal) onViewCalendar;

  const GoalsListPage({
    super.key,
    required this.onStartFocus,
    required this.onViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Consistency Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () => _openAddGoalModal(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth < 600 ? 460 : 700;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: BlocBuilder<GoalBloc, GoalState>(
                      builder: (context, state) {
                        if (state is GoalLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.accentCyan),
                          );
                        }

                        if (state is GoalErrorState) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Color(0xFFF43F5E)),
                                const SizedBox(height: 12),
                                Text(state.message, style: const TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.read<GoalBloc>().add(const LoadGoalsEvent()),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is GoalLoadedState) {
                          final goals = state.goals;

                          if (goals.isEmpty) {
                            return Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderOutline, width: 1.2),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Ready, set, focus!',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 22,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Achieve your daily goals with consistency sessions.\n'
                                      'Set your daily target minutes and build long-term momentum.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      height: 42,
                                      child: FilledButton.icon(
                                        onPressed: () => _openAddGoalModal(context),
                                        icon: const Icon(Icons.add, size: 20, color: Colors.black),
                                        label: const Text('Create First Target Goal'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.accentCyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          textStyle: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${goals.length} Active Target Goals',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _openAddGoalModal(context),
                                      icon: const Icon(Icons.add, size: 16, color: AppTheme.accentCyan),
                                      label: const Text(
                                        'New Goal',
                                        style: TextStyle(color: AppTheme.accentCyan, fontSize: 13.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...goals.map((goal) => GoalCardWidget(
                                      goal: goal,
                                      onStartFocus: () => onStartFocus(goal),
                                      onViewCalendar: () => onViewCalendar(goal),
                                      onDelete: () {
                                        context.read<GoalBloc>().add(DeleteGoalEvent(goal.id));
                                      },
                                    )),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAddGoalModal(BuildContext context) async {
    final newGoal = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEditGoalModal(),
    );

    if (newGoal != null && context.mounted) {
      context.read<GoalBloc>().add(AddGoalEvent(newGoal));
    }
  }
}
