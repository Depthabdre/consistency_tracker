import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/reminder_time_model.dart';
import '../../domain/goal_suggestions.dart';

enum _TargetUnit { minutes, hours }

class AddEditGoalModal extends StatefulWidget {
  final GoalModel? goal;

  const AddEditGoalModal({super.key, this.goal});

  @override
  State<AddEditGoalModal> createState() => _AddEditGoalModalState();
}

class _AddEditGoalModalState extends State<AddEditGoalModal> {
  static const int _maxTargetMinutes = 12 * 60;
  static const List<int> _targetPresets = [10, 15, 20, 30, 45, 60, 90, 120];

  static const List<String> _notePresets = [
    'You won’t regret the minutes you give your future self.',
    'Consistency beats intensity.',
    'Small daily wins compound.',
    'Progress, not perfection.',
    'Just start. Five minutes counts.',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descriptionFocus = FocusNode();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late final TextEditingController _targetController;
  late _TargetUnit _unit;
  late List<ReminderTimeModel> _reminderTimes;
  late String _selectedColor;
  late Set<int> _weekdays;
  bool _targetEdited = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    _noteController = TextEditingController(
      text: goal?.motivationalQuote ?? _notePresets.first,
    );
    final minutes = goal?.targetMinutes ?? 30;
    _unit = minutes >= 60 && minutes % 30 == 0
        ? _TargetUnit.hours
        : _TargetUnit.minutes;
    _targetController = TextEditingController(text: _format(minutes, _unit));
    _targetEdited = goal != null;
    _reminderTimes = goal == null
        ? [const ReminderTimeModel(hour: 9, minute: 0)]
        : _sorted(goal.activeReminderTimes);
    _selectedColor =
        goal?.colorHex.toUpperCase() ?? AppColors.goalPalette.first;
    _weekdays = (goal?.activeWeekdays ?? GoalModel.everyDay).toSet();
    _titleController.addListener(_rebuild);
    _descriptionController.addListener(_rebuild);
    _targetController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _targetController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ Daily target

  static String _format(int minutes, _TargetUnit unit) {
    if (unit == _TargetUnit.minutes) return '$minutes';
    final hours = minutes / 60;
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  /// Parsed target in minutes, or null when invalid.
  int? get _targetMinutes {
    final raw = _targetController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    final minutes = _unit == _TargetUnit.hours
        ? (value * 60).round()
        : value.round();
    if (minutes < 1 || minutes > _maxTargetMinutes) return null;
    return minutes;
  }

  void _setTarget(int minutes, {bool userEdit = true}) {
    final unit = minutes >= 60 && minutes % 30 == 0
        ? _TargetUnit.hours
        : _TargetUnit.minutes;
    setState(() {
      _unit = unit;
      _targetController.text = _format(minutes, unit);
      if (userEdit) _targetEdited = true;
    });
  }

  void _switchUnit(_TargetUnit unit) {
    if (unit == _unit) return;
    final current = _targetMinutes;
    setState(() {
      _unit = unit;
      if (current != null) _targetController.text = _format(current, unit);
    });
  }

  // ------------------------------------------------------------- Suggestions

  void _applyTitle(GoalTemplate template) {
    _titleController.text = template.title;
    _titleController.selection = TextSelection.collapsed(
      offset: template.title.length,
    );
    if (!_targetEdited) _setTarget(template.minutes, userEdit: false);
    _descriptionFocus.requestFocus();
  }

  void _applyDescription(String text) {
    _descriptionController.text = text;
    _descriptionController.selection = TextSelection.collapsed(
      offset: text.length,
    );
  }

  // --------------------------------------------------------------- Reminders

  List<ReminderTimeModel> _sorted(List<ReminderTimeModel> list) => List.of(
    list,
  )..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

  Future<void> _addReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    final time = ReminderTimeModel(hour: picked.hour, minute: picked.minute);
    if (_reminderTimes.contains(time)) return;
    setState(() => _reminderTimes = _sorted([..._reminderTimes, time]));
  }

  Future<void> _editReminderTime(int index) async {
    final current = _reminderTimes[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    final time = ReminderTimeModel(hour: picked.hour, minute: picked.minute);
    setState(() {
      final updated = List.of(_reminderTimes)..removeAt(index);
      if (!updated.contains(time)) updated.add(time);
      _reminderTimes = _sorted(updated);
    });
  }

  // -------------------------------------------------------------------- Save

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _targetMinutes != null;

  String get _saveHint => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => '⌘ Enter to save',
    TargetPlatform.windows || TargetPlatform.linux => 'Ctrl Enter to save',
    _ => '',
  };

  void _save() {
    if (!_canSave || !_formKey.currentState!.validate()) return;
    final first = _reminderTimes.first;
    Navigator.pop(
      context,
      GoalModel(
        id: widget.goal?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetMinutes: _targetMinutes!,
        reminderTimeHour: first.hour,
        reminderTimeMinute: first.minute,
        reminderTimes: _reminderTimes,
        motivationalQuote: _noteController.text.trim(),
        colorHex: _selectedColor,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        isActive: widget.goal?.isActive ?? true,
        activeWeekdays: _weekdays.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final accent = colorFromHex(_selectedColor);
    final title = _titleController.text;
    final titleIdeas = titleSuggestions(title);
    final descriptionIdeas = descriptionSuggestions(
      title,
    ).where((d) => d != _descriptionController.text.trim()).toList();
    final target = _targetMinutes;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit goal' : 'New goal',
                      style: theme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _descriptionFocus.requestFocus(),
                        style: theme.titleMedium,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Reading',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Give your goal a name'
                            : null,
                      ),
                      _SuggestionRow(
                        visible: !_isEditing && titleIdeas.isNotEmpty,
                        children: [
                          for (final t in titleIdeas)
                            ChoiceChipButton(
                              label: t.title,
                              onTap: () => _applyTitle(t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'What does a good day look like?',
                        ),
                      ),
                      _SuggestionRow(
                        visible:
                            descriptionIdeas.isNotEmpty &&
                            _descriptionController.text.trim().isEmpty,
                        children: [
                          for (final d in descriptionIdeas)
                            ChoiceChipButton(
                              label: d,
                              icon: Icons.add_rounded,
                              onTap: () => _applyDescription(d),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionLabel('Daily minimum'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _targetController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              onChanged: (_) => _targetEdited = true,
                              style: theme.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: SegmentedPills<_TargetUnit>(
                                height: 42,
                                value: _unit,
                                onChanged: _switchUnit,
                                options: const [
                                  (_TargetUnit.minutes, 'Minutes'),
                                  (_TargetUnit.hours, 'Hours'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        target == null
                            ? 'Enter between 1 minute and 12 hours.'
                            : _weekdays.length == 7
                            ? '${formatMinutes(target)} every day'
                            : '${formatMinutes(target)} on each scheduled day',
                        style: theme.bodySmall?.copyWith(
                          color: target == null
                              ? AppColors.danger
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in _targetPresets)
                            ChoiceChipButton(
                              label: formatMinutes(p),
                              selected: target == p,
                              color: accent,
                              onTap: () => _setTarget(p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _RepeatPicker(
                        selected: _weekdays,
                        color: accent,
                        onChanged: (days) => setState(() => _weekdays = days),
                      ),
                      const SizedBox(height: 24),
                      SectionLabel(
                        'Reminders',
                        trailing: TextButton.icon(
                          onPressed: _reminderTimes.length >= 5
                              ? null
                              : _addReminderTime,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add time'),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < _reminderTimes.length; i++)
                            InputChip(
                              avatar: const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              label: Text(_reminderTimes[i].formattedTime),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                              onPressed: () => _editReminderTime(i),
                              onDeleted: _reminderTimes.length > 1
                                  ? () => setState(
                                      () => _reminderTimes = List.of(
                                        _reminderTimes,
                                      )..removeAt(i),
                                    )
                                  : null,
                              deleteButtonTooltipMessage: 'Remove reminder',
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily nudges until the target is met. Tap a time to change it.',
                        style: theme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      const SectionLabel('Color'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final hex in AppColors.goalPalette)
                            _ColorSwatch(
                              color: colorFromHex(hex),
                              selected: _selectedColor == hex,
                              onTap: () => setState(() => _selectedColor = hex),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionLabel(
                        'Note to self',
                        trailing: TextButton(
                          onPressed: () {
                            final options = List.of(_notePresets)
                              ..remove(_noteController.text)
                              ..shuffle();
                            setState(
                              () => _noteController.text = options.first,
                            );
                          },
                          child: const Text('Suggest another'),
                        ),
                      ),
                      TextFormField(
                        controller: _noteController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Shown while you focus',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    Expanded(child: Text(_saveHint, style: theme.bodySmall)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: _isEditing ? 'Save' : 'Create goal',
                      height: 44,
                      onPressed: _canSave ? _save : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal suggestion chips shown under a field.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.visible, required this.children});

  final bool visible;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topLeft,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: children),
            ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: selected ? 'Selected color' : 'Color option',
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Weekday toggles; unselected days are rest days.
class _RepeatPicker extends StatelessWidget {
  const _RepeatPicker({
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final Set<int> selected;
  final Color color;
  final ValueChanged<Set<int>> onChanged;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdays = {1, 2, 3, 4, 5};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final everyDay = selected.length == 7;
    final weekdaysOnly =
        selected.length == 5 && selected.containsAll(_weekdays);

    void toggle(int day) {
      final next = Set.of(selected);
      if (!next.remove(day)) next.add(day);
      if (next.isNotEmpty) onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'Repeat',
          trailing: Wrap(
            spacing: 6,
            children: [
              ChoiceChipButton(
                label: 'Every day',
                selected: everyDay,
                color: color,
                onTap: () => onChanged({1, 2, 3, 4, 5, 6, 7}),
              ),
              ChoiceChipButton(
                label: 'Weekdays',
                selected: weekdaysOnly,
                color: color,
                onTap: () => onChanged(Set.of(_weekdays)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (var d = 1; d <= 7; d++) ...[
              if (d > 1) const SizedBox(width: 6),
              Expanded(
                child: Pressable(
                  onTap: () => toggle(d),
                  pressedScale: 0.94,
                  semanticLabel:
                      '${_names[d - 1]}, ${selected.contains(d) ? 'scheduled' : 'rest day'}',
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected.contains(d)
                          ? color.withValues(alpha: 0.16)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: selected.contains(d) ? color : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _names[d - 1],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: selected.contains(d)
                            ? color
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          everyDay
              ? 'Tap a day to make it a rest day.'
              : 'Rest days don’t break your streak.',
          style: theme.bodySmall,
        ),
      ],
    );
  }
}
