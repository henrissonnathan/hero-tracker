// Testes do backup (Fase 2): round-trip completo (incluindo a árvore com
// remap de ids), pai ausente vira raiz, e o contrato rejeita arquivo
// malformado/adulterado SEM tocar no banco.
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
import 'package:hero_tracker/models/skill_node.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_export');
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

  Future<String> writeBackup(String content) async {
    final f = File(
        '${tempDir.path}${Platform.pathSeparator}backup_${DateTime.now().microsecondsSinceEpoch}.json');
    await f.writeAsString(content, encoding: utf8);
    return f.path;
  }

  test('round-trip completo: exportar → limpar → importar reproduz tudo',
      () async {
    await wipe();
    // Semeia: raiz + sub-grupo, personagem completo, templates e árvore.
    final root = await repo.insertGroup(
        GameGroup(name: 'Jogo RT', createdAt: DateTime.now()));
    final sub = await repo.insertGroup(GameGroup(
        name: 'Sub RT', parentId: root.id, createdAt: DateTime.now()));
    await repo.insertTemplate(GroupStatTemplate(
        groupId: root.id!, name: 'Vida', type: StatType.number));
    final hero = await repo.insertCharacter(Character(
        groupId: sub.id!, name: 'Herói RT', createdAt: DateTime.now()));
    await repo.insertStat(CharacterStat(
        characterId: hero.id!, name: 'Ataque', type: StatType.number, value: 7));
    await repo.insertAbility(CharacterAbility(
        characterId: hero.id!,
        name: 'Fúria',
        targetStatName: 'Ataque',
        bonusValue: 20));
    final parentNode = await repo
        .insertSkillNode(SkillNode(groupId: root.id!, name: 'Pesquisa I'));
    await repo.insertSkillNode(SkillNode(
        groupId: root.id!, parentId: parentNode.id, name: 'Pesquisa II'));

    final json = await svc.buildExportJson();
    await wipe();
    expect(await repo.getRootGroups(), isEmpty);

    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isTrue, reason: result.message);

    final roots = await repo.getRootGroups();
    expect(roots.length, 1);
    final newRoot = roots.single;
    final subs = await repo.getSubGroups(newRoot.id!);
    expect(subs.single.name, 'Sub RT'); // hierarquia religada

    final templates = await repo.getTemplatesByGroup(newRoot.id!);
    expect(templates.single.name, 'Vida');

    final chars = await repo.getCharactersByGroup(subs.single.id!);
    expect(chars.single.name, 'Herói RT');
    final stats = await repo.getStatsByCharacter(chars.single.id!);
    expect(stats.single.value, 7);
    final abilities = await repo.getAbilitiesByCharacter(chars.single.id!);
    expect(abilities.single.bonusValue, 20);

    final nodes = await repo.getSkillNodes(newRoot.id!);
    expect(nodes.length, 2);
    final p = nodes.firstWhere((n) => n.name == 'Pesquisa I');
    final c = nodes.firstWhere((n) => n.name == 'Pesquisa II');
    expect(c.parentId, p.id, reason: 'parentId da árvore deve ser remapeado');
  });

  test('pai de grupo ausente do backup vira raiz', () async {
    await wipe();
    final json = jsonEncode({
      'version': 1,
      'groups': [
        {
          'id': 50,
          'parentId': 999, // não existe neste backup
          'name': 'Órfão',
          'createdAt': DateTime(2026).toIso8601String(),
        }
      ],
    });
    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isTrue, reason: result.message);
    final roots = await repo.getRootGroups();
    expect(roots.single.name, 'Órfão'); // virou raiz, não órfão pendurado
  });

  test('ciclo de parentId entre grupos não some da UI (vira raiz)', () async {
    await wipe();
    final json = jsonEncode({
      'version': 2,
      'groups': [
        {
          'id': 10,
          'parentId': 20,
          'name': 'Ciclo A',
          'createdAt': DateTime(2026).toIso8601String(),
        },
        {
          'id': 20,
          'parentId': 10,
          'name': 'Ciclo B',
          'createdAt': DateTime(2026).toIso8601String(),
        }
      ],
    });
    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isTrue, reason: result.message);
    final roots = await repo.getRootGroups();
    // Sem o corte de ciclo, os dois teriam parentId != null e sumiriam.
    expect(roots.map((g) => g.name).toSet(), {'Ciclo A', 'Ciclo B'});
  });

  test('campo de texto gigante é rejeitado antes de qualquer insert', () async {
    await wipe();
    final json = jsonEncode({
      'version': 2,
      'groups': [
        {
          'name': 'Jogo',
          'createdAt': DateTime(2026).toIso8601String(),
          'characters': [
            {
              'name': 'Herói',
              'role': 'x' * 6000, // acima do limite de texto
              'createdAt': DateTime(2026).toIso8601String(),
            }
          ],
        }
      ],
    });
    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isFalse);
    expect(await repo.getRootGroups(), isEmpty);
  });

  test('arquivo malformado é rejeitado sem tocar no banco', () async {
    await wipe();
    final result = await svc.importFromFile(await writeBackup('isso{não é json'));
    expect(result.success, isFalse);
    expect(await repo.getRootGroups(), isEmpty);
  });

  test('backup de versão mais nova é rejeitado com aviso', () async {
    await wipe();
    final json = jsonEncode({'version': 99, 'groups': []});
    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isFalse);
    expect(result.message, contains('versão mais nova'));
  });

  test('nome acima do limite é rejeitado ANTES de qualquer insert', () async {
    await wipe();
    final json = jsonEncode({
      'version': 2,
      'groups': [
        {
          'name': 'Válido',
          'createdAt': DateTime(2026).toIso8601String(),
        },
        {
          'name': 'x' * 500, // estoura o limite do contrato
          'createdAt': DateTime(2026).toIso8601String(),
        }
      ],
    });
    final result = await svc.importFromFile(await writeBackup(json));
    expect(result.success, isFalse);
    // validação é TUDO-ou-nada: nem o grupo válido pode ter entrado.
    expect(await repo.getRootGroups(), isEmpty);
  });
}
