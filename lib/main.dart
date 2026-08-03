import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';

// Goals Feature
import 'features/goals/data/datasources/goal_local_datasource.dart';
import 'features/goals/data/models/goal_model.dart';
import 'features/goals/data/repositories/goal_repository.dart';
import 'features/goals/presentation/bloc/goal_bloc.dart';
import 'features/goals/presentation/bloc/goal_event.dart';
import 'features/goals/presentation/pages/goals_list_page.dart';

// Focus Timer Feature
import 'features/focus_timer/data/datasources/focus_session_local_datasource.dart';
import 'features/focus_timer/data/repositories/focus_session_repository.dart';
import 'features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'features/focus_timer/presentation/pages/focus_timer_page.dart';

// Calendar Heatmap Feature
import 'features/calendar_heatmap/data/datasources/calendar_local_datasource.dart';
import 'features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'features/calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import 'features/calendar_heatmap/presentation/pages/consistency_calendar_page.dart';

// Notifications Feature
import 'features/notifications/data/datasources/notification_local_datasource.dart';
import 'features/notifications/data/repositories/notification_repository.dart';

// Settings Feature
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Offline Database
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox('settings_box');

  // Instantiate Local Datasources
  final goalLocalDataSource = GoalLocalDataSourceImpl();
  final focusSessionLocalDataSource = FocusSessionLocalDataSourceImpl();
  final calendarLocalDataSource = CalendarLocalDataSourceImpl();
  final notificationLocalDataSource = NotificationLocalDataSourceImpl();
  final settingsLocalDataSource = SettingsLocalDataSourceImpl(settingsBox: settingsBox);

  // Initialize Local Notifications
  await notificationLocalDataSource.initialize();

  // Instantiate Repositories
  final goalRepository = GoalRepositoryImpl(localDataSource: goalLocalDataSource);
  final focusSessionRepository =
      FocusSessionRepositoryImpl(localDataSource: focusSessionLocalDataSource);
  final calendarRepository =
      CalendarRepositoryImpl(localDataSource: calendarLocalDataSource);
  final notificationRepository =
      NotificationRepositoryImpl(localDataSource: notificationLocalDataSource);
  final settingsRepository =
      SettingsRepositoryImpl(localDataSource: settingsLocalDataSource);

  runApp(ConsistencyTrackerApp(
    goalRepository: goalRepository,
    focusSessionRepository: focusSessionRepository,
    calendarRepository: calendarRepository,
    notificationRepository: notificationRepository,
    settingsRepository: settingsRepository,
  ));
}

class ConsistencyTrackerApp extends StatelessWidget {
  final GoalRepository goalRepository;
  final FocusSessionRepository focusSessionRepository;
  final CalendarRepository calendarRepository;
  final NotificationRepository notificationRepository;
  final SettingsRepository settingsRepository;

  const ConsistencyTrackerApp({
    super.key,
    required this.goalRepository,
    required this.focusSessionRepository,
    required this.calendarRepository,
    required this.notificationRepository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GoalRepository>.value(value: goalRepository),
        RepositoryProvider<FocusSessionRepository>.value(value: focusSessionRepository),
        RepositoryProvider<CalendarRepository>.value(value: calendarRepository),
        RepositoryProvider<NotificationRepository>.value(value: notificationRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GoalBloc>(
            create: (context) =>
                GoalBloc(goalRepository: goalRepository)..add(const LoadGoalsEvent()),
          ),
          BlocProvider<FocusTimerBloc>(
            create: (context) =>
                FocusTimerBloc(sessionRepository: focusSessionRepository),
          ),
          BlocProvider<CalendarBloc>(
            create: (context) =>
                CalendarBloc(calendarRepository: calendarRepository),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) =>
                SettingsBloc(repository: settingsRepository)..add(const LoadSettingsEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Consistency Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const MainNavigationHostPage(),
        ),
      ),
    );
  }
}

class MainNavigationHostPage extends StatefulWidget {
  const MainNavigationHostPage({super.key});

  @override
  State<MainNavigationHostPage> createState() => _MainNavigationHostPageState();
}

class _MainNavigationHostPageState extends State<MainNavigationHostPage> {
  @override
  Widget build(BuildContext context) {
    return GoalsListPage(
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
    );
  }
}
