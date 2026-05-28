import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/app_shell/presentation/app_shell.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screens.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/events/presentation/screens/events_screens.dart';
import '../features/profile/presentation/screens/profile_screens.dart';
import '../features/statistics/presentation/screens/statistics_screens.dart';
import '../features/tasks/presentation/screens/tasks_screens.dart';
import '../features/today/presentation/screens/today_screens.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding1 = '/onboarding/1';
  static const String onboarding2 = '/onboarding/2';
  static const String onboarding3 = '/onboarding/3';
  static const String login = '/login';
  static const String register = '/register';

  static const String today = '/today';
  static const String events = '/events';
  static const String tasks = '/tasks';
  static const String profile = '/profile';

  static const String aiPlan = '/today/plan';
  static const String aiPlanDetail = '/today/plan/detail';
  static const String morningBrief = '/today/brief';
  static const String plannerTips = '/today/tips';

  static const String addEvent = '/events/add';
  static const String editEvent = '/events/edit';
  static const String eventDetail = '/events/detail';
  static const String eventCalendar = '/events/calendar';
  static const String eventCategories = '/events/categories';

  static const String addTask = '/tasks/add';
  static const String editTask = '/tasks/edit';
  static const String taskDetail = '/tasks/detail';
  static const String priorityTasks = '/tasks/priority';
  static const String completedTasks = '/tasks/completed';

  static const String statistics = '/statistics';
  static const String productivityTrends = '/statistics/trends';
  static const String weeklyReview = '/statistics/review';

  static const String editProfile = '/profile/edit';
  static const String photoUpload = '/profile/photo';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String about = '/about';
  static const String achievements = '/achievements';
  static const String support = '/support';
  static const String emptyStates = '/empty-states';
}

class AppRouterConfig {
  const AppRouterConfig(this.router);

  final GoRouter router;
}

class AppRouter {
  AppRouter(this._authProvider);

  final AuthProvider _authProvider;

  AppRouterConfig get router => AppRouterConfig(
    GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _authProvider,
      redirect: _redirect,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          pageBuilder: (context, state) => _page(state, const SplashScreen()),
        ),
        GoRoute(
          path: AppRoutes.onboarding1,
          pageBuilder: (context, state) =>
              _page(state, const OnboardingScreen1()),
        ),
        GoRoute(
          path: AppRoutes.onboarding2,
          pageBuilder: (context, state) =>
              _page(state, const OnboardingScreen2()),
        ),
        GoRoute(
          path: AppRoutes.onboarding3,
          pageBuilder: (context, state) =>
              _page(state, const OnboardingScreen3()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => _page(state, const LoginScreen()),
        ),
        GoRoute(
          path: AppRoutes.register,
          pageBuilder: (context, state) => _page(state, const RegisterScreen()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.today,
                  pageBuilder: (context, state) =>
                      _page(state, const TodayScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.events,
                  pageBuilder: (context, state) =>
                      _page(state, const EventsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.tasks,
                  pageBuilder: (context, state) =>
                      _page(state, const TasksScreen()),
                  routes: [
                    GoRoute(
                      path: 'priority',
                      pageBuilder: (context, state) =>
                          _page(state, const PriorityTasksScreen()),
                    ),
                    GoRoute(
                      path: 'completed',
                      pageBuilder: (context, state) =>
                          _page(state, const CompletedTasksScreen()),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  pageBuilder: (context, state) =>
                      _page(state, const ProfileScreen()),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.aiPlan,
          pageBuilder: (context, state) => _page(state, const AiPlanScreen()),
        ),
        GoRoute(
          path: AppRoutes.aiPlanDetail,
          pageBuilder: (context, state) => _page(
            state,
            AiPlanDetailScreen(block: state.extra as Map<String, dynamic>?),
          ),
        ),
        GoRoute(
          path: AppRoutes.morningBrief,
          pageBuilder: (context, state) =>
              _page(state, const MorningBriefScreen()),
        ),
        GoRoute(
          path: AppRoutes.plannerTips,
          pageBuilder: (context, state) =>
              _page(state, const PlannerTipsScreen()),
        ),
        GoRoute(
          path: AppRoutes.addEvent,
          pageBuilder: (context, state) => _page(state, const AddEventScreen()),
        ),
        GoRoute(
          path: AppRoutes.editEvent,
          pageBuilder: (context, state) =>
              _page(state, EditEventScreen(event: state.extra as EventModel?)),
        ),
        GoRoute(
          path: AppRoutes.eventDetail,
          pageBuilder: (context, state) => _page(
            state,
            EventDetailScreen(event: state.extra as EventModel?),
          ),
        ),
        GoRoute(
          path: AppRoutes.eventCalendar,
          pageBuilder: (context, state) =>
              _page(state, const EventCalendarScreen()),
        ),
        GoRoute(
          path: AppRoutes.eventCategories,
          pageBuilder: (context, state) =>
              _page(state, const EventCategoriesScreen()),
        ),
        GoRoute(
          path: AppRoutes.addTask,
          pageBuilder: (context, state) => _page(state, const AddTaskScreen()),
        ),
        GoRoute(
          path: AppRoutes.editTask,
          pageBuilder: (context, state) =>
              _page(state, EditTaskScreen(task: state.extra as TaskModel?)),
        ),
        GoRoute(
          path: AppRoutes.taskDetail,
          pageBuilder: (context, state) =>
              _page(state, TaskDetailScreen(task: state.extra as TaskModel?)),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          pageBuilder: (context, state) =>
              _page(state, const StatisticsScreen()),
        ),
        GoRoute(
          path: AppRoutes.productivityTrends,
          pageBuilder: (context, state) =>
              _page(state, const ProductivityTrendsScreen()),
        ),
        GoRoute(
          path: AppRoutes.weeklyReview,
          pageBuilder: (context, state) =>
              _page(state, const WeeklyReviewScreen()),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          pageBuilder: (context, state) =>
              _page(state, const EditProfileScreen()),
        ),
        GoRoute(
          path: AppRoutes.photoUpload,
          pageBuilder: (context, state) =>
              _page(state, const PhotoUploadScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => _page(state, const SettingsScreen()),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          pageBuilder: (context, state) =>
              _page(state, const NotificationsScreen()),
        ),
        GoRoute(
          path: AppRoutes.about,
          pageBuilder: (context, state) => _page(state, const AboutScreen()),
        ),
        GoRoute(
          path: AppRoutes.achievements,
          pageBuilder: (context, state) =>
              _page(state, const AchievementScreen()),
        ),
        GoRoute(
          path: AppRoutes.support,
          pageBuilder: (context, state) => _page(state, const SupportScreen()),
        ),
        GoRoute(
          path: AppRoutes.emptyStates,
          pageBuilder: (context, state) =>
              _page(state, const EmptyStateDemoScreen()),
        ),
      ],
    ),
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final isOnboarding = location.startsWith('/onboarding');
    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.register;
    final isSplash = location == AppRoutes.splash;

    if (!_authProvider.initialized) {
      return isSplash ? null : AppRoutes.splash;
    }
    if (isSplash) {
      return null;
    }
    if (!_authProvider.onboardingSeen) {
      return isOnboarding ? null : AppRoutes.onboarding1;
    }
    if (!_authProvider.isAuthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }
    if (isAuthRoute || isOnboarding || isSplash) {
      return AppRoutes.today;
    }
    return null;
  }

  CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
