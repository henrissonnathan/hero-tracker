import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper de banco de dados SQLite para o Hero Tracker.
class DatabaseHelper {
  static const _dbName = 'hero_tracker.db';
  static const _dbVersion = 11;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      // Desktop: pasta de dados do app (%APPDATA%) — o default do FFI
      // resolve relativo ao CWD e o banco "sumiria" conforme de onde
      // o .exe é lançado.
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, _dbName);
    } else {
      // Android: caminho atual intocado (L1)
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
    }
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// FK sempre ligada, em TODA conexão (antes só era ativada dentro de dois
  /// deletes — o comportamento variava conforme o histórico da sessão).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ─── Hooks de teste (Fase 1) ───────────────────────────────────────────────
  // Delegam para os métodos privados de produção — nunca duplicam schema.

  /// Versão atual do schema (para os testes de paridade).
  static int get schemaVersion => _dbVersion;

  /// Cria o schema atual (onCreate real) num banco arbitrário de teste.
  static Future<void> createSchemaForTest(Database db) =>
      DatabaseHelper.instance._onCreate(db, _dbVersion);

  /// Roda as migrações reais (onUpgrade) de [from] até [to] num banco de teste.
  static Future<void> runMigrationsForTest(Database db, int from, int to) =>
      DatabaseHelper.instance._onUpgrade(db, from, to);

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE game_groups (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        parentId              INTEGER,
        name                  TEXT NOT NULL,
        description           TEXT,
        iconEmoji             TEXT DEFAULT '⚔️',
        createdAt             TEXT NOT NULL,
        maxHeroesPerSquad     INTEGER,
        maxCommandersPerSquad INTEGER,
        contentCategory       TEXT NOT NULL DEFAULT 'general',
        iconImagePath         TEXT,
        FOREIGN KEY (parentId) REFERENCES game_groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE characters (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId       INTEGER NOT NULL,
        name          TEXT NOT NULL,
        role          TEXT,
        notes         TEXT,
        starStars     INTEGER DEFAULT 0,
        starSubLevel  INTEGER DEFAULT 0,
        createdAt     TEXT NOT NULL,
        characterType TEXT DEFAULT 'soldadoNormal',
        level         INTEGER NOT NULL DEFAULT 1,
        iconImagePath TEXT,
        FOREIGN KEY (groupId) REFERENCES game_groups(id) ON DELETE CASCADE
      )
    ''');

    await _createSkillNodesTable(db);

    await db.execute('''
      CREATE TABLE character_stats (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        characterId INTEGER NOT NULL,
        name        TEXT NOT NULL,
        type        TEXT NOT NULL,
        value       REAL DEFAULT 0,
        maxValue    REAL,
        triggerText TEXT,
        formulaText TEXT,
        sortOrder   INTEGER DEFAULT 0,
        FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await _createGroupStatTemplatesTable(db);
    await _createCharacterAbilitiesTable(db);
    await _createUnitTypeLabelsTable(db);
  }

  /// Executa migrações incrementais.
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2 && newV >= 2) {
      // v1 → v2: parentId em game_groups, skill_nodes, formulaText em stats
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN parentId INTEGER');
      await _createSkillNodesTable(db);
      await db.execute(
          'ALTER TABLE character_stats ADD COLUMN formulaText TEXT');
    }
    if (oldV < 3 && newV >= 3) {
      // v2 → v3: characterType em characters; maxHeroes/maxCommanders em game_groups
      await db.execute(
          "ALTER TABLE characters ADD COLUMN characterType TEXT DEFAULT 'soldadoNormal'");
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN maxHeroesPerSquad INTEGER');
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN maxCommandersPerSquad INTEGER');
    }
    if (oldV < 4 && newV >= 4) {
      // v3 → v4: level em characters; contentCategory em game_groups
      await db.execute(
          'ALTER TABLE characters ADD COLUMN level INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          "ALTER TABLE game_groups ADD COLUMN contentCategory TEXT NOT NULL DEFAULT 'general'");
    }
    if (oldV < 5 && newV >= 5) {
      // v4 → v5: foto interna como ícone do grupo (opcional)
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN iconImagePath TEXT');
    }
    if (oldV < 6 && newV >= 6) {
      // v5 → v6: templates de estatística no nível do grupo — todo
      // personagem novo do grupo nasce com esses stats copiados.
      await _createGroupStatTemplatesTable(db);
    }
    if (oldV < 7 && newV >= 7) {
      // v6 → v7: categoria opcional para classificar/agrupar os templates.
      // Guarda contra coluna duplicada: um DB vindo de v5 nesta MESMA execução
      // já ganha a coluna via _createGroupStatTemplatesTable (que agora cria v7).
      final cols =
          await db.rawQuery('PRAGMA table_info(group_stat_templates)');
      final hasCategory = cols.any((c) => c['name'] == 'category');
      if (!hasCategory) {
        await db.execute(
            'ALTER TABLE group_stat_templates ADD COLUMN category TEXT');
      }
    }
    if (oldV < 8 && newV >= 8) {
      // v7 → v8: "Contagem" foi removida — dados existentes viram "Número".
      await db.execute(
          "UPDATE character_stats SET type = 'number' WHERE type = 'count'");
      await db.execute(
          "UPDATE group_stat_templates SET type = 'number' WHERE type = 'count'");
    }
    if (oldV < 9 && newV >= 9) {
      // v8 → v9: habilidades de herói (descrição + gatilho + efeito em stat).
      await _createCharacterAbilitiesTable(db);
    }
    if (oldV < 10 && newV >= 10) {
      // v9 → v10: foto interna do herói/tropa (mesmo cofre seguro do grupo).
      await db.execute(
          'ALTER TABLE characters ADD COLUMN iconImagePath TEXT');
    }
    if (oldV < 11 && newV >= 11) {
      // v10 → v11: nome/emoji que CADA JOGO dá aos tipos de unidade
      // (renomear "Herói" para "Comandante" sem mexer em código).
      await _createUnitTypeLabelsTable(db);
    }
  }

  Future<void> _createUnitTypeLabelsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unit_type_labels (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId INTEGER NOT NULL,
        typeKey TEXT NOT NULL,
        label   TEXT NOT NULL,
        emoji   TEXT,
        UNIQUE (groupId, typeKey) ON CONFLICT REPLACE,
        FOREIGN KEY (groupId) REFERENCES game_groups(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCharacterAbilitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS character_abilities (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        characterId    INTEGER NOT NULL,
        name           TEXT NOT NULL,
        description    TEXT,
        triggerText    TEXT,
        targetStatName TEXT,
        bonusValue     REAL DEFAULT 0,
        bonusKind      TEXT DEFAULT 'flat',
        isActive       INTEGER DEFAULT 0,
        sortOrder      INTEGER DEFAULT 0,
        FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createGroupStatTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_stat_templates (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId      INTEGER NOT NULL,
        name         TEXT NOT NULL,
        type         TEXT NOT NULL,
        defaultValue REAL DEFAULT 0,
        maxValue     REAL,
        triggerText  TEXT,
        formulaText  TEXT,
        sortOrder    INTEGER DEFAULT 0,
        category     TEXT,
        FOREIGN KEY (groupId) REFERENCES game_groups(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSkillNodesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS skill_nodes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId      INTEGER NOT NULL,
        parentId     INTEGER,
        name         TEXT NOT NULL,
        description  TEXT,
        iconEmoji    TEXT DEFAULT '🔷',
        isUnlocked   INTEGER DEFAULT 0,
        costPoints   INTEGER DEFAULT 1,
        sortOrder    INTEGER DEFAULT 0,
        FOREIGN KEY (groupId)  REFERENCES game_groups(id) ON DELETE CASCADE,
        FOREIGN KEY (parentId) REFERENCES skill_nodes(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> enableForeignKeys() async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
