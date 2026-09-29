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
  /// Tema opcional para TESTES (o padrão AppTheme.dark usa GoogleFonts, que
  /// exige rede — indisponível no ambiente de teste até a fonte virar asset
  /// na Fase 13 do roadmap). Em produção fica sempre null.
  final ThemeData? theme;

  const HeroTrackerApp({super.key, this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero Tracker',
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
