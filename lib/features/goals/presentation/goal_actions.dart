import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../notifications/data/repositories/notification_repository.dart';
import '../data/models/goal_model.dart';
import 'bloc/goal_bloc.dart';
import 'bloc/goal_event.dart';
import 'bloc/goal_state.dart';
import 'pages/add_edit_goal_page.dart';

bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 720;

/// Opens the goal editor (dialog on wide screens, sheet on phones) and
/// dispatches the add/update.
Future<void> openGoalEditor(BuildContext context, {GoalModel? goal}) async {
  final GoalModel? result;
  if (_isWide(context)) {
    result = await showDialog<GoalModel>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: AddEditGoalModal(goal: goal),
        ),
      ),
    );
  } else {
    result = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: AddEditGoalModal(goal: goal),
      ),
    );
  }
  if (result == null || !context.mounted) return;
  context.read<GoalBloc>().add(
    goal == null ? AddGoalEvent(result) : UpdateGoalEvent(result),
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          goal == null ? '“${result.title}” created' : 'Changes saved',
        ),
      ),
    );
  if (goal == null) await _ensureNotificationPermission(context);
}

/// Asks for notification permission the first time it matters. The OS only
/// shows its prompt once; afterwards this just reads the current state.
Future<void> _ensureNotificationPermission(BuildContext context) async {
  NotificationRepository? repo;
  try {
    repo = context.read<NotificationRepository>();
  } catch (_) {
    return;
  }
  if (await repo.hasPermission() == true) return;
  await repo.requestPermission();
}

/// Deletes a goal immediately and offers an undo that restores its history.
void deleteGoalWithUndo(BuildContext context, GoalModel goal) {
  final bloc = context.read<GoalBloc>();
  final state = bloc.state;
  final history = state is GoalLoadedState
      ? List<CalendarDayModel>.of(state.entriesFor(goal.id))
      : <CalendarDayModel>[];
  bloc.add(DeleteGoalEvent(goal.id));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('“${goal.title}” deleted'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => bloc.add(RestoreGoalEvent(goal, history)),
        ),
      ),
    );
}

/// Goal-level actions: a menu anchored to [anchor] when given, else a sheet.
Future<void> showGoalActions(
  BuildContext context, {
  required GoalModel goal,
  required VoidCallback onOpenHistory,
  BuildContext? anchor,
}) async {
  final actions = <(String, IconData, VoidCallback, bool)>[
    ('View history', Icons.calendar_month_outlined, onOpenHistory, false),
    (
      'Edit',
      Icons.edit_outlined,
      () => openGoalEditor(context, goal: goal),
      false,
    ),
    (
      'Delete',
      Icons.delete_outline_rounded,
      () => deleteGoalWithUndo(context, goal),
      true,
    ),
  ];

  Widget row((String, IconData, VoidCallback, bool) a) {
    final color = a.$4 ? AppColors.danger : AppColors.textPrimary;
    return Row(
      children: [
        Icon(a.$2, size: 18, color: a.$4 ? color : AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(a.$1, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }

  if (anchor != null) {
    final box = anchor.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box != null && overlay != null) {
      final position = RelativeRect.fromRect(
        Rect.fromPoints(
          box.localToGlobal(
            box.size.bottomLeft(Offset.zero),
            ancestor: overlay,
          ),
          box.localToGlobal(
            box.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );
      final index = await showMenu<int>(
        context: context,
        position: position,
        items: [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem(value: i, height: 40, child: row(actions[i])),
        ],
      );
      if (index != null) actions[index].$3();
      return;
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                title: row(a),
                onTap: () {
                  Navigator.pop(sheetContext);
                  a.$3();
                },
              ),
          ],
        ),
      ),
    ),
  );
}
