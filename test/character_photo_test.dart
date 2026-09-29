// Foto de herói/tropa (schema v10): o caminho vive no banco, o PNG vive na
// pasta interna do app — e nenhuma das duas pontas pode vazar ou sumir.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/services/export_service.dart';
import 'package:hero_tracker/services/icon_image_store.dart';
import 'package:hero_tracker/ui/game_screen.dart';

import 'test_helpers.dart';

/// PNG 1x1 de verdade — serve de "foto" sem depender de desenho/engine.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_photo');
  final repo = TrackerRepository.instance;

  /// Mesma pasta que o IconImageStore usa (support dir mockado = tempDir).
  Directory iconsDir() => Directory(p.join(tempDir.path, 'group_icons'));

  /// Cria um PNG dentro da pasta interna, como se tivesse sido importado.
  File fakePhoto(String name) {
    final dir = iconsDir()..createSync(recursive: true);
    return File(p.join(dir.path, name))..writeAsBytesSync(_png);
  }

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

  Future<GameGroup> newGroup() => repo.insertGroup(
      GameGroup(name: 'Jogo', createdAt: DateTime(2026, 7, 25)));

  test('o personagem guarda a foto e "remover foto" limpa de verdade',
      () async {
    await wipe();
    final g = await newGroup();
    final saved = await repo.insertCharacter(Character(
      groupId: g.id!,
      name: 'Cao Cao',
      role: 'Cavalaria',
      createdAt: DateTime(2026, 7, 25),
      iconImagePath: r'C:\interno\icon_1.png',
    ));
    expect((await repo.getCharactersByGroup(g.id!)).single.iconImagePath,
        r'C:\interno\icon_1.png');

    // Remover a foto tem que APAGAR a coluna: chave ausente no UPDATE
    // deixaria o caminho velho no banco (a foto "voltaria" ao reabrir).
    await repo
        .updateCharacter(saved.copyWith(clearIconImage: true, clearRole: true));
    final depois = (await repo.getCharactersByGroup(g.id!)).single;
    expect(depois.iconImagePath, isNull);
    expect(depois.role, isNull);
  });

  test('a varredura de órfãos NÃO apaga a foto de um personagem', () async {
    await wipe();
    final g = await newGroup();
    final usada = fakePhoto('icon_do_heroi.png');
    final orfa = fakePhoto('icon_sobra.png');
    await repo.insertCharacter(Character(
      groupId: g.id!,
      name: 'Com foto',
      createdAt: DateTime(2026, 7, 25),
      iconImagePath: usada.path,
    ));

    // Exatamente a lista que a Home usa no boot.
    await IconImageStore.cleanupOrphans(
        await repo.getAllIconImagePathsInUse());

    expect(usada.existsSync(), isTrue,
        reason: 'a foto do herói foi varrida junto com as sobras');
    expect(orfa.existsSync(), isFalse,
        reason: 'a sobra de verdade tinha que ter sido apagada');
  });

  test('o backup NÃO leva o caminho da foto (contrato JSON)', () async {
    await wipe();
    final g = await newGroup();
    await repo.insertCharacter(Character(
      groupId: g.id!,
      name: 'Com foto',
      createdAt: DateTime(2026, 7, 25),
      iconImagePath: r'C:\Users\alguem\segredo\icon_9.png',
    ));

    final json = await ExportService.instance.buildExportJson();
    final arquivo = File(p.join(tempDir.path, 'backup.json'))
      ..writeAsStringSync(json);

    await wipe();
    final r = await ExportService.instance.importFromFile(arquivo.path);
    expect(r.success, isTrue, reason: r.message);

    final grupo = (await repo.getAllGroups()).single;
    final importado = (await repo.getCharactersByGroup(grupo.id!)).single;
    expect(importado.name, 'Com foto');
    expect(importado.iconImagePath, isNull,
        reason: 'caminho de arquivo do PC de outra pessoa entrou pelo backup');
  });

  testWidgets('card do personagem: com foto mostra a imagem, sem foto o emoji',
      (WidgetTester tester) async {
    late GameGroup g;
    await tester.runAsync(() async {
      await wipe();
      g = await newGroup();
      await repo.insertCharacter(Character(
        groupId: g.id!,
        name: 'Com foto',
        createdAt: DateTime(2026, 7, 25),
        iconImagePath: fakePhoto('icon_card.png').path,
      ));
      await repo.insertCharacter(Character(
        groupId: g.id!,
        name: 'Sem foto',
        createdAt: DateTime(2026, 7, 25, 0, 1),
      ));
    });

    await tester.pumpWidget(MaterialApp(home: GameScreen(group: g)));
    await pumpUntilFound(tester, find.text('Com foto'));

    expect(find.text('Sem foto'), findsOneWidget);
    // Uma foto na tela = a do primeiro card; o segundo cai no emoji do tipo.
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('🛡️'), findsOneWidget);
  });
}
