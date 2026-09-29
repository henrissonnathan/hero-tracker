// Testes do formulário de status (usabilidade): o tipo se escolhe pelo nome
// ou por cartão, a fórmula se monta TOCANDO (sem digitar × ÷), gatilho já
// usado entra com um toque, e os operadores têm nome falado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hero_tracker/models/stat_type.dart';
import 'package:hero_tracker/ui/widgets/stat_form_dialog.dart';

void main() {
  /// Abre o dialog e devolve uma função que lê o resultado depois do Salvar.
  Future<StatFormResult? Function()> abrir(
    WidgetTester tester, {
    List<String> nomes = const [],
    List<String> gatilhos = const [],
  }) async {
    StatFormResult? resultado;
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              resultado = await showDialog<StatFormResult>(
                context: context,
                builder: (_) => StatFormDialog(
                  title: 'Novo',
                  availableStatNames: nomes,
                  knownTriggers: gatilhos,
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () => resultado;
  }

  Future<void> salvar(WidgetTester tester) async {
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }

  testWidgets('nome com "Bônus" já escolhe Porcentagem; atalho 10% preenche',
      (tester) async {
    final ler = await abrir(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nome do status'), 'Bônus de ataque');
    await tester.pump();
    expect(find.textContaining('Escolhido pelo nome'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '10%'));
    await tester.pump();
    await salvar(tester);

    final r = ler()!;
    expect(r.type, StatType.percent);
    expect(r.value, 10);
  });

  testWidgets('fórmula se monta tocando nos nomes e nos operadores',
      (tester) async {
    final ler = await abrir(tester, nomes: ['Ataque', 'Defesa']);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nome do status'), 'Poder');
    await tester.tap(find.text('Fórmula'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'Ataque'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('vezes'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Defesa'));
    await tester.pump();
    await salvar(tester);

    final r = ler()!;
    expect(r.type, StatType.formula);
    expect(r.formulaText, 'Ataque × Defesa');
  });

  testWidgets('gatilho já usado no jogo entra com um toque', (tester) async {
    final ler = await abrir(tester, gatilhos: ['defendendo a base', '']);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nome do status'), 'Muralha');
    await tester.tap(find.text('Gatilho'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'defendendo a base'));
    await tester.pump();
    await salvar(tester);

    final r = ler()!;
    expect(r.type, StatType.trigger);
    expect(r.triggerText, 'defendendo a base');
  });

  testWidgets('sem nome não salva e avisa no próprio campo', (tester) async {
    final ler = await abrir(tester);
    await salvar(tester);
    expect(find.text('Dê um nome ao status'), findsOneWidget);
    expect(ler(), isNull);
  });
}
