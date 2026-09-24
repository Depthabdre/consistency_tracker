import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../calendar_heatmap/domain/streak_calculator.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import '../../../calendar_heatmap/presentation/bloc/calendar_event.dart';
import '../../../calendar_heatmap/presentation/pages/consistency_calendar_page.dart';
import '../../../focus_timer/domain/entities/session_phase.dart';
import '../../../focus_timer/presentation/bloc/focus_timer_bloc.dart';
import '../../../focus_timer/presentation/bloc/focus_timer_event.dart';
import '../../../focus_timer/presentation/bloc/focus_timer_state.dart';
import '../../../focus_timer/presentation/pages/focus_timer_page.dart';
import '../../../focus_timer/presentation/reusable_widgets/session_complete_dialog.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../../goals/presentation/goal_actions.dart';
import '../../../goals/presentation/pages/goals_list_page.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey _pagesKey = GlobalKey();
  DateTime _loadedDay = dayOnly(DateTime.now());
  bool _remindersSynced = false;
  bool? _lastEscalationSetting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame so the completion listener is already attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FocusTimerBloc>().add(const RestoreFocusTimerEvent());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh "today" progress when the app is reopened on a new day.
    if (state == AppLifecycleState.resumed &&
        !isSameDay(_loadedDay, DateTime.now())) {
      _loadedDay = dayOnly(DateTime.now());
      context.read<GoalBloc>().add(const LoadGoalsEvent());
    }
  }

  T? _maybeRead<T>() {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  GoalModel? _findGoal(String id) {
    final state = context.read<GoalBloc>().state;
    if (state is! GoalLoadedState) return null;
    return state.goals.where((g) => g.id == id).firstOrNull;
  }

  String? _activeGoalId(FocusTimerState state) => switch (state) {
    FocusTimerRunningState s => s.goalId,
    FocusTimerPausedState s => s.goalId,
    _ => null,
  };

  // ---------------------------------------------------------------- Navigation

  void _openFocus(GoalModel goal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FocusTimerPage(goal: goal)));
  }

  void _startFocus(GoalModel goal) {
    final activeId = _activeGoalId(context.read<FocusTimerBloc>().state);
    final activeGoal = activeId == null ? null : _findGoal(activeId);
    if (activeGoal == null || activeGoal.id == goal.id) {
      _openFocus(goal);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('A session is running'),
        content: Text(
          'You’re focusing on “${activeGoal.title}”. Finish or end it before starting “${goal.title}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openFocus(activeGoal);
            },
            child: const Text('Open session'),
          ),
        ],
      ),
    );
  }

  void _openHistory(GoalModel goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConsistencyCalendarPage(goal: goal, onStartFocus: _startFocus),
      ),
    );
  }

  // ------------------------------------------------------------------- Logic

  Future<void> _syncReminders(GoalLoadedState state) async {
    final repo = _maybeRead<NotificationRepository>();
    if (repo == null) return;
    final settings = context.read<SettingsBloc>().state;
    final escalation = settings is SettingsLoaded
        ? settings.settings.escalationRemindersEnabled
        : null;
    for (final goal in state.goals) {
      final doneToday = state.todayMinutesFor(goal.id) >= goal.targetMinutes;
      await repo.cancelGoalReminders(goal.id);
      await repo.scheduleGoalReminders(
        goal,
        skipToday: doneToday,
        includeEscalation: escalation,
      );
    }
  }

  Future<void> _handleSessionCompleted(FocusTimerCompletedState s) async {
    final messenger = ScaffoldMessenger.of(context);
    final goalBloc = context.read<GoalBloc>();
    if (goalBloc.state is! GoalLoadedState) {
      await goalBloc.stream.firstWhere(
        (st) => st is GoalLoadedState || st is GoalErrorState,
      );
      if (!mounted) return;
    }
    final goal = _findGoal(s.goalId);
    if (goal == null) return;

    if (s.totalMinutesCompleted <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ended in under a minute — nothing was logged.'),
        ),
      );
      return;
    }

    final result = await context
        .read<CalendarRepository>()
        .addFocusMinutesToToday(
          goalId: goal.id,
          targetMinutes: goal.targetMinutes,
          minutesToAdd: s.totalMinutesCompleted,
        );
    if (!mounted) return;

    final day = result.fold(
      onSuccess: (d) => d,
      onFailure: (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return null;
      },
    );
    if (day == null) return;

    goalBloc.add(
      UpdateGoalProgressEvent(
        goalId: goal.id,
        todayMinutes: day.totalMinutesFocused,
      ),
    );
    _maybeRead<CalendarBloc>()?.add(LoadCalendarEntriesEvent(goal.id));

    if (day.isCompleted) {
      // Silence today's remaining reminders but keep tomorrow's.
      final repo = _maybeRead<NotificationRepository>();
      if (repo != null) {
        final settings = context.read<SettingsBloc>().state;
        await repo.cancelGoalReminders(goal.id);
        await repo.scheduleGoalReminders(
          goal,
          skipToday: true,
          includeEscalation: settings is SettingsLoaded
              ? settings.settings.escalationRemindersEnabled
              : null,
        );
      }
    }
    if (!mounted) return;

    final loaded = goalBloc.state;
    final history = [
      if (loaded is GoalLoadedState)
        ...loaded
            .entriesFor(goal.id)
            .where((e) => !isSameDay(e.date, day.date)),
      day,
    ];

    await showSessionCompleteDialog(
      context,
      goal: goal,
      sessionMinutes: s.totalMinutesCompleted,
      todayMinutes: day.totalMinutesFocused,
      targetMet: day.isCompleted,
      streak: calculateCurrentStreak(
        history,
        activeWeekdays: goal.activeWeekdays,
      ),
    );
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FocusTimerBloc, FocusTimerState>(
          listenWhen: (_, curr) => curr is FocusTimerCompletedState,
          listener: (_, state) =>
              _handleSessionCompleted(state as FocusTimerCompletedState),
        ),
        BlocListener<GoalBloc, GoalState>(
          listenWhen: (_, curr) => curr is GoalLoadedState && !_remindersSynced,
          listener: (_, state) {
            _remindersSynced = true;
            _syncReminders(state as GoalLoadedState);
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (_, curr) => curr is SettingsLoaded,
          listener: (_, state) {
            final enabled =
                (state as SettingsLoaded).settings.escalationRemindersEnabled;
            final previous = _lastEscalationSetting;
            _lastEscalationSetting = enabled;
            final goals = context.read<GoalBloc>().state;
            if (previous != null &&
                previous != enabled &&
                goals is GoalLoadedState) {
              _syncReminders(goals);
            }
          },
        ),
      ],
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              openGoalEditor(context),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              openGoalEditor(context),
          for (final (i, key) in const [
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
          ].indexed) ...{
            SingleActivator(key, meta: true): () =>
                setState(() => _currentIndex = i),
            SingleActivator(key, control: true): () =>
                setState(() => _currentIndex = i),
          },
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pages = IndexedStack(
                key: _pagesKey,
                index: _currentIndex,
                children: [
                  GoalsListPage(
                    onStartFocus: _startFocus,
                    onViewCalendar: _openHistory,
                  ),
                  AnalyticsPage(onOpenGoal: _openHistory),
                  const SettingsPage(),
                ],
              );
              void select(int i) => setState(() => _currentIndex = i);

              if (constraints.maxWidth >= 900) {
                return Scaffold(
                  backgroundColor: AppColors.background,
                  body: Row(
                    children: [
                      _Sidebar(
                        currentIndex: _currentIndex,
                        onSelect: select,
                        live: _LiveSessionBar(
                          onOpen: _openFocus,
                          findGoal: _findGoal,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: pages),
                    ],
                  ),
                );
              }

              return Scaffold(
                backgroundColor: AppColors.background,
                body: pages,
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _LiveSessionBar(
                        onOpen: _openFocus,
                        findGoal: _findGoal,
                      ),
                    ),
                    _BottomNavBar(
                      currentIndex: _currentIndex,
                      onSelect: select,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navItems = [
  _NavItem('Today', Icons.today_outlined, Icons.today_rounded),
  _NavItem('Insights', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
];

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                Expanded(
                  child: Pressable(
                    onTap: () => onSelect(i),
                    pressedScale: 0.95,
                    semanticLabel: _navItems[i].label,
                    child: _NavContent(
                      item: _navItems[i],
                      selected: i == currentIndex,
                      vertical: true,
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentIndex,
    required this.onSelect,
    required this.live,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    return SizedBox(
      width: 232,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Text('Consistency', style: theme.titleMedium),
              ),
              for (var i = 0; i < _navItems.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Pressable(
                    onTap: () => onSelect(i),
                    pressedScale: 1,
                    semanticLabel: _navItems[i].label,
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: i == currentIndex
                            ? AppColors.surfaceHigh
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavContent(
                              item: _navItems[i],
                              selected: i == currentIndex,
                              vertical: false,
                            ),
                          ),
                          Text(
                            '${isMac ? '⌘' : 'Ctrl '}${i + 1}',
                            style: theme.bodySmall?.copyWith(
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              live,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavContent extends StatelessWidget {
  const _NavContent({
    required this.item,
    required this.selected,
    required this.vertical,
  });

  final _NavItem item;
  final bool selected;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;
    final icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: vertical ? 22 : 18,
      color: selected && vertical ? AppColors.primary : color,
    );
    final label = Text(
      item.label,
      style: TextStyle(
        fontSize: vertical ? 11.5 : 13.5,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: color,
      ),
    );
    if (vertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(height: 3), label],
      );
    }
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Flexible(child: label),
      ],
    );
  }
}

/// Persistent "now focusing" bar so a running session is never lost.
class _LiveSessionBar extends StatelessWidget {
  const _LiveSessionBar({required this.onOpen, required this.findGoal});

  final ValueChanged<GoalModel> onOpen;
  final GoalModel? Function(String id) findGoal;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusTimerBloc, FocusTimerState>(
      builder: (context, state) {
        final (goalId, remaining, paused, isBreak) = switch (state) {
          FocusTimerRunningState s => (
            s.goalId,
            s.remainingSecondsInPhase,
            false,
            s.currentPhase?.type == SessionPhaseType.breakTime,
          ),
          FocusTimerPausedState s => (
            s.goalId,
            s.remainingSecondsInPhase,
            true,
            s.currentPhase?.type == SessionPhaseType.breakTime,
          ),
          _ => (null, 0, false, false),
        };
        final goal = goalId == null ? null : findGoal(goalId);

        return AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          child: goal == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LiveSessionContent(
                    goal: goal,
                    remaining: remaining,
                    paused: paused,
                    isBreak: isBreak,
                    onOpen: () => onOpen(goal),
                  ),
                ),
        );
      },
    );
  }
}

class _LiveSessionContent extends StatelessWidget {
  const _LiveSessionContent({
    required this.goal,
    required this.remaining,
    required this.paused,
    required this.isBreak,
    required this.onOpen,
  });

  final GoalModel goal;
  final int remaining;
  final bool paused;
  final bool isBreak;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = isBreak ? AppColors.success : colorFromHex(goal.colorHex);
    final status = paused ? 'Paused' : (isBreak ? 'Break' : 'Focusing');
    return AppCard(
      onTap: onOpen,
      semanticLabel: 'Open running session for ${goal.title}',
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      radius: AppRadii.md,
      color: AppColors.surfaceRaised,
      child: Row(
        children: [
          Icon(
            paused ? Icons.pause_circle_outline_rounded : Icons.timer_outlined,
            size: 20,
            color: paused ? AppColors.warning : accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$status · ${formatClock(remaining)} left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            tooltip: paused ? 'Resume' : 'Pause',
            size: 36,
            onTap: () => context.read<FocusTimerBloc>().add(
              paused
                  ? const ResumeFocusTimerEvent()
                  : const PauseFocusTimerEvent(),
            ),
          ),
        ],
      ),
    );
  }
}
