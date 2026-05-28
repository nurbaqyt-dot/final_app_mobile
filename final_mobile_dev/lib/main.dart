import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/task_provider.dart';
import 'router/app_router.dart';
import 'services/ai_planner_service.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/preferences_service.dart';
import 'services/storage_service.dart';
import 'services/task_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ru_RU';

  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(sharedPreferences);

  await FirebaseBootstrap.initialize();

  final authService = AuthService(preferencesService: preferencesService);
  final authProvider = AuthProvider(
    authService: authService,
    preferencesService: preferencesService,
  );
  await authProvider.initialize();

  final eventProvider = EventProvider(
    service: EventService(preferencesService: preferencesService),
    authProvider: authProvider,
  );
  final taskProvider = TaskProvider(
    service: TaskService(preferencesService: preferencesService),
    authProvider: authProvider,
  );
  final planProvider = PlanProvider(service: AiPlannerService());
  final profileProvider = ProfileProvider(
    storageService: StorageService(),
    authProvider: authProvider,
  );

  final routerConfig = AppRouter(authProvider).router;

  runApp(
    FlowDayApp(
      authProvider: authProvider,
      eventProvider: eventProvider,
      taskProvider: taskProvider,
      planProvider: planProvider,
      profileProvider: profileProvider,
      routerConfig: routerConfig,
    ),
  );
}

class FlowDayApp extends StatelessWidget {
  const FlowDayApp({
    super.key,
    required this.authProvider,
    required this.eventProvider,
    required this.taskProvider,
    required this.planProvider,
    required this.profileProvider,
    required this.routerConfig,
  });

  final AuthProvider authProvider;
  final EventProvider eventProvider;
  final TaskProvider taskProvider;
  final PlanProvider planProvider;
  final ProfileProvider profileProvider;
  final AppRouterConfig routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<EventProvider>.value(value: eventProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<PlanProvider>.value(value: planProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: routerConfig.router,
      ),
    );
  }
}
