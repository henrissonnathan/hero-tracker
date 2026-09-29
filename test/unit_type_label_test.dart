// Nomes dos tipos de unidade por jogo (v11): o dono renomeia "Herói" para
// "Comandante" DENTRO do app, o nome desce para os sub-grupos, volta ao padrão
// quando ele quiser, e não se perde no backup.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/unit_type_label.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/services/export_service.dart';
import 'package:hero_tracker/ui/game_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_types');
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

  Future<void> wipe() async {
    for (final g in await repo.getAllGroups()) {
      await repo.deleteGroup(g.id!);
    }
  }

  Future<GameGroup> newGroup({int? parentId, String name = 'Jogo'}) =>
      repo.insertGroup(GameGroup(
          parentId: parentId, name: name, createdAt: DateTime(2026, 7, 25)));

  Future<void> rename(int groupId, CharacterType t, String label,
          [String? emoji]) =>
      repo.upsertTypeLabel(UnitTypeLabel(
          groupId: groupId, typeKey: t.dbValue, label: label, emoji: emoji));

  test('renomear no jogo vale nos sub-grupos; o sub-grupo pode sobrepor um só',
      () async {
    await wipe();
    final jogo = await newGroup(name: 'Rise of Kingdoms');
    final sub = await newGroup(parentId: jogo.id, name: 'Comandantes');

    await rename(jogo.id!, CharacterType.heroi, 'Comandante', '⚔️');
    await rename(jogo.id!, CharacterType.comandante, 'Governador');

    final noSub = await repo.getEffectiveTypeNames(sub.id!);
    expect(noSub.labelOf(CharacterType.heroi), 'Comandante');
    expect(noSub.labelOf(CharacterType.comandante), 'Governador');
    // Tipo não renomeado continua no padrão do app.
    expect(noSub.labelOf(CharacterType.soldadoNormal),
        CharacterType.soldadoNormal.label);

    // O sub-grupo sobrepõe SÓ um tipo — o resto continua herdado.
    await rename(sub.id!, CharacterType.heroi, 'Oficial');
    final depois = await repo.getEffectiveTypeNames(sub.id!);
    expect(depois.labelOf(CharacterType.heroi), 'Oficial');
    expect(depois.labelOf(CharacterType.comandante), 'Governador');
  });

  test('regravar o mesmo tipo troca o nome (não empilha) e restaurar volta ao '
      'padrão do app', () async {
    await wipe();
    final jogo = await newGroup();

    await rename(jogo.id!, CharacterType.heroi, 'Comandante');
    await rename(jogo.id!, CharacterType.heroi, 'General');
    expect((await repo.getTypeLabelsByGroup(jogo.id!)).length, 1);
    expect((await repo.getEffectiveTypeNames(jogo.id!))
        .labelOf(CharacterType.heroi), 'General');

    await repo.deleteTypeLabel(jogo.id!, CharacterType.heroi.dbValue);
    final nomes = await repo.getEffectiveTypeNames(jogo.id!);
    expect(nomes.labelOf(CharacterType.heroi), CharacterType.heroi.label);
    expect(nomes.emojiOf(CharacterType.heroi), CharacterType.heroi.emoji);
  });

  test('o backup leva os nomes dos tipos', () async {
    await wipe();
    final jogo = await newGroup();
    await rename(jogo.id!, CharacterType.heroi, 'Comandante', '🎖️');

    final json = await ExportService.instance.buildExportJson();
    final arquivo = File(p.join(tempDir.path, 'backup_tipos.json'))
      ..writeAsStringSync(json);

    await wipe();
    final r = await ExportService.instance.importFromFile(arquivo.path);
    expect(r.success, isTrue, reason: r.message);

    final importado = (await repo.getAllGroups()).single;
    final nomes = await repo.getEffectiveTypeNames(importado.id!);
    expect(nomes.labelOf(CharacterType.heroi), 'Comandante');
    expect(nomes.emojiOf(CharacterType.heroi), '🎖️');
  });

  testWidgets('o card do personagem mostra o nome que o jogo deu ao tipo',
      (WidgetTester tester) async {
    late GameGroup jogo;
    await tester.runAsync(() async {
      await wipe();
      jogo = await newGroup();
      await rename(jogo.id!, CharacterType.heroi, 'Comandante', '⚔️');
      await repo.insertCharacter(Character(
        groupId: jogo.id!,
        name: 'Cao Cao',
        characterType: CharacterType.heroi,
        createdAt: DateTime(2026, 7, 25),
      ));
    });

    await tester.pumpWidget(MaterialApp(home: GameScreen(group: jogo)));
    await pumpUntilFound(tester, find.text('Cao Cao'));

    expect(find.text('Comandante'), findsOneWidget);
    expect(find.text('Herói'), findsNothing);
  });
}
