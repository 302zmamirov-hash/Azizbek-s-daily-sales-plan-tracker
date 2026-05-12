import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_sales_plan_tracker/screens/history_month_details_screen.dart';
import 'package:daily_sales_plan_tracker/screens/main_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainNavigation(currentIndex: 0),
        ),
      ),
      GoRoute(
        path: AppRoutes.daily,
        name: 'daily',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainNavigation(currentIndex: 1),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainNavigation(currentIndex: 2),
        ),
      ),

      // Bonus tab (Бонус)
      GoRoute(
        path: AppRoutes.bonus,
        name: 'bonus',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainNavigation(currentIndex: 3),
        ),
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainNavigation(currentIndex: 4),
        ),
      ),

      GoRoute(
        path: AppRoutes.historyMonth,
        name: 'history_month',
        pageBuilder: (context, state) {
          final year = int.tryParse(state.pathParameters['year'] ?? '');
          final month = int.tryParse(state.pathParameters['month'] ?? '');
          return MaterialPage(
            child: HistoryMonthDetailsScreen(year: year ?? DateTime.now().year, month: month ?? DateTime.now().month),
          );
        },
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String daily = '/daily';
  static const String history = '/history';
  static const String bonus = '/bonus';
  static const String settings = '/settings';
  static const String historyMonth = '/history/:year/:month';
}
