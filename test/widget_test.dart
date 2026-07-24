// Smoke test do Hero Tracker: o app sobe, a HomeScreen carrega do banco
// (sqflite via FFI em ambiente de teste) e mostra a tela inicial.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/ui/home_screen.dart';
import 'package:hero_tracker/ui/stats_screen.dart';
import 'package:hero_tracker/ui/widgets/group_icon.dart';

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

  testWidgets('HomeScreen carrega do banco e renderiza',
      (WidgetTester tester) async {
    // Tema padrão (sem AppTheme/GoogleFonts): fonte em runtime não carrega
    // em teste — some quando a Nunito for embutida nos assets.
    // runAsync: o banco abre com I/O real, que não roda no tempo simulado
    // do ambiente de teste.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await Future<void>.delayed(const Duration(seconds: 1));
      await tester.pump();
    });

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
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

    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: StatsScreen(group: group)));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
    });

    expect(find.text('Combate'), findsOneWidget);
    expect(find.text('Recursos'), findsOneWidget);
    expect(find.text('Vida · Número'), findsOneWidget);
  });
}
