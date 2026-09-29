// Alvo de toque >= 48×48 (WCAG 2.5.5 / regra A11Y) nas telas principais.
// Mede CADA botão direto — o `androidTapTargetGuideline` sozinho é cego a
// botão pequeno dentro de um nó de semântica fundido (card/linha clicável).
// Roda com o TEMA REAL do app (sem a fonte) em Android E Windows: no
// Windows o Flutter encolhe botões por padrão, e é lá que o dono testa.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_ability.dart';
import 'package:hero_tracker/models/character_stat.dart';
import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/skill_node.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/theme/app_theme.dart';
import 'package:hero_tracker/ui/character_screen.dart';
import 'package:hero_tracker/ui/game_screen.dart';
import 'package:hero_tracker/ui/skill_tree_screen.dart';
import 'package:hero_tracker/ui/stats_screen.dart';
import 'package:hero_tracker/ui/widgets/option_card.dart';

import 'test_helpers.dart';

const _plataformas = TargetPlatformVariant(
    {TargetPlatform.android, TargetPlatform.windows});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_alvo');
  final repo = TrackerRepository.instance;
  late GameGroup g;
  late Character c;

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
    } catch (_) {/* banco aberto no Windows */}
  });

  /// Um jogo com sub-grupo, modelo, herói (status + habilidade) e nó.
  Future<void> dados(WidgetTester tester) => tester.runAsync(() async {
        for (final r in await repo.getRootGroups()) {
          await repo.deleteGroup(r.id!);
        }
        g = await repo.insertGroup(
            GameGroup(name: 'Jogo', createdAt: DateTime(2026)));
        await repo.insertGroup(GameGroup(
            name: 'Sub', parentId: g.id, createdAt: DateTime(2026)));
        await repo.insertTemplate(GroupStatTemplate(
            groupId: g.id!,
            name: 'Ataque',
            type: StatType.number,
            category: 'Combate'));
        c = await repo.insertCharacter(Character(
            groupId: g.id!,
            name: 'Cao Cao',
            characterType: CharacterType.heroi,
            createdAt: DateTime(2026)));
        await repo.insertStat(CharacterStat(
            characterId: c.id!,
            name: 'Ataque',
            type: StatType.number,
            value: 5));
        await repo.insertAbility(CharacterAbility(
            characterId: c.id!,
            name: 'Carga',
            targetStatName: 'Ataque',
            bonusValue: 10));
        await repo.insertSkillNode(SkillNode(groupId: g.id!, name: 'Nó A'));
      });

  Future<void> abrir(WidgetTester tester, Widget tela, Finder pronto) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.buildDark(), home: tela));
    await pumpUntilFound(tester, pronto);
    await pumpUntilGone(tester, find.byType(CircularProgressIndicator));
  }

  /// Todo botão/opção visível com no mínimo 48×48 (+ guideline do Flutter).
  Future<void> todosComAlvo48(WidgetTester tester, String onde) async {
    final alvos = find.byWidgetPredicate((w) =>
        w is IconButton ||
        w is ButtonStyleButton ||
        w is FloatingActionButton ||
        w is RawChip ||
        w is OptionCard);
    expect(alvos, findsWidgets, reason: onde);
    final pequenos = <String>[];
    for (final e in alvos.evaluate()) {
      final box = e.renderObject;
      if (box is! RenderBox || !box.hasSize) continue;
      final s = box.size;
      if (s.width < 48 || s.height < 48) {
        pequenos.add('${e.widget.runtimeType} '
            '${s.width.toStringAsFixed(0)}×${s.height.toStringAsFixed(0)}');
      }
    }
    expect(pequenos, isEmpty, reason: '$onde: alvos menores que 48×48');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }

  testWidgets('tela do jogo e dialog de criação: tudo >= 48×48',
      (tester) async {
    final h = tester.ensureSemantics();
    await dados(tester);
    await abrir(tester, GameScreen(group: g), find.text('Cao Cao'));
    await todosComAlvo48(tester, 'tela do jogo');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Status do modelo'));
    await tester.pumpAndSettle();
    await todosComAlvo48(tester, 'dialog Novo personagem');
    h.dispose();
  }, variant: _plataformas);

  testWidgets('tela do herói (status, habilidade, estrelas): tudo >= 48×48',
      (tester) async {
    final h = tester.ensureSemantics();
    await dados(tester);
    await abrir(tester, CharacterScreen(character: c), find.text('Carga'));
    await todosComAlvo48(tester, 'tela do herói');
    h.dispose();
  }, variant: _plataformas);

  testWidgets('árvore de habilidades: tudo >= 48×48, inclusive desbloquear',
      (tester) async {
    final h = tester.ensureSemantics();
    await dados(tester);
    await abrir(tester, SkillTreeScreen(group: g), find.text('Nó A'));
    await todosComAlvo48(tester, 'árvore');
    final bolinha = tester.getSize(find.byTooltip('Desbloquear'));
    expect(bolinha.width >= 48 && bolinha.height >= 48, isTrue,
        reason: 'bolinha de desbloquear: $bolinha');
    h.dispose();
  }, variant: _plataformas);

  testWidgets('tela de estatísticas: tudo >= 48×48', (tester) async {
    final h = tester.ensureSemantics();
    await dados(tester);
    await abrir(tester, StatsScreen(group: g), find.text('Combate'));
    await todosComAlvo48(tester, 'estatísticas');
    h.dispose();
  }, variant: _plataformas);
}
