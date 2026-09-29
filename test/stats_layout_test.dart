// Status por linha na tela do personagem: o dono escolhe 1, 2 ou 3 colunas
// (pediu "mais informação por linha, mais compacto"). O teste olha a POSIÇÃO
// real na tela — dois status na mesma linha têm o mesmo topo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_stat.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/ui/character_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_layout');
  final repo = TrackerRepository.instance;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {/* em uso no Windows */}
  });

  /// Cria um personagem com 4 status numéricos e devolve ele.
  Future<Character> comQuatroStatus() async {
    for (final g in await repo.getAllGroups()) {
      await repo.deleteGroup(g.id!);
    }
    final grupo = await repo.insertGroup(
        GameGroup(name: 'Jogo', createdAt: DateTime(2026, 7, 25)));
    final c = await repo.insertCharacter(Character(
        groupId: grupo.id!, name: 'Herói', createdAt: DateTime(2026, 7, 25)));
    const nomes = ['Ataque', 'Defesa', 'Vida', 'Velocidade'];
    for (var i = 0; i < nomes.length; i++) {
      await repo.insertStat(CharacterStat(
          characterId: c.id!,
          name: nomes[i],
          type: StatType.number,
          value: 10,
          sortOrder: i));
    }
    return c;
  }

  /// Topo do card na tela (prova de qual linha o status está).
  double topo(WidgetTester tester, String nome) =>
      tester.getTopLeft(find.text(nome)).dy;

  testWidgets('padrão: 2 status por linha', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    late Character c;
    await tester.runAsync(() async => c = await comQuatroStatus());

    await tester.pumpWidget(MaterialApp(home: CharacterScreen(character: c)));
    await pumpUntilFound(tester, find.text('Velocidade'));

    expect(topo(tester, 'Ataque'), topo(tester, 'Defesa'),
        reason: 'Ataque e Defesa deviam dividir a 1ª linha');
    expect(topo(tester, 'Vida'), topo(tester, 'Velocidade'),
        reason: 'Vida e Velocidade deviam dividir a 2ª linha');
    expect(topo(tester, 'Vida'), greaterThan(topo(tester, 'Ataque')),
        reason: 'a 2ª linha tem que ficar abaixo da 1ª');
  });

  testWidgets('escolhendo 1 por linha, cada status ocupa a sua',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'flutter.stats_columns': 1});
    late Character c;
    await tester.runAsync(() async => c = await comQuatroStatus());

    await tester.pumpWidget(MaterialApp(home: CharacterScreen(character: c)));
    // Com 1 por linha o card é grande: "Velocidade" fica fora da tela e nem
    // chega a ser construído — por isso a espera é pelo 3º status.
    await pumpUntilFound(tester, find.text('Vida'));
    // A preferência chega por Future — dá tempo dela ser aplicada.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    expect(topo(tester, 'Defesa'), greaterThan(topo(tester, 'Ataque')));
    expect(topo(tester, 'Vida'), greaterThan(topo(tester, 'Defesa')));
  });
}
