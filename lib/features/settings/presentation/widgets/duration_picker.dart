import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

/// Row with a compact − value + stepper.
class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.label,
    required this.valueMinutes,
    required this.minMinutes,
    required this.maxMinutes,
    required this.onChanged,
    this.icon = Icons.timer_outlined,
    this.step = 1,
    this.description,
  });

  final String label;
  final String? description;
  final IconData icon;
  final int valueMinutes;
  final int minMinutes;
  final int maxMinutes;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
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
                if (description != null)
                  Text(description!, style: theme.bodySmall),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.remove_rounded,
            tooltip: 'Decrease $label',
            size: 32,
            onTap: valueMinutes > minMinutes
                ? () => onChanged(
                    (valueMinutes - step).clamp(minMinutes, maxMinutes),
                  )
                : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$valueMinutes min',
              textAlign: TextAlign.center,
              style: theme.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Increase $label',
            size: 32,
            onTap: valueMinutes < maxMinutes
                ? () => onChanged(
                    (valueMinutes + step).clamp(minMinutes, maxMinutes),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }
}
