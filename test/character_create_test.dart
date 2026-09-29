// Criação de card de herói pela TELA (Bloco C da sprint): tipo já sugerido,
// Enter cria e abre, nome vazio/repetido bloqueado no próprio campo,
// "Criar outro" fica no dialog, e o modelo escolhido com Todos/Nenhum.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/content_category.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/repositories/tracker_repository.dart';
import 'package:hero_tracker/ui/game_screen.dart';
import 'package:hero_tracker/ui/widgets/option_card.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('hero_tracker_create');
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
    } catch (_) {/* banco aberto no Windows */}
  });

  /// Jogo de heróis com 2 status no modelo (+ personagens já existentes).
  Future<GameGroup> jogo(WidgetTester tester,
      {List<String> jaExistem = const []}) async {
    late GameGroup g;
    await tester.runAsync(() async {
      for (final r in await repo.getRootGroups()) {
        await repo.deleteGroup(r.id!);
      }
      g = await repo.insertGroup(GameGroup(
          name: 'Comandantes',
          contentCategory: ContentCategory.heroes,
          createdAt: DateTime(2026)));
      await repo.insertTemplate(GroupStatTemplate(
          groupId: g.id!, name: 'Bônus de ataque', type: StatType.percent));
      await repo.insertTemplate(GroupStatTemplate(
          groupId: g.id!,
          name: 'Capacidade de tropas',
          type: StatType.number,
          sortOrder: 1));
      for (final n in jaExistem) {
        await repo.insertCharacter(Character(
            groupId: g.id!,
            name: n,
            characterType: CharacterType.heroi,
            createdAt: DateTime(2026)));
      }
    });
    return g;
  }

  /// Abre a tela do jogo e o dialog "Novo personagem".
  Future<void> abrirDialog(WidgetTester tester, GameGroup g) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: GameScreen(group: g)));
    // O "+" da AppBar tem o mesmo tooltip; o teste usa o botão redondo.
    await pumpUntilFound(tester, find.byType(FloatingActionButton));
    // Spinner de carregamento anima para sempre: pumpAndSettle travaria.
    await pumpUntilGone(tester, find.byType(CircularProgressIndicator));
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntilFound(tester, find.text('Novo personagem'));
    await tester.pumpAndSettle();
  }

  Finder campoNome() => find.widgetWithText(TextField, 'Nome');

  Future<List<Character>> doBanco(WidgetTester tester, GameGroup g) async {
    late List<Character> cs;
    await tester.runAsync(() async => cs = await repo.getCharactersByGroup(g.id!));
    return cs;
  }

  testWidgets('Enter cria com o tipo sugerido e abre a tela do herói',
      (tester) async {
    final g = await jogo(tester);
    await abrirDialog(tester, g);

    final heroi = tester.widget<OptionCard>(find.byWidgetPredicate(
        (w) => w is OptionCard && w.semanticLabel == 'Tipo Herói'));
    expect(heroi.selected, isTrue,
        reason: 'grupo de Heróis vazio já sugere herói');

    await tester.enterText(campoNome(), 'Cao Cao');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpUntilFound(tester, find.widgetWithText(AppBar, 'Cao Cao'));

    final cs = await doBanco(tester, g);
    expect(cs.single.characterType, CharacterType.heroi);
    late int nStatus;
    await tester.runAsync(() async =>
        nStatus = (await repo.getStatsByCharacter(cs.single.id!)).length);
    expect(nStatus, 2, reason: 'nasce com todos os status do modelo');
  });

  testWidgets('nome vazio ou repetido: aviso no campo e nada é gravado',
      (tester) async {
    final g = await jogo(tester, jaExistem: ['Sun Tzu']);
    await abrirDialog(tester, g);

    await tester.tap(find.text('Criar e abrir'));
    await tester.pump();
    expect(find.text('Dê um nome ao personagem'), findsOneWidget);

    await tester.enterText(campoNome(), 'sun tzu');
    await tester.tap(find.text('Criar e abrir'));
    await tester.pump();
    expect(find.text('Já existe "sun tzu" neste grupo'), findsOneWidget);

    expect(find.text('Novo personagem'), findsOneWidget,
        reason: 'o dialog continua aberto');
    expect((await doBanco(tester, g)).length, 1);
  });

  testWidgets('"Criar outro" grava, avisa e deixa o dialog pronto p/ o próximo',
      (tester) async {
    final g = await jogo(tester);
    await abrirDialog(tester, g);

    OptionCard tipo(String nome) => tester.widget<OptionCard>(
        find.byWidgetPredicate(
            (w) => w is OptionCard && w.semanticLabel == 'Tipo $nome'));
    await tester.tap(find.byWidgetPredicate(
        (w) => w is OptionCard && w.semanticLabel == 'Tipo Comandante'));
    await tester.pump();

    await tester.enterText(campoNome(), 'Boudica');
    await tester.tap(find.text('Criar outro'));
    await pumpUntilFound(tester, find.text('"Boudica" criado'));
    await tester.pump();
    final campo = tester.widget<TextField>(campoNome());
    expect(campo.controller!.text, isEmpty);
    expect(campo.focusNode!.hasFocus, isTrue,
        reason: 'foco volta no nome para digitar o próximo');
    expect(tipo('Comandante').selected, isTrue,
        reason: 'o tipo escolhido continua marcado');

    await tester.enterText(campoNome(), 'Ricardo I');
    await tester.tap(find.text('Criar outro'));
    await pumpUntilFound(tester, find.text('"Ricardo I" criado · 2 nesta vez'));

    expect(find.text('Novo personagem'), findsOneWidget);
    final nomes = (await doBanco(tester, g)).map((c) => c.name).toSet();
    expect(nomes, {'Boudica', 'Ricardo I'});
  });

  testWidgets('editar herói com nome repetido ANTIGO salva sem trocar o nome',
      (tester) async {
    // Grupos antigos (ou vindos de backup) podem ter nomes repetidos: o
    // bloqueio vale para criar/renomear, nunca para travar a edição.
    final g = await jogo(tester, jaExistem: ['Arqueiro', 'Arqueiro']);
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: GameScreen(group: g)));
    await pumpUntilFound(tester, find.text('Arqueiro'));
    await pumpUntilGone(tester, find.byType(CircularProgressIndicator));

    await tester.tap(find.byTooltip('Ações de "Arqueiro"').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate(
        (w) => w is OptionCard && w.semanticLabel == 'Tipo Comandante'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    // O pop é na hora; a animação de saída precisa de tempo simulado.
    await tester.pumpAndSettle();
    expect(find.text('Editar personagem'), findsNothing,
        reason: 'salvou e fechou — sem "Já existe"');

    // A gravação é I/O real: espera o banco refletir a edição.
    var tipos = <CharacterType>[];
    for (var i = 0; i < 40 && !tipos.contains(CharacterType.comandante); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      tipos = (await doBanco(tester, g)).map((c) => c.characterType).toList();
    }
    expect(tipos, contains(CharacterType.comandante),
        reason: 'a edição foi gravada');
  });

  testWidgets('"Nenhum" no modelo: personagem nasce sem status',
      (tester) async {
    final g = await jogo(tester);
    await abrirDialog(tester, g);

    expect(find.text('✓ 2 de 2 vão para o personagem'), findsOneWidget);
    await tester.tap(find.text('Status do modelo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nenhum'));
    await tester.pumpAndSettle();
    expect(find.text('✓ 0 de 2 vão para o personagem'), findsOneWidget);

    await tester.enterText(campoNome(), 'Tropa leve');
    await tester.tap(find.text('Criar outro'));
    await pumpUntilFound(tester, find.text('"Tropa leve" criado'));

    final c = (await doBanco(tester, g)).single;
    late int nStatus;
    await tester.runAsync(
        () async => nStatus = (await repo.getStatsByCharacter(c.id!)).length);
    expect(nStatus, 0);
  });
}
