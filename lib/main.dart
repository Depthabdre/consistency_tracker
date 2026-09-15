import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';

// Goals Feature
import 'features/goals/data/datasources/goal_local_datasource.dart';
import 'features/goals/data/repositories/goal_repository.dart';
import 'features/goals/presentation/bloc/goal_bloc.dart';
import 'features/goals/presentation/bloc/goal_event.dart';

import 'features/navigation/presentation/pages/main_navigation_shell.dart';

// Focus Timer Feature
import 'features/focus_timer/data/datasources/focus_session_local_datasource.dart';
import 'features/focus_timer/data/repositories/focus_session_repository.dart';
import 'features/focus_timer/presentation/bloc/focus_timer_bloc.dart';

// Calendar Heatmap Feature
import 'features/calendar_heatmap/data/datasources/calendar_local_datasource.dart';
import 'features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'features/calendar_heatmap/presentation/bloc/calendar_bloc.dart';

// Notifications Feature
import 'features/notifications/data/datasources/notification_local_datasource.dart';
import 'features/notifications/data/repositories/notification_repository.dart';

// Settings Feature
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';

import 'core/services/email_service.dart';

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
  final settingsLocalDataSource = SettingsLocalDataSourceImpl(
    settingsBox: settingsBox,
  );

  // Initialize Local Notifications
  await notificationLocalDataSource.initialize();

  // Instantiate Repositories and Services
  final goalRepository = GoalRepositoryImpl(
    localDataSource: goalLocalDataSource,
  );
  final focusSessionRepository = FocusSessionRepositoryImpl(
    localDataSource: focusSessionLocalDataSource,
  );
  final calendarRepository = CalendarRepositoryImpl(
    localDataSource: calendarLocalDataSource,
  );
  final notificationRepository = NotificationRepositoryImpl(
    localDataSource: notificationLocalDataSource,
  );
  final settingsRepository = SettingsRepositoryImpl(
    localDataSource: settingsLocalDataSource,
  );
  final emailService = EmailServiceImpl(settingsBox: settingsBox);

  runApp(
    ConsistencyTrackerApp(
      goalRepository: goalRepository,
      focusSessionRepository: focusSessionRepository,
      calendarRepository: calendarRepository,
      notificationRepository: notificationRepository,
      settingsRepository: settingsRepository,
      emailService: emailService,
    ),
  );
}

class ConsistencyTrackerApp extends StatelessWidget {
  final GoalRepository goalRepository;
  final FocusSessionRepository focusSessionRepository;
  final CalendarRepository calendarRepository;
  final NotificationRepository notificationRepository;
  final SettingsRepository settingsRepository;
  final EmailService? emailService;

  const ConsistencyTrackerApp({
    super.key,
    required this.goalRepository,
    required this.focusSessionRepository,
    required this.calendarRepository,
    required this.notificationRepository,
    required this.settingsRepository,
    this.emailService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEmailService = emailService ?? EmailServiceImpl();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GoalRepository>.value(value: goalRepository),
        RepositoryProvider<FocusSessionRepository>.value(
          value: focusSessionRepository,
        ),
        RepositoryProvider<CalendarRepository>.value(value: calendarRepository),
        RepositoryProvider<NotificationRepository>.value(
          value: notificationRepository,
        ),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<EmailService>.value(value: effectiveEmailService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GoalBloc>(
            create: (context) => GoalBloc(
              goalRepository: goalRepository,
              notificationRepository: notificationRepository,
              calendarRepository: calendarRepository,
            )..add(const LoadGoalsEvent()),
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
                SettingsBloc(repository: settingsRepository)
                  ..add(const LoadSettingsEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Consistency Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const MainNavigationShell(),
        ),
      ),
    );
  }
}
