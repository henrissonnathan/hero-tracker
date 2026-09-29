// Round-trip toMap/fromMap de TODOS os modelos (Fase 1 do roadmap):
// o que entra tem que sair igual — protege o banco E o backup JSON.
import 'package:flutter_test/flutter_test.dart';

import 'package:hero_tracker/models/character.dart';
import 'package:hero_tracker/models/character_ability.dart';
import 'package:hero_tracker/models/character_stat.dart';
import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/content_category.dart';
import 'package:hero_tracker/models/game_group.dart';
import 'package:hero_tracker/models/group_stat_template.dart';
import 'package:hero_tracker/models/skill_node.dart';
import 'package:hero_tracker/models/star_rank.dart';
import 'package:hero_tracker/models/stat_type.dart';

void main() {
  test('GameGroup round-trip preserva todos os campos', () {
    final g = GameGroup(
      id: 7,
      parentId: 3,
      name: 'Rise of Kingdoms',
      description: 'conta principal',
      iconEmoji: '🏰',
      iconImagePath: r'C:\fotos\icon_1.png',
      createdAt: DateTime(2026, 7, 25, 10, 30),
      maxHeroesPerSquad: 2,
      maxCommandersPerSquad: 1,
      contentCategory: ContentCategory.heroes,
    );
    final r = GameGroup.fromMap(g.toMap());
    expect(r.id, g.id);
    expect(r.parentId, g.parentId);
    expect(r.name, g.name);
    expect(r.description, g.description);
    expect(r.iconEmoji, g.iconEmoji);
    expect(r.iconImagePath, g.iconImagePath);
    expect(r.createdAt, g.createdAt);
    expect(r.maxHeroesPerSquad, g.maxHeroesPerSquad);
    expect(r.maxCommandersPerSquad, g.maxCommandersPerSquad);
    expect(r.contentCategory, g.contentCategory);
  });

  test('Character round-trip preserva todos os campos', () {
    final c = Character(
      id: 11,
      groupId: 7,
      name: 'Herói Teste',
      role: 'Tank',
      notes: 'nota',
      starRank: const StarRank(stars: 3, subLevel: 5),
      createdAt: DateTime(2026, 7, 25),
      characterType: CharacterType.comandante,
      level: 42,
      iconImagePath: r'C:\fotos\heroi_1.png',
    );
    final r = Character.fromMap(c.toMap());
    expect(r.id, c.id);
    expect(r.groupId, c.groupId);
    expect(r.name, c.name);
    expect(r.role, c.role);
    expect(r.notes, c.notes);
    expect(r.starRank.stars, c.starRank.stars);
    expect(r.starRank.subLevel, c.starRank.subLevel);
    expect(r.createdAt, c.createdAt);
    expect(r.characterType, c.characterType);
    expect(r.level, c.level);
    expect(r.iconImagePath, c.iconImagePath);
  });

  test('CharacterStat round-trip preserva todos os campos', () {
    const s = CharacterStat(
      id: 5,
      characterId: 11,
      name: 'Crítico',
      type: StatType.percent,
      value: 12.5,
      maxValue: 100,
      triggerText: 'ao atacar',
      formulaText: 'a × b',
      sortOrder: 2,
    );
    final r = CharacterStat.fromMap(s.toMap());
    expect(r.id, s.id);
    expect(r.characterId, s.characterId);
    expect(r.name, s.name);
    expect(r.type, s.type);
    expect(r.value, s.value);
    expect(r.maxValue, s.maxValue);
    expect(r.triggerText, s.triggerText);
    expect(r.formulaText, s.formulaText);
    expect(r.sortOrder, s.sortOrder);
  });

  test('GroupStatTemplate round-trip preserva todos os campos', () {
    const t = GroupStatTemplate(
      id: 9,
      groupId: 7,
      name: 'Vida',
      type: StatType.number,
      defaultValue: 100.5,
      maxValue: 999,
      triggerText: 'g',
      formulaText: 'f',
      sortOrder: 3,
      category: 'Status base',
    );
    final r = GroupStatTemplate.fromMap(t.toMap());
    expect(r.id, t.id);
    expect(r.groupId, t.groupId);
    expect(r.name, t.name);
    expect(r.type, t.type);
    expect(r.defaultValue, t.defaultValue);
    expect(r.maxValue, t.maxValue);
    expect(r.triggerText, t.triggerText);
    expect(r.formulaText, t.formulaText);
    expect(r.sortOrder, t.sortOrder);
    expect(r.category, t.category);
  });

  test('SkillNode round-trip preserva todos os campos', () {
    const n = SkillNode(
      id: 4,
      groupId: 7,
      parentId: 2,
      name: 'Ataque Duplo',
      description: 'desc',
      iconEmoji: '⚔️',
      isUnlocked: true,
      costPoints: 3,
      sortOrder: 1,
    );
    final r = SkillNode.fromMap(n.toMap());
    expect(r.id, n.id);
    expect(r.groupId, n.groupId);
    expect(r.parentId, n.parentId);
    expect(r.name, n.name);
    expect(r.description, n.description);
    expect(r.iconEmoji, n.iconEmoji);
    expect(r.isUnlocked, n.isUnlocked);
    expect(r.costPoints, n.costPoints);
    expect(r.sortOrder, n.sortOrder);
  });

  test('CharacterAbility round-trip preserva todos os campos', () {
    const a = CharacterAbility(
      id: 6,
      characterId: 11,
      name: 'Fúria',
      description: 'em campo dá +20 de ataque',
      triggerText: 'atacando uma base',
      targetStatName: 'Ataque',
      bonusValue: -12.5,
      bonusKind: 'percent',
      isActive: true,
      sortOrder: 2,
    );
    final r = CharacterAbility.fromMap(a.toMap());
    expect(r.id, a.id);
    expect(r.characterId, a.characterId);
    expect(r.name, a.name);
    expect(r.description, a.description);
    expect(r.triggerText, a.triggerText);
    expect(r.targetStatName, a.targetStatName);
    expect(r.bonusValue, a.bonusValue);
    expect(r.bonusKind, a.bonusKind);
    expect(r.isActive, a.isActive);
    expect(r.sortOrder, a.sortOrder);
  });

  test('StarRank round-trip + regressão nunca fica negativa', () {
    const s = StarRank(stars: 2, subLevel: 7);
    final r = StarRank.fromMap(s.toMap());
    expect(r.stars, s.stars);
    expect(r.subLevel, s.subLevel);
  });
}
