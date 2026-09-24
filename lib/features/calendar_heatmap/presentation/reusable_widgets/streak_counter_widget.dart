import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';

/// Goal statistics: a 2×2 grid, or a single row when [inline].
class StreakCounterWidget extends StatelessWidget {
  const StreakCounterWidget({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.totalFocus,
    this.inline = false,
  });

  final int currentStreak;
  final int bestStreak;
  final String completionRate;
  final String totalFocus;
  final bool inline;

  String _days(int n) => '$n ${n == 1 ? 'day' : 'days'}';

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatBlock(value: _days(currentStreak), label: 'Current streak'),
      StatBlock(value: _days(bestStreak), label: 'Best streak'),
      StatBlock(value: completionRate, label: 'Last 30 days'),
      StatBlock(value: totalFocus, label: 'Total focus'),
    ];

    if (inline) return StatRow(stats: stats);

    Widget cell(StatBlock s) => Expanded(
      child: Padding(padding: const EdgeInsets.all(14), child: s),
    );
    Widget pair(int i) => IntrinsicHeight(
      child: Row(
        children: [
          cell(stats[i]),
          const VerticalDivider(width: 1),
          cell(stats[i + 1]),
        ],
      ),
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [pair(0), const Divider(), pair(2)]),
    );
  }
}
