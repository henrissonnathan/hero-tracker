// Smokes do Hero Tracker: o app REAL sobe, a HomeScreen carrega do banco
// (sqflite via FFI) e a StatsScreen agrupa por categoria.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/main.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/ui/home_screen.dart';
import 'package:hero_tracker/ui/stats_screen.dart';
import 'package:hero_tracker/ui/widgets/group_icon.dart';
import 'package:hero_tracker/ui/widgets/stat_type_visual.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_test');

  setUpAll(() {
    // Em testes (Dart VM) não há plugin Android — usa o backend FFI.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Testes não têm rede — sem fetch de fonte em runtime (padrão do pacote).
    GoogleFonts.config.allowRuntimeFetching = false;

    // O branch desktop do DatabaseHelper usa path_provider, que não tem
    // plugin no ambiente de teste — responde com uma pasta temporária.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Banco pode ainda estar aberto no Windows — pasta temp se limpa sozinha.
    }
  });

  testWidgets('smoke de boot: o app REAL (HeroTrackerApp) sobe até a Home',
      (WidgetTester tester) async {
    // Tema de teste substitui só a fonte (GoogleFonts sem rede);
    // árvore de widgets é a REAL do main.dart.
    await tester.pumpWidget(HeroTrackerApp(theme: ThemeData.dark()));
    await pumpUntilGone(tester, find.byType(CircularProgressIndicator));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('GroupIcon sem foto mostra o emoji', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: GroupIcon(imagePath: null, emoji: '🐉')));
    expect(find.text('🐉'), findsOneWidget);
  });

  testWidgets('GroupIcon com caminho inexistente cai no emoji (fallback)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: GroupIcon(
            imagePath: 'C:/nao/existe/icone.png', emoji: '🏰')));
    expect(find.text('🏰'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('StatsScreen agrupa os status por categoria',
      (WidgetTester tester) async {
    final repo = TrackerRepository.instance;
    late GameGroup group;
    await tester.runAsync(() async {
      group = await repo.insertGroup(
          GameGroup(name: 'Jogo de Teste', createdAt: DateTime(2026, 1, 1)));
      await repo.insertTemplate(GroupStatTemplate(
          groupId: group.id!,
          name: 'Vida',
          type: StatType.number,
          category: 'Combate'));
      await repo.insertTemplate(GroupStatTemplate(
          groupId: group.id!,
          name: 'Ouro',
          type: StatType.number,
          category: 'Recursos'));
    });

    await tester.pumpWidget(MaterialApp(home: StatsScreen(group: group)));
    await pumpUntilFound(tester, find.text('Combate'));

    expect(find.text('Combate'), findsOneWidget);
    expect(find.text('Recursos'), findsOneWidget);
    // O status fica DENTRO da sua categoria, com nome, tipo e selo de ícone.
    final combate = find.ancestor(
        of: find.text('Combate'), matching: find.byType(Card));
    expect(find.descendant(of: combate, matching: find.text('Vida')),
        findsOneWidget);
    expect(find.descendant(of: combate, matching: find.text('Ouro')),
        findsNothing);
    expect(find.text('Número'), findsNWidgets(2));
    expect(find.byType(StatTypeBadge), findsNWidgets(2));
  });
}
