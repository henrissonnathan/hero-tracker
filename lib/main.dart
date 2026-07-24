import 'package:flutter/material.dart';
import 'repositories/desktop_database_init.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDesktopDatabaseFactory(); // no-op em Android (guard interno)
  runApp(const HeroTrackerApp());
}

class HeroTrackerApp extends StatelessWidget {
  const HeroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
