import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';
import 'package:daily_sales_plan_tracker/nav.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  
  // Initialize the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SalesProvider()..loadData()),
      ],
      child: MaterialApp.router(
        title: 'Daily Sales Plan Tracker',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
        ],

        // Theme configuration
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,

        // Use context.go() or context.push() to navigate to the routes.
        routerConfig: AppRouter.router,
      ),
    );
  }
}
