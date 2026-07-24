import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB700),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  /// Cor dourada — usada para estrelas e destaques de rank
  static const Color gold = Color(0xFFFFB700);
  static const Color goldLight = Color(0xFFFFD54F);
  static const Color goldDark = Color(0xFFFF8F00);

  /// Cores por tipo de status
  static const Color percentColor = Color(0xFF66BB6A);
  static const Color numberColor = Color(0xFFAB47BC);
  static const Color triggerColor = Color(0xFFFF7043);
  static const Color formulaColor = Color(0xFF26C6DA);
}
