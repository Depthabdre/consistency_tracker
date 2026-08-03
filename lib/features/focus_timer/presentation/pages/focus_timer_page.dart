import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_event.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/session_phase.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';
import '../reusable_widgets/circular_timer_widget.dart';
import '../reusable_widgets/phase_timeline_widget.dart';
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
    final settingsState = context.watch<SettingsBloc>().state;
    final activeSettings = settingsState is SettingsLoaded
        ? settingsState.settings
        : AppSettings.defaults;

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFFE2E2E2)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
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
                                        focusDuration: activeSettings.focusDurationMinutes,
                                        breakDuration: activeSettings.breakDurationMinutes,
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
                                        onStartTap: (skipBreaks) {
                                          context.read<FocusTimerBloc>().add(
                                                StartFocusTimerEvent(
                                                  goalId: widget.goal.id,
                                                  targetMinutes: _selectedMinutes,
                                                  settings: activeSettings,
                                                  skipBreaks: skipBreaks,
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
      BuildContext context, FocusTimerCompletedState state) async {
    final calendarRepository = context.read<CalendarRepository>();

    final result = await calendarRepository.addFocusMinutesToToday(
      goalId: widget.goal.id,
      targetMinutes: widget.goal.targetMinutes,
      minutesToAdd: state.totalMinutesCompleted,
    );

    if (!context.mounted) return;

    result.fold(
      onSuccess: (updatedDay) {
        final cumulativeToday = updatedDay.totalMinutesFocused;
        final isTargetMet = updatedDay.isCompleted;

        // Reload CalendarBloc entries for this goalId
        context.read<CalendarBloc>().add(LoadCalendarEntriesEvent(widget.goal.id));

        // Synchronize GoalBloc today's progress map specifically for this goalId
        context.read<GoalBloc>().add(
              UpdateGoalProgressEvent(
                goalId: widget.goal.id,
                todayMinutes: cumulativeToday,
              ),
            );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderOutline, width: 1.2),
            ),
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
                  isTargetMet ? 'Daily Target Completed!' : 'Focus Session Saved!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isTargetMet
                      ? 'Awesome job! You reached your daily target of ${widget.goal.targetMinutes} minutes! Today is marked green on your calendar.'
                      : 'You focused for ${state.totalMinutesCompleted} mins ($cumulativeToday / ${widget.goal.targetMinutes} mins focused today). Keep going to reach today\'s target!',
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
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }
}

class _NoSessionContent extends StatefulWidget {
  final GoalModel goal;
  final int selectedMinutes;
  final int focusDuration;
  final int breakDuration;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onMinusTap;
  final VoidCallback onPlusTap;
  final Function(bool skipBreaks) onStartTap;

  const _NoSessionContent({
    required this.goal,
    required this.selectedMinutes,
    required this.focusDuration,
    required this.breakDuration,
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
    final int blockDuration = widget.focusDuration + widget.breakDuration;
    final int plannedBreaks = blockDuration > 0 ? widget.selectedMinutes ~/ blockDuration : 0;

    String breakLabel;
    if (_skipBreaks || widget.selectedMinutes <= widget.focusDuration || plannedBreaks == 0) {
      breakLabel = 'You\'ll have no breaks.';
    } else if (plannedBreaks == 1) {
      breakLabel = 'You\'ll have 1 break.';
    } else {
      breakLabel = 'You\'ll have $plannedBreaks breaks.';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
          const SizedBox(height: 16),
          Text(
            'Achieve your goals and get more done with focus\nsessions. '
            'Tell us how much time you have, and we\'ll\nset up the rest.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFD0D0D0),
                  fontSize: 14,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 38),

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
                            onTap: widget.onMinusTap,
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
                            onTap: widget.onPlusTap,
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
          const SizedBox(height: 26),

          // Dynamic Break Label
          Text(
            breakLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

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
                'Skip breaks',
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
            height: 40,
            child: FilledButton.icon(
              onPressed: () => widget.onStartTap(_skipBreaks),
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
    int remainingSeconds = 0;
    int totalPhaseSeconds = goal.targetMinutes * 60;
    bool isPaused = false;
    List<SessionPhase> phases = [];
    int currentPhaseIndex = 0;
    SessionPhaseType phaseType = SessionPhaseType.focus;

    if (timerState is FocusTimerRunningState) {
      final s = timerState as FocusTimerRunningState;
      phases = s.phases;
      currentPhaseIndex = s.currentPhaseIndex;
      remainingSeconds = s.remainingSecondsInPhase;
      final currentPhase = s.currentPhase;
      if (currentPhase != null) {
        totalPhaseSeconds = currentPhase.durationSeconds;
        phaseType = currentPhase.type;
      }
    } else if (timerState is FocusTimerPausedState) {
      final s = timerState as FocusTimerPausedState;
      phases = s.phases;
      currentPhaseIndex = s.currentPhaseIndex;
      remainingSeconds = s.remainingSecondsInPhase;
      isPaused = true;
      final currentPhase = s.currentPhase;
      if (currentPhase != null) {
        totalPhaseSeconds = currentPhase.durationSeconds;
        phaseType = currentPhase.type;
      }
    }

    int focusCount = 0;
    int breakCount = 0;
    int currentFocusIndex = 0;
    int currentBreakIndex = 0;

    for (int i = 0; i < phases.length; i++) {
      if (phases[i].type == SessionPhaseType.focus) {
        focusCount++;
        if (i <= currentPhaseIndex) currentFocusIndex = focusCount;
      } else {
        breakCount++;
        if (i <= currentPhaseIndex) currentBreakIndex = breakCount;
      }
    }

    final bool isBreak = phaseType == SessionPhaseType.breakTime;
    final String headline = isBreak
        ? (breakCount > 1 ? 'Break ($currentBreakIndex of $breakCount)' : 'Break period')
        : (focusCount > 1 ? 'Focus period ($currentFocusIndex of $focusCount)' : 'Focus period');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 14,
            child: Text(
              headline.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8A8A),
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Phase Timeline Indicator
                if (phases.isNotEmpty)
                  PhaseTimelineWidget(
                    phases: phases,
                    currentPhaseIndex: currentPhaseIndex,
                  ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final Size screenSize = MediaQuery.sizeOf(context);
                    final double size = math.min(
                      constraints.maxWidth * 0.7,
                      screenSize.height * 0.50,
                    ).clamp(110.0, 520.0);

                    return CircularProgressTimer(
                      remainingSeconds: remainingSeconds,
                      totalSeconds: totalPhaseSeconds,
                      phaseType: isBreak ? SessionPhaseType.breakTime : SessionPhaseType.focus,
                      size: size,
                    );
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  isPaused
                      ? 'Session Paused'
                      : isBreak
                          ? 'Break phase active ☕'
                          : 'Focus session active 🎯',
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
