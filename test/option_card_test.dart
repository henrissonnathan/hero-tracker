// Widgets de padrão do app (docs/PADROES-UI.md): OptionCard/EmojiChoice
// (escolha acessível, 48×48) e ItemActionsMenu + confirmDelete (⋮ e
// confirmação antes de apagar).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hero_tracker/ui/widgets/item_actions.dart';
import 'package:hero_tracker/ui/widgets/option_card.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('OptionCard: toque escolhe, fala "selecionado" e tem 48×48',
      (tester) async {
    final h = tester.ensureSemantics();
    var tocou = 0;
    await tester.pumpWidget(_app(Wrap(children: [
      OptionCard(
        selected: true,
        semanticLabel: 'Categoria Heróis',
        onTap: () => tocou++,
        child: const Text('⚔️'),
      ),
    ])));

    final card = find.byType(OptionCard);
    final tamanho = tester.getSize(card);
    expect(tamanho.width, greaterThanOrEqualTo(48));
    expect(tamanho.height, greaterThanOrEqualTo(48));
    expect(tamanho.width, lessThan(200),
        reason: 'dentro de Wrap não pode esticar na largura toda');

    // O leitor de tela precisa de um botão que FAZ algo: ação de toque e
    // foco (a revisão pegou a versão sem ação — "botão" mudo no TalkBack).
    final node = tester.getSemantics(card);
    expect(
        node,
        isSemantics(
            label: 'Categoria Heróis',
            isSelected: true,
            isButton: true,
            hasTapAction: true,
            isFocusable: true));

    await tester.tap(card);
    expect(tocou, 1);
    // Toque duplo do TalkBack/Narrador = ação de toque do nó.
    tester.semantics.tap(find.semantics.byLabel('Categoria Heróis'));
    await tester.pump();
    expect(tocou, 2);
    h.dispose();
  });

  testWidgets('OptionCard pelo teclado: Tab chega e Enter escolhe',
      (tester) async {
    var escolhido = '';
    await tester.pumpWidget(_app(Row(mainAxisSize: MainAxisSize.min, children: [
      for (final nome in ['Soldado', 'Herói'])
        OptionCard(
          selected: escolhido == nome,
          semanticLabel: 'Tipo $nome',
          onTap: () => escolhido = nome,
          child: Text(nome),
        ),
    ])));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(escolhido, 'Herói');
  });

  testWidgets('EmojiChoice é um quadrado de 48×48', (tester) async {
    await tester.pumpWidget(_app(
        EmojiChoice(emoji: '🐉', selected: false, onTap: () {})));
    expect(tester.getSize(find.byType(EmojiChoice)), const Size(48, 48));
  });

  testWidgets('⋮ mostra Editar/Apagar; Apagar só confirma no botão Apagar',
      (tester) async {
    var editou = 0;
    final respostas = <bool>[];
    await tester.pumpWidget(_app(Builder(
      builder: (context) => ItemActionsMenu(
        itemName: 'Cao Cao',
        onEdit: () => editou++,
        onDelete: () async => respostas
            .add(await confirmDelete(context, itemName: 'Cao Cao')),
      ),
    )));

    await tester.tap(find.byTooltip('Ações de "Cao Cao"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(editou, 1);

    // Cancelar não apaga.
    await tester.tap(find.byTooltip('Ações de "Cao Cao"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar "Cao Cao"?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Confirmar apaga.
    await tester.tap(find.byTooltip('Ações de "Cao Cao"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
    await tester.pumpAndSettle();
    expect(respostas, [false, true]);
  });
}
