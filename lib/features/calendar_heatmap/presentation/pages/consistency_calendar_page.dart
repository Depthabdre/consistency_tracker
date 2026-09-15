import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../goals/data/models/goal_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../reusable_widgets/calendar_grid_widget.dart';
import '../reusable_widgets/day_detail_bottom_sheet.dart';
import '../reusable_widgets/streak_counter_widget.dart';

class ConsistencyCalendarPage extends StatefulWidget {
  final GoalModel goal;

  const ConsistencyCalendarPage({super.key, required this.goal});

  @override
  State<ConsistencyCalendarPage> createState() =>
      _ConsistencyCalendarPageState();
}

class _ConsistencyCalendarPageState extends State<ConsistencyCalendarPage> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
    context.read<CalendarBloc>().add(LoadCalendarEntriesEvent(widget.goal.id));
  }

  bool get _canNavigateBack {
    final startMonth = DateTime(
      widget.goal.createdAt.year,
      widget.goal.createdAt.month,
    );
    final currentMonthView = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    return currentMonthView.isAfter(startMonth);
  }

  void _changeMonth(int increment) {
    if (increment < 0 && !_canNavigateBack) return;
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
    final formattedStartDate = DateFormat(
      'MMM d, yyyy',
    ).format(widget.goal.createdAt);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(title: Text('${widget.goal.title} Heatmap')),
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
                    child: BlocBuilder<CalendarBloc, CalendarState>(
                      builder: (context, state) {
                        if (state is CalendarLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentCyan,
                            ),
                          );
                        }

                        if (state is CalendarErrorState) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Color(0xFFF43F5E)),
                            ),
                          );
                        }

                        if (state is CalendarLoadedState) {
                          final completedCount = state.entries
                              .where((e) => e.isCompleted)
                              .length;

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                // Goal Start Date Header Badge
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.borderOutline,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.flag_rounded,
                                        size: 16,
                                        color: AppTheme.accentCyan,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Goal started on $formattedStartDate',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Streak Counter
                                StreakCounterWidget(
                                  currentStreak: state.currentStreak,
                                  totalDaysCompleted: completedCount,
                                ),
                                const SizedBox(height: 20),

                                // Month Navigation Bar
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.borderOutline,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.chevron_left_rounded,
                                          color: _canNavigateBack
                                              ? AppTheme.textPrimary
                                              : Colors.white24,
                                        ),
                                        onPressed: _canNavigateBack
                                            ? () => _changeMonth(-1)
                                            : null,
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMMM yyyy',
                                        ).format(_displayedMonth),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppTheme.textPrimary,
                                        ),
                                        onPressed: () => _changeMonth(1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Calendar Grid Widget
                                CalendarGridWidget(
                                  currentMonth: _displayedMonth,
                                  goalStartDate: widget.goal.createdAt,
                                  targetMinutes: widget.goal.targetMinutes,
                                  entries: state.entries,
                                  onDayTap: (day) {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          DayDetailBottomSheet(
                                            day: day,
                                            goalTitle: widget.goal.title,
                                            goalStartDate:
                                                widget.goal.createdAt,
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
