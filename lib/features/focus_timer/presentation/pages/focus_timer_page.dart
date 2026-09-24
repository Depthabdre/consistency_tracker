import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/session_phase.dart';
import '../../domain/usecases/calculate_chunks_usecase.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';
import '../reusable_widgets/circular_timer_widget.dart';
import '../reusable_widgets/phase_timeline_widget.dart';
import '../reusable_widgets/timer_controls.dart';

/// Session completion is persisted and celebrated globally by the navigation
/// shell, so it works even if this page has been minimized.
class FocusTimerPage extends StatefulWidget {
  final GoalModel goal;

  const FocusTimerPage({super.key, required this.goal});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  static const int _minMinutes = 1;
  static const int _maxMinutes = 720;

  final FocusNode _keyboardFocusNode = FocusNode();
  late int _selectedMinutes;
  bool _skipBreaks = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<GoalBloc>().state;
    final today = state is GoalLoadedState
        ? state.todayMinutesFor(widget.goal.id)
        : 0;
    final remaining = widget.goal.targetMinutes - today;
    _selectedMinutes = (remaining > 0 ? remaining : widget.goal.targetMinutes)
        .clamp(_minMinutes, _maxMinutes);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  GoalModel _latestGoal(GoalState state) {
    if (state is! GoalLoadedState) return widget.goal;
    return state.goals.where((g) => g.id == widget.goal.id).firstOrNull ??
        widget.goal;
  }

  bool _isActive(FocusTimerState s) =>
      (s is FocusTimerRunningState && s.goalId == widget.goal.id) ||
      (s is FocusTimerPausedState && s.goalId == widget.goal.id);

  void _togglePause() {
    final bloc = context.read<FocusTimerBloc>();
    final s = bloc.state;
    if (!_isActive(s)) return;
    HapticFeedback.lightImpact();
    bloc.add(
      s is FocusTimerRunningState
          ? const PauseFocusTimerEvent()
          : const ResumeFocusTimerEvent(),
    );
  }

