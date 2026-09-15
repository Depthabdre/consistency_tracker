import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../calendar_heatmap/presentation/pages/consistency_calendar_page.dart';
import '../../../focus_timer/presentation/pages/focus_timer_page.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/pages/goals_list_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GoalsListPage(
            onStartFocus: (GoalModel goal) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FocusTimerPage(goal: goal),
                ),
              );
            },
            onViewCalendar: (GoalModel goal) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsistencyCalendarPage(goal: goal),
                ),
              );
            },
          ),
          const AnalyticsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border(
            top: BorderSide(color: AppTheme.borderOutline, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded),
              label: 'Targets',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
