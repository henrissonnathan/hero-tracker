// Testes da tela "Testes do app": ela abre, e — o mais importante — a conta
// bate. Se alguém criar um teste novo e esquecer de descrevê-lo na tela, o
// portão (TESTAR.bat) fica vermelho e a tela nunca vira mentira.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hero_tracker/ui/tests_info_screen.dart';

/// Conta chamadas de `test(` / `testWidgets(` em todos os arquivos de test/.
int _countRealTests() {
  final dir = Directory('test');
  final re = RegExp(r'^\s*(test|testWidgets)\s*\(', multiLine: true);
  var total = 0;
  for (final f in dir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('_test.dart')) continue;
    total += re.allMatches(f.readAsStringSync()).length;
  }
  return total;
}

void main() {
  test('a conta bate: todo teste da pasta test/ está descrito na tela', () {
    final real = _countRealTests();
    expect(
      TestsInfo.totalTests,
      real,
      reason: 'Existem $real testes em test/, mas a tela "Testes do app" '
          'descreve ${TestsInfo.totalTests}. Atualize TestsInfo.groups em '
          'lib/ui/tests_info_screen.dart (e docs/TESTES.md) para a tela '
          'continuar dizendo a verdade.',
    );
  });

  testWidgets('a tela de testes abre e mostra os blocos',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsInfoScreen()));
    await tester.pump();

    // Cabeçalho com o total e o primeiro bloco.
    expect(find.text('${TestsInfo.totalTests}'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);

    // Rolando até o fim: as ideias A–E aparecem para o dono escolher e o
    // último card também (prova que a tela rola até o fim sem estourar).
    // Rola até o ÚLTIMO card — parar no 'E' quebraria a cada bloco novo.
    await tester.scrollUntilVisible(find.text('💬 Sua vez'), 300);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('💬 Sua vez'), findsOneWidget);
  });
}
