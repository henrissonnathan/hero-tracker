// Teste de paridade de migração (Fase 1 do roadmap):
// um banco criado do ZERO na versão atual precisa ter as MESMAS tabelas e
// colunas de um banco criado na v1 e migrado passo a passo até a versão atual.
// Se alguém esquecer de espelhar uma mudança entre _onCreate e _onUpgrade,
// este teste grita.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hero_tracker/repositories/database_helper.dart';

late Directory _tempDir;
int _dbSeq = 0;

/// Abre um banco NOVO e isolado em arquivo temporário ( :memory: do FFI
/// compartilhava instância entre aberturas no mesmo isolate ).
Future<Database> _openIsolated() async {
  final path = '${_tempDir.path}${Platform.pathSeparator}parity_${_dbSeq++}.db';
  await databaseFactory.deleteDatabase(path);
  return databaseFactory.openDatabase(path);
}

/// Schema REAL da v1 (reconstruído do _onCreate original menos as migrações
/// v2+ — ver histórico no CLAUDE.md). Fixture congelada: NÃO atualizar quando
/// o schema evoluir; é o ponto de partida do caminho de migração.
const _v1Schema = [
  '''
  CREATE TABLE game_groups (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    description TEXT,
    iconEmoji   TEXT DEFAULT '⚔️',
    createdAt   TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE characters (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    groupId      INTEGER NOT NULL,
    name         TEXT NOT NULL,
    role         TEXT,
    notes        TEXT,
    starStars    INTEGER DEFAULT 0,
    starSubLevel INTEGER DEFAULT 0,
    createdAt    TEXT NOT NULL,
    FOREIGN KEY (groupId) REFERENCES game_groups(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE character_stats (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    characterId INTEGER NOT NULL,
    name        TEXT NOT NULL,
    type        TEXT NOT NULL,
    value       REAL DEFAULT 0,
    maxValue    REAL,
    triggerText TEXT,
    sortOrder   INTEGER DEFAULT 0,
    FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
  )
  ''',
];

// NOTA (divergência de FK aceita como fóssil): este teste compara TABELAS e
// COLUNAS, não constraints. Há uma divergência conhecida: um banco muito antigo
// que passou por v1→v2 ganhou game_groups.parentId via ALTER (que no SQLite não
// cria FK), enquanto um banco novo declara a FK no _onCreate. Corrigir exigiria
// RECONSTRUIR a tabela (proibido por L1). O CASCADE de sub-grupos funciona em
// todo banco criado a partir da v2+; só bancos pré-históricos não têm a FK.
Future<Map<String, Set<String>>> _tableColumns(Database db) async {
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
  final result = <String, Set<String>>{};
  for (final t in tables) {
    final name = t['name'] as String;
    final cols = await db.rawQuery('PRAGMA table_info($name)');
    result[name] = cols.map((c) => c['name'] as String).toSet();
  }
  return result;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _tempDir = Directory.systemTemp.createTempSync('hero_tracker_parity');
  });

  tearDownAll(() {
    try {
      _tempDir.deleteSync(recursive: true);
    } catch (_) {/* arquivos podem estar em uso no Windows */}
  });

  test('paridade: banco do zero == banco migrado v1 → v${DatabaseHelper.schemaVersion}',
      () async {
    // Banco A: criado do zero na versão atual (onCreate real).
    final fresh = await _openIsolated();
    await DatabaseHelper.createSchemaForTest(fresh);

    // Banco B: schema v1 + todas as migrações reais (onUpgrade).
    final migrated = await _openIsolated();
    for (final sql in _v1Schema) {
      await migrated.execute(sql);
    }
    await DatabaseHelper.runMigrationsForTest(
        migrated, 1, DatabaseHelper.schemaVersion);

    final freshTables = await _tableColumns(fresh);
    final migratedTables = await _tableColumns(migrated);

    expect(migratedTables.keys.toSet(), freshTables.keys.toSet(),
        reason: 'conjunto de tabelas diverge entre onCreate e onUpgrade');
    for (final table in freshTables.keys) {
      expect(migratedTables[table], freshTables[table],
          reason: 'colunas da tabela $table divergem entre criar e migrar');
    }

    await fresh.close();
    await migrated.close();
  });

  test('caminho parcial v5 → atual também converge (guard do PRAGMA na v7)',
      () async {
    // Banco na v5: v1 + migrações reais até 5, depois 5 → atual.
    final db = await _openIsolated();
    for (final sql in _v1Schema) {
      await db.execute(sql);
    }
    await DatabaseHelper.runMigrationsForTest(db, 1, 5);
    await DatabaseHelper.runMigrationsForTest(
        db, 5, DatabaseHelper.schemaVersion);

    final fresh = await _openIsolated();
    await DatabaseHelper.createSchemaForTest(fresh);

    expect(await _tableColumns(db), await _tableColumns(fresh));
    await db.close();
    await fresh.close();
  });
}
