import '../models/game_group.dart';
import '../models/character.dart';
import '../models/character_stat.dart';
import '../models/group_stat_template.dart';
import '../models/skill_node.dart';
import 'database_helper.dart';

/// Repositório principal — acesso a dados via SQLite.
class TrackerRepository {
  TrackerRepository._();
  static final TrackerRepository instance = TrackerRepository._();

  // ─── GameGroup ────────────────────────────────────────────────────────────

  /// Retorna apenas os grupos raiz (sem pai).
  Future<List<GameGroup>> getRootGroups() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'game_groups',
      where: 'parentId IS NULL',
      orderBy: 'createdAt ASC',
    );
    return rows.map(GameGroup.fromMap).toList();
  }

  /// Retorna todos os grupos (para exportação).
  Future<List<GameGroup>> getAllGroups() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('game_groups', orderBy: 'createdAt ASC');
    return rows.map(GameGroup.fromMap).toList();
  }

  /// Caminhos de foto de ícone em uso por algum grupo (varredura de órfãos).
  Future<List<String>> getAllIconImagePaths() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'game_groups',
      columns: ['iconImagePath'],
      where: 'iconImagePath IS NOT NULL',
    );
    return rows
        .map((r) => r['iconImagePath'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Retorna um grupo pelo id, ou null se não existir.
  Future<GameGroup?> getGroupById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'game_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameGroup.fromMap(rows.first);
  }

  /// Retorna sub-grupos diretos de [parentId].
  Future<List<GameGroup>> getSubGroups(int parentId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'game_groups',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(GameGroup.fromMap).toList();
  }

  Future<GameGroup> insertGroup(GameGroup group) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('game_groups', group.toMap());
    return group.copyWith(id: id);
  }

  Future<void> updateGroup(GameGroup group) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'game_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(int id) async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.enableForeignKeys();
    await db.delete('game_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Character ────────────────────────────────────────────────────────────

  Future<List<Character>> getCharactersByGroup(int groupId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'characters',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Character.fromMap).toList();
  }

  Future<Character> insertCharacter(Character character) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('characters', character.toMap());
    return character.copyWith(id: id);
  }

  Future<void> updateCharacter(Character character) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<void> deleteCharacter(int id) async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.enableForeignKeys();
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CharacterStat ────────────────────────────────────────────────────────

  Future<List<CharacterStat>> getStatsByCharacter(int characterId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'character_stats',
      where: 'characterId = ?',
      whereArgs: [characterId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(CharacterStat.fromMap).toList();
  }

  Future<CharacterStat> insertStat(CharacterStat stat) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('character_stats', stat.toMap());
    return stat.copyWith(id: id);
  }

  Future<void> updateStat(CharacterStat stat) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'character_stats',
      stat.toMap(),
      where: 'id = ?',
      whereArgs: [stat.id],
    );
  }

  Future<void> deleteStat(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('character_stats', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SkillNode ────────────────────────────────────────────────────────────

  Future<List<SkillNode>> getSkillNodes(int groupId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'skill_nodes',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(SkillNode.fromMap).toList();
  }

  Future<SkillNode> insertSkillNode(SkillNode node) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('skill_nodes', node.toMap());
    return node.copyWith(id: id);
  }

  Future<void> updateSkillNode(SkillNode node) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'skill_nodes',
      node.toMap(),
      where: 'id = ?',
      whereArgs: [node.id],
    );
  }

  Future<void> deleteSkillNode(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('skill_nodes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderStats(List<CharacterStat> stats) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (int i = 0; i < stats.length; i++) {
      batch.update(
        'character_stats',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [stats[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ─── GroupStatTemplate ────────────────────────────────────────────────────

  /// Templates definidos diretamente em [groupId] (não considera herança).
  Future<List<GroupStatTemplate>> getTemplatesByGroup(int groupId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'group_stat_templates',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(GroupStatTemplate.fromMap).toList();
  }

  /// Templates efetivos de [groupId]: os próprios, ou — se não houver —
  /// os do ancestral mais próximo que tiver templates definidos.
  Future<List<GroupStatTemplate>> getEffectiveTemplates(int groupId) async {
    final visited = <int>{};
    int? currentId = groupId;
    // visited.add retorna false se o id já foi visitado — corta ciclos de
    // parentId (ex.: dado corrompido/importado) sem loop infinito.
    while (currentId != null && visited.add(currentId)) {
      final templates = await getTemplatesByGroup(currentId);
      if (templates.isNotEmpty) return templates;
      final group = await getGroupById(currentId);
      currentId = group?.parentId;
    }
    return [];
  }

  Future<GroupStatTemplate> insertTemplate(GroupStatTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('group_stat_templates', template.toMap());
    return template.copyWith(id: id);
  }

  Future<void> updateTemplate(GroupStatTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'group_stat_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteTemplate(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('group_stat_templates', where: 'id = ?', whereArgs: [id]);
  }

  /// Copia os templates efetivos do grupo de [character] para
  /// character_stats — chamado ao criar um personagem novo. É uma cópia de
  /// valores (não referência): mudanças futuras no template não afetam o
  /// personagem.
  /// [onlyTemplateIds]: se informado, copia apenas os templates com esses ids
  /// (escolha feita nas caixinhas do dialog de criação). null = todos (padrão).
  Future<void> applyGroupTemplatesToCharacter(
    Character character, {
    Set<int>? onlyTemplateIds,
  }) async {
    final templates = await getEffectiveTemplates(character.groupId);
    for (final template in templates) {
      if (onlyTemplateIds != null && !onlyTemplateIds.contains(template.id)) {
        continue;
      }
      await insertStat(template.toCharacterStat(character.id!));
    }
  }
}
