import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper de banco de dados SQLite para o Hero Tracker.
class DatabaseHelper {
  static const _dbName = 'hero_tracker.db';
  static const _dbVersion = 3;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

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
  }

  /// Executa migrações incrementais.
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // v1 → v2: parentId em game_groups, skill_nodes, formulaText em stats
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN parentId INTEGER');
      await _createSkillNodesTable(db);
      await db.execute(
          'ALTER TABLE character_stats ADD COLUMN formulaText TEXT');
    }
    if (oldV < 3) {
      // v2 → v3: characterType em characters; maxHeroes/maxCommanders em game_groups
      await db.execute(
          "ALTER TABLE characters ADD COLUMN characterType TEXT DEFAULT 'soldadoNormal'");
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN maxHeroesPerSquad INTEGER');
      await db.execute(
          'ALTER TABLE game_groups ADD COLUMN maxCommandersPerSquad INTEGER');
    }
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
