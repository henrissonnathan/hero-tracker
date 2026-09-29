// Testa o "usuário simulado" (SeedService): montar o mapa de exemplo do Rise
// of Kingdoms cria o jogo com 4 sub-grupos coerentes — cada um com seu modelo
// de status — e refazer/remover funciona sem empilhar cópias.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/services/seed_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_seed');
  final repo = TrackerRepository.instance;
  final seed = SeedService.instance;

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

  test('createExample monta o mapa do RoK com 4 sub-grupos coerentes',
      () async {
    await wipe();
    expect(await seed.exampleExists(), isFalse);

    final root = await seed.createExample();
    expect(await seed.exampleExists(), isTrue);
    expect((await repo.getRootGroups()).single.name,
        SeedService.exampleGroupName);

    // 4 sub-grupos por categoria.
    final subs = await repo.getSubGroups(root.id!);
    expect(subs.map((g) => g.name).toSet(),
        {'Comandantes', 'Tropas', 'Pesquisa', 'Construção'});

    // Comandantes: modelo rico (com fórmula) + 6 comandantes + árvore.
    final cmd = subs.firstWhere((g) => g.name == 'Comandantes');
    final cmdTemplates = await repo.getTemplatesByGroup(cmd.id!);
    expect(cmdTemplates.any((t) => t.type == StatType.formula), isTrue);
    expect(cmdTemplates.any((t) => t.type == StatType.percent), isTrue);

    // Correção do dono: no RoK o comandante NÃO tem Ataque/Defesa/Vida —
    // isso é das TROPAS. Ele entra pela capacidade de tropa + bônus.
    final nomesCmd = cmdTemplates.map((t) => t.name).toSet();
    expect(nomesCmd.intersection({'Ataque', 'Defesa', 'Vida'}), isEmpty,
        reason: 'atributo de tropa voltou para o modelo do comandante');
    expect(nomesCmd, contains('Capacidade de tropas'));
    // E as tropas continuam com esses atributos.
    final tropasModel = await repo.getTemplatesByGroup(
        subs.firstWhere((g) => g.name == 'Tropas').id!);
    expect(tropasModel.map((t) => t.name).toSet(),
        containsAll({'Ataque', 'Defesa', 'Vida'}));

    // O jogo renomeia os tipos: "Herói" aparece como "Comandante".
    final nomesTipo = await repo.getEffectiveTypeNames(cmd.id!);
    expect(nomesTipo.labelOf(CharacterType.heroi), 'Comandante');

    final commanders = await repo.getCharactersByGroup(cmd.id!);
    expect(commanders.length, 6);
    expect(commanders.map((c) => c.name),
        containsAll(['Cao Cao', 'Cipião Africano', 'Yi Seong-Gye']));

    // Habilidade sempre aponta pra um status que EXISTE (o toggle funciona).
    final caoCao = commanders.firstWhere((c) => c.name == 'Cao Cao');

    // Comandante do exemplo já nasce com foto (avatar desenhado pelo app).
    expect(caoCao.iconImagePath, isNotNull);
    expect(File(caoCao.iconImagePath!).existsSync(), isTrue);

    final statNames =
        (await repo.getStatsByCharacter(caoCao.id!)).map((s) => s.name).toSet();
    final abilities = await repo.getAbilitiesByCharacter(caoCao.id!);
    expect(abilities, isNotEmpty);
    for (final a in abilities) {
      expect(statNames.contains(a.targetStatName), isTrue,
          reason: 'habilidade "${a.name}" aponta para status inexistente '
              '"${a.targetStatName}"');
    }

    // Árvore de talentos dos comandantes existe e está religada.
    final tree = await repo.getSkillNodes(cmd.id!);
    expect(tree.any((n) => n.parentId == null), isTrue);
    expect(tree.any((n) => n.parentId != null), isTrue);

    // Tropas: o status "Vantagem contra" é do tipo Gatilho e tem texto.
    final troops = subs.firstWhere((g) => g.name == 'Tropas');
    final inf = (await repo.getCharactersByGroup(troops.id!))
        .firstWhere((c) => c.name.startsWith('Infantaria'));
    final vantagem = (await repo.getStatsByCharacter(inf.id!))
        .firstWhere((s) => s.name == 'Vantagem contra');
    expect(vantagem.type, StatType.trigger);
    expect(vantagem.triggerText, isNotNull);
  });

  test('refazer o exemplo remove o antigo em vez de empilhar', () async {
    await wipe();
    await seed.createExample();
    expect(await seed.exampleExists(), isTrue);

    // remove tudo (raiz + sub-grupos + conteúdo).
    await seed.removeExample();
    expect(await seed.exampleExists(), isFalse);
    expect(await repo.getAllGroups(), isEmpty);

    // O fluxo do botão "Refazer": remover e criar de novo dá exatamente 1.
    await seed.createExample();
    await seed.removeExample();
    await seed.createExample();
    final examples = (await repo.getRootGroups())
        .where((g) => g.name == SeedService.exampleGroupName);
    expect(examples.length, 1);
  });
}