  Future<void> _confirmEnd(
    List<SessionPhase> phases,
    int index,
    int remaining,
  ) async {
    var focusedSeconds = 0;
    for (var i = 0; i < index && i < phases.length; i++) {
      if (phases[i].type == SessionPhaseType.focus) {
        focusedSeconds += phases[i].durationSeconds;
      }
    }
    if (index < phases.length && phases[index].type == SessionPhaseType.focus) {
      focusedSeconds += phases[index].durationSeconds - remaining;
    }
    final minutes = focusedSeconds ~/ 60;

    final end = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End session early?'),
        content: Text(
          minutes > 0
              ? 'You’ve focused for ${formatMinutes(minutes)}. That time will be logged to today.'
              : 'You haven’t completed a full minute yet, so nothing will be logged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(minutes > 0 ? 'End and log' : 'End session'),
          ),
        ],
      ),
    );
    if (end == true && mounted) {
      context.read<FocusTimerBloc>().add(const CompleteFocusTimerEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final settings = settingsState is SettingsLoaded
        ? settingsState.settings
        : AppSettings.defaults;
    final goalState = context.watch<GoalBloc>().state;
    final goal = _latestGoal(goalState);
    final todayMinutes = goalState is GoalLoadedState
        ? goalState.todayMinutesFor(goal.id)
        : 0;
    final timerState = context.watch<FocusTimerBloc>().state;
    final active = _isActive(timerState);
    final accent = colorFromHex(goal.colorHex);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space &&
            FocusManager.instance.primaryFocus == _keyboardFocusNode) {
          _togglePause();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                goal: goal,
                active: active,
                onBack: () => Navigator.of(context).maybePop(),
                onSettings: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.standard,
                  child: active
                      ? _ActiveSession(
                          key: const ValueKey('active'),
                          goal: goal,
                          timerState: timerState,
                          accent: accent,
                          onTogglePause: _togglePause,
                          onEnd: _confirmEnd,
                          onMinimize: () => Navigator.of(context).maybePop(),
                        )
                      : _SessionSetup(
                          key: const ValueKey('setup'),
                          goal: goal,
                          accent: accent,
                          todayMinutes: todayMinutes,
                          settings: settings,
                          selectedMinutes: _selectedMinutes,
                          skipBreaks: _skipBreaks,
                          onMinutesChanged: (m) => setState(
                            () => _selectedMinutes = m.clamp(
                              _minMinutes,
                              _maxMinutes,
                            ),
                          ),
                          onSkipBreaksChanged: (v) =>
                              setState(() => _skipBreaks = v),
                          onStart: () {
                            HapticFeedback.mediumImpact();
                            context.read<FocusTimerBloc>().add(
                              StartFocusTimerEvent(
                                goalId: goal.id,
                                targetMinutes: _selectedMinutes,
                                settings: settings,
                                skipBreaks: _skipBreaks,
                              ),
                            );
                            _keyboardFocusNode.requestFocus();
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.goal,
    required this.active,
    required this.onBack,
    required this.onSettings,
  });

  final GoalModel goal;
  final bool active;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          AppIconButton(
            icon: active
                ? Icons.keyboard_arrow_down_rounded
                : Icons.arrow_back_rounded,
            tooltip: active ? 'Minimize — session keeps running' : 'Back',
            onTap: onBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium,
                ),
                Text(
                  active ? 'In session' : 'New session',
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: active ? 0 : 1,
            child: IgnorePointer(
              ignoring: active,
              child: AppIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Session settings',
                onTap: onSettings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSetup extends StatelessWidget {
  const _SessionSetup({
    super.key,
    required this.goal,
    required this.accent,
    required this.todayMinutes,
    required this.settings,
    required this.selectedMinutes,
    required this.skipBreaks,
    required this.onMinutesChanged,
    required this.onSkipBreaksChanged,
    required this.onStart,
  });

  final GoalModel goal;
  final Color accent;
  final int todayMinutes;
  final AppSettings settings;
  final int selectedMinutes;
  final bool skipBreaks;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<bool> onSkipBreaksChanged;
  final VoidCallback onStart;

  Future<void> _editMinutes(BuildContext context) async {
    final controller = TextEditingController(text: '$selectedMinutes');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session length'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: 'minutes'),
          onSubmitted: (v) => Navigator.pop(dialogContext, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value > 0) onMinutesChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final plan = CalculateChunksUseCase()(
      totalTargetMinutes: selectedMinutes,
      settings: settings,
      skipBreaks: skipBreaks,
    );
    final focusBlocks = plan.phases
        .where((p) => p.type == SessionPhaseType.focus)
        .length;
    final breaks = plan.phases.length - focusBlocks;
    final endsAt = DateTime.now().add(
      Duration(seconds: plan.totalFocusSeconds + plan.totalBreakSeconds),
    );
    final remainingToday = goal.targetMinutes - todayMinutes;
    final presets = <int>{
      if (remainingToday > 0) remainingToday.clamp(1, 720),
      15,
      25,
      45,
      60,
      90,
    }.toList();
    final step = selectedMinutes > 5 ? 5 : 1;
    final isDesktop =
        kIsWeb ||
        {
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
        }.contains(defaultTargetPlatform);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = math.max(20.0, (constraints.maxWidth - 480) / 2);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                remainingToday <= 0
                    ? 'Today’s target is done · $todayMinutes min so far'
                    : 'Today $todayMinutes of ${goal.targetMinutes} min',
                textAlign: TextAlign.center,
                style: theme.bodySmall?.copyWith(
                  color: remainingToday <= 0
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIconButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Decrease',
                    size: 44,
                    onTap: selectedMinutes > 1
                        ? () => onMinutesChanged(selectedMinutes - step)
                        : null,
                  ),
                  Expanded(
                    child: Pressable(
                      onTap: () => _editMinutes(context),
                      semanticLabel: '$selectedMinutes minutes. Tap to edit',
                      child: Column(
                        children: [
                          Text(
                            '$selectedMinutes',
                            style: theme.displayLarge?.copyWith(
                              fontSize: 72,
                              height: 1.05,
                            ),
                          ),
                          Text('minutes', style: theme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Increase',
                    size: 44,
                    onTap: selectedMinutes < 720
                        ? () => onMinutesChanged(selectedMinutes + step)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in presets)
                    ChoiceChipButton(
                      label: p == remainingToday && remainingToday > 0
                          ? 'Rest of today · ${formatMinutes(p)}'
                          : formatMinutes(p),
                      selected: p == selectedMinutes,
                      color: accent,
                      onTap: () => onMinutesChanged(p),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Plan', style: theme.titleSmall)),
                        Text(
                          'Ends ${formatTimeOfDay(endsAt)}',
                          style: theme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PhaseTimelineWidget(
                      phases: plan.phases,
                      focusColor: accent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      breaks == 0
                          ? 'One ${formatMinutes(selectedMinutes)} block, no breaks'
                          : '$focusBlocks focus blocks, $breaks ${breaks == 1 ? 'break' : 'breaks'} of ${settings.breakDurationMinutes} min',
                      style: theme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Skip breaks', style: theme.bodyMedium),
                        ),
                        Switch(
                          value: skipBreaks,
                          onChanged: onSkipBreaksChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Start focusing',
                icon: Icons.play_arrow_rounded,
                onPressed: onStart,
              ),
              if (isDesktop) ...[
                const SizedBox(height: 10),
                Text(
                  'Space pauses and resumes during a session',
                  textAlign: TextAlign.center,
                  style: theme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({
    super.key,
    required this.goal,
    required this.timerState,
    required this.accent,
    required this.onTogglePause,
    required this.onEnd,
    required this.onMinimize,
  });

  final GoalModel goal;
  final FocusTimerState timerState;
  final Color accent;
  final VoidCallback onTogglePause;
  final void Function(List<SessionPhase> phases, int index, int remaining)
  onEnd;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final (phases, index, remaining, paused, endTime) = switch (timerState) {
      FocusTimerRunningState s => (
        s.phases,
        s.currentPhaseIndex,
        s.remainingSecondsInPhase,
        false,
        s.targetEndTime,
      ),
      FocusTimerPausedState s => (
        s.phases,
        s.currentPhaseIndex,
        s.remainingSecondsInPhase,
        true,
        null,
      ),
      _ => (const <SessionPhase>[], 0, 0, false, null),
    };
    if (phases.isEmpty || index >= phases.length) {
      return const SizedBox.shrink();
    }

    final phase = phases[index];
    final isBreak = phase.type == SessionPhaseType.breakTime;
    final color = isBreak ? AppColors.success : accent;
    final focusTotal = phases
        .where((p) => p.type == SessionPhaseType.focus)
        .length;
    final focusIndex = phases
        .take(index + 1)
        .where((p) => p.type == SessionPhaseType.focus)
        .length;
    final phaseProgress = phase.durationSeconds == 0
        ? 0.0
        : 1 - remaining / phase.durationSeconds;
    final next = index + 1 < phases.length ? phases[index + 1] : null;
    final sessionRemaining =
        remaining +
        phases.skip(index + 1).fold<int>(0, (s, p) => s + p.durationSeconds);
    final sessionEnd = DateTime.now().add(Duration(seconds: sessionRemaining));
    final label = isBreak
        ? 'Break'
        : focusTotal > 1
        ? 'Focus · block $focusIndex of $focusTotal'
        : 'Focus';

    return LayoutBuilder(
      builder: (context, constraints) {
        final ringSize = math
            .min(constraints.maxWidth * 0.7, constraints.maxHeight * 0.42)
            .clamp(180.0, 360.0);
        final gutter = math.max(24.0, (constraints.maxWidth - 480) / 2);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      label,
                      style: theme.bodyMedium?.copyWith(color: color),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressTimer(
                      remainingSeconds: remaining,
                      totalSeconds: phase.durationSeconds,
                      color: color,
                      size: ringSize,
                      paused: paused,
                      endsAt: endTime,
                      caption: 'remaining',
                    ),
                    const SizedBox(height: 24),
                    PhaseTimelineWidget(
                      phases: phases,
                      focusColor: accent,
                      currentPhaseIndex: index,
                      currentPhaseProgress: phaseProgress,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            next == null
                                ? 'Last block'
                                : 'Next: ${next.type == SessionPhaseType.focus ? 'focus' : 'break'} · ${next.labelMinutes} min',
                            style: theme.bodySmall,
                          ),
                        ),
                        Text(
                          paused
                              ? 'Paused'
                              : 'Session ends ${formatTimeOfDay(sessionEnd)}',
                          style: theme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    TimerControls(
                      isPaused: paused,
                      color: color,
                      onPause: onTogglePause,
                      onResume: onTogglePause,
                      onStop: () => onEnd(phases, index, remaining),
                      onMinimize: onMinimize,
                    ),
                    if (goal.motivationalQuote.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        goal.motivationalQuote,
                        textAlign: TextAlign.center,
                        style: theme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
