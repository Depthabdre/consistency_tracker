import 'package:flutter/material.dart';

class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.label,
    required this.valueMinutes,
    required this.minMinutes,
    required this.maxMinutes,
    required this.onChanged,
  });

  final String label;
  final int valueMinutes;
  final int minMinutes;
  final int maxMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF33353C),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          IconButton(
            onPressed: valueMinutes > minMinutes
                ? () => onChanged(valueMinutes - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF53B5EA)),
          ),
          Text(
            '$valueMinutes min',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFF2F4F8),
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: valueMinutes < maxMinutes
                ? () => onChanged(valueMinutes + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF53B5EA)),
          ),
        ],
      ),
    );
  }
}
