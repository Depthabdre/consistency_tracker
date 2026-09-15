import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../reusable_widgets/goal_card_widget.dart';
import 'add_edit_goal_page.dart';

class GoalsListPage extends StatefulWidget {
  final Function(GoalModel goal) onStartFocus;
  final Function(GoalModel goal) onViewCalendar;

  const GoalsListPage({
    super.key,
    required this.onStartFocus,
    required this.onViewCalendar,
  });

  @override
  State<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends State<GoalsListPage> {
  String _selectedFilter = 'all'; // 'all', 'in_progress', 'completed'

  int _getTodayMinutes(GoalLoadedState goalState, String goalId) {
    return goalState.todayMinutesByGoalId[goalId] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(title: const Text('Consistency Targets')),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: BlocBuilder<GoalBloc, GoalState>(
                      builder: (context, state) {
                        if (state is GoalLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentCyan,
                            ),
                          );
                        }

                        if (state is GoalErrorState) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Color(0xFFF43F5E),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.message,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.read<GoalBloc>().add(
                                    const LoadGoalsEvent(),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is GoalLoadedState) {
                          final allGoals = state.goals;

                          if (allGoals.isEmpty) {
                            return Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.borderOutline,
                                    width: 1.2,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 40,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Ready, set, focus!',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
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
                                        onPressed: () =>
                                            _openAddGoalModal(context),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 20,
                                          color: Colors.black,
                                        ),
                                        label: const Text(
                                          'Create First Target Goal',
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.accentCyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Calculate Momentum Metrics
                          int totalFocusedToday = 0;
                          int totalTargetMinutes = 0;
                          int completedCount = 0;

                          for (final goal in allGoals) {
                            final mins = _getTodayMinutes(state, goal.id);
                            totalFocusedToday += mins;
                            totalTargetMinutes += goal.targetMinutes;
                            if (mins >= goal.targetMinutes) {
                              completedCount++;
                            }
                          }

                          // Filter goals
                          final filteredGoals = allGoals.where((goal) {
                            final mins = _getTodayMinutes(state, goal.id);
                            final isMet = mins >= goal.targetMinutes;
                            if (_selectedFilter == 'completed') return isMet;
                            if (_selectedFilter == 'in_progress') return !isMet;
                            return true;
                          }).toList();

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Today's Momentum Banner
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          completedCount == allGoals.length &&
                                              allGoals.isNotEmpty
                                          ? AppTheme.successGreen
                                          : AppTheme.borderOutline,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentCyan
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppTheme.accentCyan
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.bolt_rounded,
                                                  color: AppTheme.accentCyan,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Today\'s Momentum',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  completedCount ==
                                                      allGoals.length
                                                  ? AppTheme.successGreen
                                                        .withValues(alpha: 0.15)
                                                  : AppTheme.accentCyan
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$completedCount / ${allGoals.length} Done',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    completedCount ==
                                                        allGoals.length
                                                    ? AppTheme.successGreen
                                                    : AppTheme.accentCyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            '$totalFocusedToday',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            ' / $totalTargetMinutes mins committed',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: totalTargetMinutes > 0
                                              ? (totalFocusedToday /
                                                        totalTargetMinutes)
                                                    .clamp(0.0, 1.0)
                                              : 0.0,
                                          minHeight: 6,
                                          backgroundColor: const Color(
                                            0xFF262626,
                                          ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                completedCount ==
                                                            allGoals.length &&
                                                        allGoals.isNotEmpty
                                                    ? AppTheme.successGreen
                                                    : AppTheme.accentCyan,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Filter chips & New Goal button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _buildFilterChip(
                                          'All',
                                          'all',
                                          Icons.grid_view_rounded,
                                        ),
                                        _buildFilterChip(
                                          'In Progress',
                                          'in_progress',
                                          Icons.timelapse_rounded,
                                        ),
                                        _buildFilterChip(
                                          'Completed',
                                          'completed',
                                          Icons.check_circle_outline_rounded,
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openAddGoalModal(context),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: AppTheme.accentCyan,
                                      ),
                                      label: const Text(
                                        'New Goal',
                                        style: TextStyle(
                                          color: AppTheme.accentCyan,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                if (filteredGoals.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.borderOutline,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No goals in this category.',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredGoals.map((goal) {
                                    final todayMins = _getTodayMinutes(
                                      state,
                                      goal.id,
                                    );
                                    return GoalCardWidget(
                                      goal: goal,
                                      todayFocusedMinutes: todayMins,
                                      onStartFocus: () =>
                                          widget.onStartFocus(goal),
                                      onViewCalendar: () =>
                                          widget.onViewCalendar(goal),
                                      onEdit: () =>
                                          _openEditGoalModal(context, goal),
                                      onDelete: () {
                                        _showGitHubStyleDeleteDialog(
                                          context,
                                          goal,
                                        );
                                      },
                                    );
                                  }),
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

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentCyan.withValues(alpha: 0.18)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan : AppTheme.borderOutline,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
              ),
            ),
          ],
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

  void _openEditGoalModal(BuildContext context, GoalModel goal) async {
    final updatedGoal = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditGoalModal(goal: goal),
    );

    if (updatedGoal != null && context.mounted) {
      context.read<GoalBloc>().add(UpdateGoalEvent(updatedGoal));
    }
  }

  void _showGitHubStyleDeleteDialog(BuildContext context, GoalModel goal) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isMatch =
                textController.text.trim() == goal.title.trim();

            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppTheme.borderOutline,
                  width: 1.2,
                ),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF43F5E),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Delete Target Goal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action cannot be undone. This will permanently delete the "${goal.title}" target goal and all associated focus history.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      children: [
                        const TextSpan(text: 'Please type '),
                        TextSpan(
                          text: goal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(text: ' to confirm:'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: goal.title,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundStart,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: AppTheme.borderOutline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isMatch
                              ? const Color(0xFFF43F5E)
                              : AppTheme.borderOutline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFF4F4F4F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isMatch
                      ? () {
                          Navigator.pop(dialogContext);
                          context.read<GoalBloc>().add(
                            DeleteGoalEvent(goal.id),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF43F5E),
                    disabledBackgroundColor: const Color(
                      0xFFF43F5E,
                    ).withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('I understand, delete goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
