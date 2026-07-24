// Testes do repositório para o sprint "Stats-base do grupo": templates de
// status no nível do grupo copiados para personagens novos.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir =
      Directory.systemTemp.createTempSync('hero_tracker_template_test');

  setUpAll(() {
    // Em testes (Dart VM) não há plugin Android — usa o backend FFI.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

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

  final repo = TrackerRepository.instance;

  test('personagem novo nasce com os stats do template do grupo', () async {
    final group = await repo.insertGroup(
      GameGroup(name: 'Grupo Templates', createdAt: DateTime.now()),
    );

    await repo.insertTemplate(GroupStatTemplate(
      groupId: group.id!,
      name: 'Vida',
      type: StatType.number,
      defaultValue: 100,
      sortOrder: 0,
    ));
    await repo.insertTemplate(GroupStatTemplate(
      groupId: group.id!,
      name: 'Defesa',
      type: StatType.number,
      defaultValue: 10,
      sortOrder: 1,
    ));
    await repo.insertTemplate(GroupStatTemplate(
      groupId: group.id!,
      name: 'Crítico',
      type: StatType.percent,
      defaultValue: 5,
      sortOrder: 2,
    ));

    final character = await repo.insertCharacter(
      Character(groupId: group.id!, name: 'Herói Teste', createdAt: DateTime.now()),
    );
    await repo.applyGroupTemplatesToCharacter(character);

    final stats = await repo.getStatsByCharacter(character.id!);
    expect(stats.length, 3);
    expect(stats.map((s) => s.name).toSet(), {'Vida', 'Defesa', 'Crítico'});
    expect(stats.firstWhere((s) => s.name == 'Vida').value, 100);
    expect(stats.firstWhere((s) => s.name == 'Crítico').type, StatType.percent);
  });

  test('personagem criado ANTES do template continua intacto', () async {
    final group = await repo.insertGroup(
      GameGroup(name: 'Grupo Personagem Antigo', createdAt: DateTime.now()),
    );
    final character = await repo.insertCharacter(
      Character(groupId: group.id!, name: 'Veterano', createdAt: DateTime.now()),
    );

    // Template criado DEPOIS do personagem — não deve afetá-lo (sem
    // aplicação retroativa nesta sprint).
    await repo.insertTemplate(GroupStatTemplate(
      groupId: group.id!,
      name: 'Vida',
      type: StatType.number,
      defaultValue: 100,
    ));

    final stats = await repo.getStatsByCharacter(character.id!);
    expect(stats, isEmpty);
  });

  test('grupo sem templates: personagem nasce sem stats (comportamento atual intocado)',
      () async {
    final group = await repo.insertGroup(
      GameGroup(name: 'Grupo Sem Templates', createdAt: DateTime.now()),
    );
    final character = await repo.insertCharacter(
      Character(groupId: group.id!, name: 'Sem Stats', createdAt: DateTime.now()),
    );
    await repo.applyGroupTemplatesToCharacter(character);

    final stats = await repo.getStatsByCharacter(character.id!);
    expect(stats, isEmpty);
  });

  test('sub-grupo sem templates próprios herda do pai mais próximo', () async {
    final parent = await repo.insertGroup(
      GameGroup(name: 'Pai Templates', createdAt: DateTime.now()),
    );
    await repo.insertTemplate(GroupStatTemplate(
      groupId: parent.id!,
      name: 'Ataque',
      type: StatType.number,
      defaultValue: 50,
    ));
    final child = await repo.insertGroup(
      GameGroup(
        name: 'Filho Sem Templates',
        parentId: parent.id,
        createdAt: DateTime.now(),
      ),
    );

    final effective = await repo.getEffectiveTemplates(child.id!);
    expect(effective.length, 1);
    expect(effective.first.name, 'Ataque');

    final character = await repo.insertCharacter(
      Character(groupId: child.id!, name: 'Herdeiro', createdAt: DateTime.now()),
    );
    await repo.applyGroupTemplatesToCharacter(character);
    final stats = await repo.getStatsByCharacter(character.id!);
    expect(stats.length, 1);
    expect(stats.first.name, 'Ataque');
  });

  test('onlyTemplateIds filtra quais templates o personagem recebe', () async {
    final group = await repo.insertGroup(
      GameGroup(name: 'Grupo Caixinhas', createdAt: DateTime.now()),
    );
    final vida = await repo.insertTemplate(GroupStatTemplate(
        groupId: group.id!, name: 'Vida', type: StatType.number));
    await repo.insertTemplate(GroupStatTemplate(
        groupId: group.id!, name: 'Só de Herói', type: StatType.number));

    final character = await repo.insertCharacter(
      Character(
          groupId: group.id!, name: 'Soldado', createdAt: DateTime.now()),
    );
    // Só "Vida" marcada — "Só de Herói" desmarcada nas caixinhas.
    await repo.applyGroupTemplatesToCharacter(character,
        onlyTemplateIds: {vida.id!});

    final stats = await repo.getStatsByCharacter(character.id!);
    expect(stats.length, 1);
    expect(stats.first.name, 'Vida');
  });

  test('editar ou apagar template não altera stats já copiados (cópia, não referência)',
      () async {
    final group = await repo.insertGroup(
      GameGroup(name: 'Grupo Edição', createdAt: DateTime.now()),
    );
    final template = await repo.insertTemplate(GroupStatTemplate(
      groupId: group.id!,
      name: 'Vida',
      type: StatType.number,
      defaultValue: 100,
    ));
    final character = await repo.insertCharacter(
      Character(groupId: group.id!, name: 'Personagem', createdAt: DateTime.now()),
    );
    await repo.applyGroupTemplatesToCharacter(character);

    await repo.updateTemplate(template.copyWith(defaultValue: 999));
    var stats = await repo.getStatsByCharacter(character.id!);
    expect(stats.first.value, 100);

    await repo.deleteTemplate(template.id!);
    stats = await repo.getStatsByCharacter(character.id!);
    expect(stats.length, 1); // stat do personagem continua existindo
  });
}
