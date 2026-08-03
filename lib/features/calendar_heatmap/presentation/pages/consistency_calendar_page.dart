import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../goals/data/models/goal_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../reusable_widgets/calendar_grid_widget.dart';
import '../reusable_widgets/streak_counter_widget.dart';

class ConsistencyCalendarPage extends StatefulWidget {
  final GoalModel goal;

  const ConsistencyCalendarPage({super.key, required this.goal});

  @override
  State<ConsistencyCalendarPage> createState() => _ConsistencyCalendarPageState();
}

class _ConsistencyCalendarPageState extends State<ConsistencyCalendarPage> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
    context.read<CalendarBloc>().add(LoadCalendarEntriesEvent(widget.goal.id));
  }

  void _changeMonth(int increment) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + increment,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.goal.title} Heatmap'),
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoadingState) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is CalendarErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          if (state is CalendarLoadedState) {
            final completedCount =
                state.entries.where((e) => e.isCompleted).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Streak Counter
                  StreakCounterWidget(
                    currentStreak: state.currentStreak,
                    totalDaysCompleted: completedCount,
                  ),
                  const SizedBox(height: 24),

                  // Month Navigation Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calendar Grid Widget
                  CalendarGridWidget(
                    currentMonth: _displayedMonth,
                    entries: state.entries,
                    onDayTap: (day) {
                      context.read<CalendarBloc>().add(
                            ToggleCalendarDayTickEvent(
                              goalId: widget.goal.id,
                              day: day,
                            ),
                          );
                    },
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
