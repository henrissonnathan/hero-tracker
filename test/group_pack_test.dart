// Testes do PACOTE de um jogo (modelo + personagens): enviar → receber em
// outro jogo, JSON escrito à mão (só nome + valor), nada que existe é
// sobrescrito, e arquivo errado é recusado sem tocar no banco.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_ability.dart';
import 'package:hero_tracker/models/character_stat.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_pack');
  final repo = TrackerRepository.instance;
  final svc = ExportService.instance;

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
    for (final g in await repo.getRootGroups()) {
      await repo.deleteGroup(g.id!);
    }
  }

  Future<String> writeFile(String content) async {
    final f = File('${tempDir.path}${Platform.pathSeparator}'
        'pacote_${DateTime.now().microsecondsSinceEpoch}.json');
    await f.writeAsString(content, encoding: utf8);
    return f.path;
  }

  Future<GameGroup> novoJogo(String nome) =>
      repo.insertGroup(GameGroup(name: nome, createdAt: DateTime.now()));

  test('enviar pacote → receber em outro jogo traz modelo, heróis e habilidades',
      () async {
    await wipe();
    final origem = await novoJogo('Origem');
    await repo.insertTemplate(GroupStatTemplate(
        groupId: origem.id!,
        name: 'Bônus de ataque',
        type: StatType.percent,
        category: 'Bônus'));
    final heroi = await repo.insertCharacter(Character(
        groupId: origem.id!,
        name: 'Cao Cao',
        iconImagePath: 'C:/foto/que/nao/pode/viajar.png',
        createdAt: DateTime.now()));
    await repo.insertStat(CharacterStat(
        characterId: heroi.id!,
        name: 'Bônus de ataque',
        type: StatType.percent,
        value: 12));
    await repo.insertAbility(CharacterAbility(
        characterId: heroi.id!,
        name: 'Carga',
        targetStatName: 'Bônus de ataque',
        bonusValue: 5));

    final json = await svc.buildGroupPackJson(origem.id!);
    expect(json, isNot(contains('viajar.png')),
        reason: 'caminho de foto nunca sai do aparelho');

    final destino = await novoJogo('Destino');
    final r = await svc.importGroupPack(await writeFile(json), destino.id!);
    expect(r.success, isTrue, reason: r.message);

    final modelo = await repo.getTemplatesByGroup(destino.id!);
    expect(modelo.single.name, 'Bônus de ataque');
    expect(modelo.single.type, StatType.percent);
    expect(modelo.single.category, 'Bônus');

    final chars = await repo.getCharactersByGroup(destino.id!);
    expect(chars.single.name, 'Cao Cao');
    expect(chars.single.iconImagePath, isNull);
    final stats = await repo.getStatsByCharacter(chars.single.id!);
    expect(stats.single.value, 12);
    final habs = await repo.getAbilitiesByCharacter(chars.single.id!);
    expect(habs.single.name, 'Carga');
  });

  test('JSON escrito à mão: só nome + valor, tipo vem do modelo', () async {
    await wipe();
    final jogo = await novoJogo('Mão');
    final path = await writeFile(jsonEncode({
      'group': {
        'statTemplates': [
          {'name': 'Bônus de defesa', 'type': 'percent', 'defaultValue': 3},
          {'name': 'Capacidade de tropas', 'type': 'number'},
        ],
        'characters': [
          {
            'name': 'Sun Tzu',
            'stats': [
              {'name': 'bônus de defesa', 'value': 8}, // sem type, minúscula
              {'name': 'Velocidade', 'value': 2}, // fora do modelo
            ],
          },
          {'name': 'Boudica'}, // sem stats: nasce só com o modelo
        ],
      },
    }));

    final r = await svc.importGroupPack(path, jogo.id!);
    expect(r.success, isTrue, reason: r.message);

    final chars = {
      for (final c in await repo.getCharactersByGroup(jogo.id!)) c.name: c
    };
    final sun = await repo.getStatsByCharacter(chars['Sun Tzu']!.id!);
    final porNome = {for (final s in sun) s.name: s};
    expect(porNome.keys,
        ['Bônus de defesa', 'Capacidade de tropas', 'Velocidade'],
        reason: 'ordem do modelo, extra no fim');
    expect(porNome['Bônus de defesa']!.type, StatType.percent);
    expect(porNome['Bônus de defesa']!.value, 8);
    expect(porNome['Capacidade de tropas']!.value, 0);

    final bou = await repo.getStatsByCharacter(chars['Boudica']!.id!);
    expect(bou.map((s) => s.name), ['Bônus de defesa', 'Capacidade de tropas']);
    expect(bou.first.value, 3, reason: 'valor padrão do modelo');
  });

  test('receber pacote não sobrescreve status nem personagem que já existem',
      () async {
    await wipe();
    final jogo = await novoJogo('Meu jogo');
    await repo.insertTemplate(GroupStatTemplate(
        groupId: jogo.id!, name: 'Vida', type: StatType.number));
    final meu = await repo.insertCharacter(Character(
        groupId: jogo.id!,
        name: 'Ricardo I',
        notes: 'minhas notas',
        createdAt: DateTime.now()));

    final r = await svc.importGroupPack(
        await writeFile(jsonEncode({
          'version': ExportService.formatVersion,
          'kind': ExportService.packKind,
          'group': {
            'name': 'x',
            'statTemplates': [
              {'name': 'VIDA', 'type': 'percent'},
              {'name': 'Fúria', 'type': 'number'},
            ],
            'characters': [
              {'name': 'ricardo i', 'notes': 'do arquivo'},
              {'name': 'Yi Seong-Gye'},
            ],
          },
        })),
        jogo.id!);
    expect(r.success, isTrue, reason: r.message);
    expect(r.message, contains('2 item(ns)'));

    final modelo = await repo.getTemplatesByGroup(jogo.id!);
    expect(modelo.map((t) => t.name), ['Vida', 'Fúria']);
    expect(modelo.first.type, StatType.number, reason: 'o meu ficou intacto');

    final chars = await repo.getCharactersByGroup(jogo.id!);
    expect(chars.length, 2);
    final ricardo = chars.firstWhere((c) => c.id == meu.id);
    expect(ricardo.notes, 'minhas notas');
  });

  test('arquivo que não é pacote é recusado sem gravar nada', () async {
    await wipe();
    final jogo = await novoJogo('Intocado');
    for (final conteudo in [
      '{ isto não é json',
      jsonEncode({'foo': 1}),
      jsonEncode({
        'group': {
          'characters': [
            {'name': 'A' * 500},
          ],
        },
      }),
    ]) {
      final r = await svc.importGroupPack(await writeFile(conteudo), jogo.id!);
      expect(r.success, isFalse, reason: conteudo);
    }
    expect(await repo.getTemplatesByGroup(jogo.id!), isEmpty);
    expect(await repo.getCharactersByGroup(jogo.id!), isEmpty);
  });
}
