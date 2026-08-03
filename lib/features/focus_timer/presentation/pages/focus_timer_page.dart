import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_event.dart';
import '../../../goals/data/models/goal_model.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';
import '../reusable_widgets/circular_timer_widget.dart';

class FocusTimerPage extends StatefulWidget {
  final GoalModel goal;

  const FocusTimerPage({super.key, required this.goal});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  @override
  void initState() {
    super.initState();
    context.read<FocusTimerBloc>().add(
          StartFocusTimerEvent(
            goalId: widget.goal.id,
            targetMinutes: widget.goal.targetMinutes,
          ),
        );
  }

  Color _parseHex(String hex) {
    try {
      return Color(int.parse('ff${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseHex(widget.goal.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocConsumer<FocusTimerBloc, FocusTimerState>(
        listener: (context, state) {
          if (state is FocusTimerCompletedState) {
            _handleCompletedSession(context, state);
          }
        },
        builder: (context, state) {
          int elapsedSeconds = 0;
          bool isRunning = false;
          bool isTargetReached = false;

          if (state is FocusTimerRunningState) {
            elapsedSeconds = state.elapsedSeconds;
            isRunning = true;
            isTargetReached = state.isTargetReached;
          } else if (state is FocusTimerPausedState) {
            elapsedSeconds = state.elapsedSeconds;
            isRunning = false;
            isTargetReached = elapsedSeconds >= (widget.goal.targetMinutes * 60);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Target Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTargetReached ? Icons.stars : Icons.timer,
                        color: isTargetReached ? AppTheme.success : accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTargetReached
                            ? 'Target Target Met! Keep compounding!'
                            : '${widget.goal.targetMinutes} Mins Focus Goal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isTargetReached ? AppTheme.success : accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Circular Timer Widget
                CircularTimerWidget(
                  elapsedSeconds: elapsedSeconds,
                  targetMinutes: widget.goal.targetMinutes,
                  isRunning: isRunning,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 40),

                // Motivational Quote Card
                if (widget.goal.motivationalQuote.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.format_quote, size: 24, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          '"${widget.goal.motivationalQuote}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),

                // Timer Controls (Play, Pause, Complete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isRunning)
                      FloatingActionButton.large(
                        heroTag: 'pause',
                        onPressed: () {
                          context.read<FocusTimerBloc>().add(const PauseFocusTimerEvent());
                        },
                        backgroundColor: AppTheme.warning,
                        child: const Icon(Icons.pause, size: 36),
                      )
                    else
                      FloatingActionButton.large(
                        heroTag: 'play',
                        onPressed: () {
                          context.read<FocusTimerBloc>().add(const ResumeFocusTimerEvent());
                        },
                        backgroundColor: accentColor,
                        child: const Icon(Icons.play_arrow, size: 36),
                      ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<FocusTimerBloc>()
                            .add(const CompleteFocusTimerEvent());
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 22),
                      label: const Text('Finish & Log Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleCompletedSession(BuildContext context, FocusTimerCompletedState state) {
    // Automatically update today's entry on the calendar heatmap!
    final today = DateTime.now();
    final todayCalendarDay = CalendarDayModel(
      date: today,
      totalMinutesFocused: state.totalMinutesCompleted,
      targetMinutes: widget.goal.targetMinutes,
      isCompleted: true,
    );

    context.read<CalendarBloc>().add(
          ToggleCalendarDayTickEvent(
            goalId: widget.goal.id,
            day: todayCalendarDay,
          ),
        );

    // Celebratory Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Focus Session Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed ${state.totalMinutesCompleted} minutes of focus for ${widget.goal.title}.\nToday is automatically ticked on your calendar!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Targets', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
