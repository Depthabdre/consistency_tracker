import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';

class AddEditGoalModal extends StatefulWidget {
  final GoalModel? goal;

  const AddEditGoalModal({super.key, this.goal});

  @override
  State<AddEditGoalModal> createState() => _AddEditGoalModalState();
}

class _AddEditGoalModalState extends State<AddEditGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _quoteController;
  int _targetMinutes = 25;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  String _selectedColor = '#53B5EA';

  final List<String> _colorOptions = [
    '#53B5EA', // Cyan
    '#6366F1', // Indigo
    '#8B5CF6', // Violet
    '#34D399', // Emerald Mint
    '#F59E0B', // Amber
    '#F43F5E', // Coral
  ];

  final List<String> _quotePresets = [
    "You won't regret taking 20 minutes for your future self today.",
    "Consistency transforms average performance into excellence.",
    "Small daily wins compound into massive results over time.",
    "Focus on progress, not perfection.",
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _quoteController = TextEditingController(
      text: widget.goal?.motivationalQuote ?? _quotePresets.first,
    );
    if (widget.goal != null) {
      _targetMinutes = widget.goal!.targetMinutes;
      _reminderHour = widget.goal!.reminderTimeHour;
      _reminderMinute = widget.goal!.reminderTimeMinute;
      _selectedColor = widget.goal!.colorHex;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    return Color(int.parse('ff${hex.replaceFirst('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.goal == null ? 'Set New Target Goal' : 'Edit Target Goal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g. Daily Flutter Code Focus',
                  filled: true,
                  fillColor: AppTheme.backgroundStart,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderOutline),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief detail about your target',
                  filled: true,
                  fillColor: AppTheme.backgroundStart,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderOutline),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Minimum Target Duration Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Minimum Target Duration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_targetMinutes mins/day',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _targetMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: AppTheme.accentCyan,
                inactiveColor: AppTheme.backgroundStart,
                onChanged: (val) => setState(() => _targetMinutes = val.toInt()),
              ),
              const SizedBox(height: 16),

              // Motivational Quote
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Motivational Quote',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final randomQuote = (List.from(_quotePresets)..shuffle()).first;
                      setState(() => _quoteController.text = randomQuote);
                    },
                    icon: const Icon(Icons.shuffle, size: 14, color: AppTheme.accentCyan),
                    label: const Text('Randomize', style: TextStyle(fontSize: 12, color: AppTheme.accentCyan)),
                  ),
                ],
              ),
              TextFormField(
                controller: _quoteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundStart,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderOutline),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Accent Color Picker
              const Text(
                'Color Theme Accent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.black)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save CTA Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _saveGoal,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.goal == null ? 'Create Goal' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = GoalModel(
        id: widget.goal?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetMinutes: _targetMinutes,
        reminderTimeHour: _reminderHour,
        reminderTimeMinute: _reminderMinute,
        motivationalQuote: _quoteController.text.trim(),
        colorHex: _selectedColor,
      );

      Navigator.pop(context, goal);
    }
  }
}
