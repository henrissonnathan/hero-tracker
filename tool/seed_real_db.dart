// Ferramenta de DESENVOLVIMENTO — NÃO faz parte do app.
//
// O app continua entrando por lib/main.dart; este arquivo é um segundo entry
// point, rodado à mão só quando se quer o mapa de exemplo já gravado no banco
// REAL do PC (o mesmo %APPDATA% que o app usa), sem precisar clicar no menu:
//
//   flutter run -t tool/seed_real_db.dart -d windows
//
// Por que um app Flutter em vez de um script Dart puro: o caminho do banco vem
// do path_provider, que só existe dentro do engine. Assim ele grava no MESMO
// arquivo do app — e reusa o SeedService de verdade, sem SQL duplicado aqui.
//
// Efeito: se o exemplo já existir, é REFEITO (apaga o antigo e monta a versão
// nova) — exatamente o que o botão "Refazer" da Home faz. Nenhum outro grupo é
// tocado. A janela mostra o resultado e pode ser fechada.
import 'package:flutter/material.dart';

import 'package:hero_tracker/repositories/desktop_database_init.dart';
import 'package:hero_tracker/services/seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDesktopDatabaseFactory();

  final seed = SeedService.instance;
  String resultado;
  try {
    final jaExistia = await seed.exampleExists();
    if (jaExistia) await seed.removeExample();
    final root = await seed.createExample();
    resultado = jaExistia
        ? 'Exemplo REFEITO: "${root.name}" (id ${root.id}).'
        : 'Exemplo CRIADO: "${root.name}" (id ${root.id}).';
  } catch (e) {
    resultado = 'FALHOU: $e';
  }

  debugPrint('[seed_real_db] $resultado');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(resultado, textAlign: TextAlign.center),
        ),
      ),
    ),
  ));
}
