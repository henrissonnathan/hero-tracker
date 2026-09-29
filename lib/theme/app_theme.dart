import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Tema do app (fonte Nunito via google_fonts).
  static ThemeData get dark =>
      buildDark(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme));

  /// O MESMO tema, com a fonte opcional — gancho de teste: o teste roda sem
  /// rede (sem GoogleFonts) mas precisa das outras regras do tema de verdade.
  static ThemeData buildDark({TextTheme? textTheme}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB700),
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
        // No Windows o Flutter usa por padrão botões compactos e área de toque
        // encolhida (shrinkWrap). Fixamos o tamanho de celular: alvo 48×48 em
        // toda plataforma, e o PC mostra o app como ele será no celular.
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
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
  // Roxo claro: o AB47BC dava ~3,9:1 no fundo escuro (WCAG pede 4,5:1).
  static const Color numberColor = Color(0xFFCE93D8);
  static const Color triggerColor = Color(0xFFFF7043);
  static const Color formulaColor = Color(0xFF26C6DA);
}
