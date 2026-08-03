import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_event.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_state.dart';
import '../../../goals/data/models/goal_model.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';
import '../reusable_widgets/circular_timer_widget.dart';
import '../reusable_widgets/timer_controls.dart';

class FocusTimerPage extends StatefulWidget {
  final GoalModel goal;

  const FocusTimerPage({super.key, required this.goal});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.goal.targetMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.goal.title),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: BlocConsumer<FocusTimerBloc, FocusTimerState>(
                      listener: (context, state) {
                        if (state is FocusTimerCompletedState) {
                          _handleCompletedSession(context, state);
                        }
                      },
                      builder: (context, timerState) {
                        final bool isRunningOrPaused =
                            timerState is FocusTimerRunningState ||
                                timerState is FocusTimerPausedState;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: isRunningOrPaused
                                    ? _ActiveSessionContent(
                                        goal: widget.goal,
                                        timerState: timerState,
                                      )
                                    : _NoSessionContent(
                                        goal: widget.goal,
                                        selectedMinutes: _selectedMinutes,
                                        onMinutesChanged: (newMins) {
                                          setState(() => _selectedMinutes = newMins);
                                        },
                                        onMinusTap: () {
                                          setState(() {
                                            _selectedMinutes =
                                                (_selectedMinutes - 5).clamp(5, 720);
                                          });
                                        },
                                        onPlusTap: () {
                                          setState(() {
                                            _selectedMinutes =
                                                (_selectedMinutes + 5).clamp(5, 720);
                                          });
                                        },
                                        onStartTap: () {
                                          context.read<FocusTimerBloc>().add(
                                                StartFocusTimerEvent(
                                                  goalId: widget.goal.id,
                                                  targetMinutes: _selectedMinutes,
                                                ),
                                              );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        );
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

  void _handleCompletedSession(
      BuildContext context, FocusTimerCompletedState state) {
    final today = DateTime.now();
    final calendarBloc = context.read<CalendarBloc>();
    final currentEntries = calendarBloc.state is CalendarLoadedState
        ? (calendarBloc.state as CalendarLoadedState).entries
        : <CalendarDayModel>[];

    // Calculate cumulative minutes focused today for this goal
    int cumulativeToday = state.totalMinutesCompleted;
    for (final entry in currentEntries) {
      if (entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day) {
        cumulativeToday += entry.totalMinutesFocused;
      }
    }

    final isTargetMet = cumulativeToday >= widget.goal.targetMinutes;

    final updatedDay = CalendarDayModel(
      date: today,
      totalMinutesFocused: cumulativeToday,
      targetMinutes: widget.goal.targetMinutes,
      isCompleted: isTargetMet,
    );

    calendarBloc.add(
      ToggleCalendarDayTickEvent(
        goalId: widget.goal.id,
        day: updatedDay,
      ),
    );

    // Celebratory dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTargetMet ? AppTheme.successGreen : AppTheme.accentCyan,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTargetMet ? Icons.emoji_events : Icons.check,
                size: 40,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isTargetMet ? 'Daily Target Completed!' : 'Focus Session Logged!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTargetMet
                  ? 'Awesome job! You reached your daily target of ${widget.goal.targetMinutes} minutes. Today is ticked on your calendar!'
                  : 'You focused for ${state.totalMinutesCompleted} minutes today ($cumulativeToday / ${widget.goal.targetMinutes} mins total). Keep going to complete today\'s tick!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSessionContent extends StatefulWidget {
  final GoalModel goal;
  final int selectedMinutes;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onMinusTap;
  final VoidCallback onPlusTap;
  final VoidCallback onStartTap;

  const _NoSessionContent({
    required this.goal,
    required this.selectedMinutes,
    required this.onMinutesChanged,
    required this.onMinusTap,
    required this.onPlusTap,
    required this.onStartTap,
  });

  @override
  State<_NoSessionContent> createState() => _NoSessionContentState();
}

class _NoSessionContentState extends State<_NoSessionContent> {
  bool _skipBreaks = false;
  late TextEditingController _minutesController;
  final FocusNode _minutesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _minutesController =
        TextEditingController(text: widget.selectedMinutes.toString());
    _minutesFocusNode.addListener(() {
      if (!_minutesFocusNode.hasFocus) {
        _submitMinutes();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NoSessionContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMinutes != widget.selectedMinutes &&
        !_minutesFocusNode.hasFocus) {
      _minutesController.text = widget.selectedMinutes.toString();
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _minutesFocusNode.dispose();
    super.dispose();
  }

  void _submitMinutes() {
    final int? parsed = int.tryParse(_minutesController.text);
    if (parsed != null && parsed > 0) {
      widget.onMinutesChanged(parsed);
    } else {
      _minutesController.text = widget.selectedMinutes.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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
          Text(
            'Target for "${widget.goal.title}" is ${widget.goal.targetMinutes} minutes daily.\n'
            'Tell us how much time you have for this session.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 36),

          // Duration Stepper Box
          Container(
            width: 160,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4F4F4F)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IntrinsicWidth(
                        child: TextField(
                          controller: _minutesController,
                          focusNode: _minutesFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _submitMinutes(),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'mins',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF383838),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onPlusTap,
                            borderRadius:
                                const BorderRadius.only(topRight: Radius.circular(8)),
                            child: const Center(
                              child: Icon(Icons.keyboard_arrow_up,
                                  color: Color(0xFFE2E2E2), size: 28),
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1, color: const Color(0xFF4F4F4F)),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onMinusTap,
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8)),
                            child: const Center(
                              child: Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFFE2E2E2), size: 28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Skip breaks toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _skipBreaks,
                  onChanged: (bool? value) {
                    setState(() {
                      _skipBreaks = value ?? false;
                    });
                  },
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.accentCyan;
                    }
                    return Colors.transparent;
                  }),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFA0A0A0), width: 1.5),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Continuous focus mode (no breaks)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA0A0A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            height: 42,
            child: FilledButton.icon(
              onPressed: widget.onStartTap,
              icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
              label: const Text('Start focus session'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: const TextStyle(
                  fontSize: 15,
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
    );
  }
}

class _ActiveSessionContent extends StatelessWidget {
  final GoalModel goal;
  final FocusTimerState timerState;

  const _ActiveSessionContent({
    required this.goal,
    required this.timerState,
  });

  @override
  Widget build(BuildContext context) {
    int elapsedSeconds = 0;
    int targetMinutes = goal.targetMinutes;
    bool isPaused = false;

    if (timerState is FocusTimerRunningState) {
      final s = timerState as FocusTimerRunningState;
      elapsedSeconds = s.elapsedSeconds;
      targetMinutes = s.targetMinutes;
    } else if (timerState is FocusTimerPausedState) {
      final s = timerState as FocusTimerPausedState;
      elapsedSeconds = s.elapsedSeconds;
      targetMinutes = s.targetMinutes;
      isPaused = true;
    }

    final totalTargetSeconds = targetMinutes * 60;
    final remainingSeconds = (totalTargetSeconds - elapsedSeconds).clamp(0, 99999);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 14,
            left: 16,
            child: Text(
              'FOCUS PERIOD',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8A8A),
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LayoutBuilder(builder: (context, constraints) {
                  return CircularProgressTimer(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: totalTargetSeconds,
                    phaseType: SessionPhaseType.focus,
                    size: 260.0,
                  );
                }),
                const SizedBox(height: 24),
                Text(
                  isPaused ? 'Session Paused' : 'Focus session active',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),

                // Timer Controls
                TimerControls(
                  isPaused: isPaused,
                  onPause: () {
                    context.read<FocusTimerBloc>().add(const PauseFocusTimerEvent());
                  },
                  onResume: () {
                    context.read<FocusTimerBloc>().add(const ResumeFocusTimerEvent());
                  },
                  onStop: () {
                    context.read<FocusTimerBloc>().add(const CompleteFocusTimerEvent());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
