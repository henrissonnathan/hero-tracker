---
name: hero-tracker-testes
sigla: TEST
description: >
  Especialista em testes do hero-tracker (Flutter/Dart).
  Carregue quando o chat for: escrever novos testes, corrigir testes vermelhos,
  aumentar cobertura, rodar a bateria, diagnosticar falhas, ajustar mocks/FFI,
  manter o catálogo da tela "Testes do app".
triggers: [teste, test, flutter-test, cobertura, mock, FFI, verde, vermelho, bateria, widget-test, unit-test, TESTAR]
---

# TEST — Hero Tracker Testes

## Escopo deste chat
Mantenha e expanda a **bateria de testes**. Estado em 2026-09-29: 51 testes
verdes (commit e6fc3ce). Antes de entregar: ≥ contagem anterior e todos verdes.
Teste vermelho: diagnosticar → corrigir → re-rodar, no máximo 3 voltas; na
3ª sem sucesso, pare e devolva ao CENT com o diagnóstico (anti-loop).

### Pode tocar em
```
test/*.dart
lib/ui/tests_info_screen.dart   ← SÓ a lista TestsInfo (groups/manual/ideas)
docs/TESTES.md                  ← espelho do catálogo
```
Em lib/ fora disso: **somente** para expor gancho testável (padrão existente:
`DatabaseHelper.createSchemaForTest` / `runMigrationsForTest`,
`HeroTrackerApp(theme:)`) — sem mudar comportamento. Bug de verdade em lib/ →
não conserte aqui: escreva o teste que prova o bug e devolva ao CENT.

### NÃO pode tocar em
- Regra de negócio, schema, visual — só descreva o defeito no handoff
- Nunca "conserte" um teste afrouxando o assert para passar: primeiro decida
  se o CÓDIGO ou o TESTE está errado (debugging root-cause)

## Arquivos (13)
| arquivo | cobre |
|---|---|
| widget_test | app real abre; GroupIcon; StatsScreen por categoria |
| stat_form_dialog_test | tipo por nome, fórmula por toque, gatilho reuso |
| stats_layout_test | status em 1/2/3 colunas (mede posição) |
| character_photo_test | foto de herói, órfãos, backup sem caminho |
| export_import_test | backup round-trip, ciclo, limites, versão |
| group_pack_test | pacote de um jogo (JSON à mão, não sobrescreve) |
| migration_parity_test | banco novo == migrado v1→atual; v5→atual |
| model_roundtrip_test | todo campo sobrevive toMap/fromMap |
| group_stat_template_test | herança, cópia, FK, habilidades |
| seed_service_test | exemplo RoK coerente, refazer não empilha |
| unit_type_label_test | nomes dos tipos por jogo, herança |
| tests_info_test | tela de testes + CONTA os testes |
| test_helpers | `pumpUntilFound` / `pumpUntilGone` |

⚠️ Teste novo ou removido → atualizar `TestsInfo` em
`lib/ui/tests_info_screen.dart` E `docs/TESTES.md`. O `tests_info_test` conta
com a regex `^\s*(test|testWidgets)\s*\(` (multiLine) em test/*.dart e fica
vermelho se não bater com `TestsInfo.totalTests`. Consequência: helper
chamado `test(` no início da linha também conta — não nomeie assim.

## Tiers de teste (L5)
| Tier       | O que testa                        |
|------------|------------------------------------|
| unit       | model/service isolado, sem banco   |
| widget     | widget em tela (pump + find)       |
| db         | CRUD real com SQLite FFI           |
| regression | bug específico que voltou          |
Widget novo em lib/ui → no mínimo 1 teste de widget (lei L5).

## Como rodar (nesta máquina)
```bash
export PATH="/c/flutter/bin:$PATH"        # flutter fora do PATH do bash
flutter test --no-pub                               # tudo (~40 s)
flutter test --no-pub test/export_import_test.dart  # arquivo único
flutter analyze --fatal-infos --no-pub              # info também reprova
bash scripts/enxuto.sh /c/flutter/bin/flutter.bat test --no-pub  # saída curta
```
Saída completa do enxuto: `.dart_tool/saida-enxuta/`. Portão oficial:
`TESTAR.bat` (= testes.ps1: analyze --fatal-infos + test).
`--no-pub` evita o `pub get`, que falha com "requires symlink support" quando o
Modo Desenvolvedor do Windows está desligado. Pacote sumiu do cache ("Target
of URI doesn't exist" em massa)? Rode `flutter pub get` uma vez — baixa mesmo
reclamando de symlink (E28).

## Setup do banco em teste (copie de test/export_import_test.dart:24-41)
```dart
final tempDir = Directory.systemTemp.createTempSync('hero_tracker_<nome>');
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async => tempDir.path,
  );
});
tearDownAll(() { try { tempDir.deleteSync(recursive: true); } catch (_) {} });
```
- `DatabaseHelper` é singleton e pega o caminho do `path_provider`: o mock
  acima põe o banco numa pasta temporária por arquivo de teste (cada arquivo
  roda no seu isolate → banco próprio). Dentro do arquivo o banco é
  COMPARTILHADO entre testes: limpe no início (`wipe()` apagando grupos raiz).
- `inMemoryDatabasePath` só no migration_parity_test, que monta o banco por
  fora do singleton com os ganchos `createSchemaForTest`/`runMigrationsForTest`.
- Tela com fonte: `GoogleFonts.config.allowRuntimeFetching = false` e, no app
  real, `HeroTrackerApp(theme: ThemeData.dark())` (widget_test) — teste não
  tem rede.
- No Windows o `deleteSync` pode falhar com o banco aberto: engula o erro.

## Armadilhas de widget test (já aconteceram)
- Banco FFI é I/O REAL: não anda no tempo simulado. Use `tester.runAsync`
  para gravar e `pumpUntilFound(tester, finder)` para esperar — nunca
  `Future.delayed` fixo nem `pumpAndSettle` esperando o banco.
- Dialog alto: `tester.binding.setSurfaceSize(Size(900, 1400))` +
  `addTearDown(() => ...setSurfaceSize(null))`, senão o botão fica fora da tela.
- `Semantics(label:)` dentro de InkWell/botão é FUNDIDA no nó do botão:
  `find.bySemanticsLabel` não acha — use `find.byType(<Widget>)` (E29).
  Só funciona quando o próprio botão tem `excludeSemantics: true`.
- Layout em colunas: compare posição real (`tester.getTopLeft`), não só existência.

## Checklist de novo teste
- Nome descreve o comportamento esperado, em português
- Banco FFI em pasta temporária (mock acima), nunca o banco real do dono
- Um comportamento por teste; assert com `reason:` quando não for óbvio
- Roda isolado E junto com a bateria completa
- Catálogo `TestsInfo` + docs/TESTES.md atualizados (contagem!)

## Handoff
Devolva ao CENT (formato da skill `hero-tracker-central`): contagem antes →
depois, arquivos tocados, e — se achou bug em lib/ — o teste que o prova e
qual chat deve corrigir (VISL/FUNC/BANC/JSON/A11Y).
