import 'package:flutter/material.dart';
import 'duration_picker.dart';

class SettingsToggleSwitch extends StatelessWidget {
  const SettingsToggleSwitch({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.icon = Icons.toggle_on_outlined,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SettingsIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.titleSmall),
                    const SizedBox(height: 2),
                    Text(description, style: theme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
