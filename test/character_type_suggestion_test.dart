// Tipo já marcado ao criar personagem (Bloco C da sprint de acessibilidade):
// o mais comum no grupo; grupo vazio segue a categoria; empate favorece a
// categoria.
import 'package:flutter_test/flutter_test.dart';

import 'package:hero_tracker/models/character_type.dart';
import 'package:hero_tracker/models/character_type_suggestion.dart';
import 'package:hero_tracker/models/content_category.dart';

void main() {
  test('grupo vazio: Heróis sugere herói; o resto sugere soldado', () {
    expect(suggestCharacterType(const [], ContentCategory.heroes),
        CharacterType.heroi);
    for (final cat in [
      ContentCategory.troops,
      ContentCategory.research,
      ContentCategory.building,
      ContentCategory.general,
    ]) {
      expect(suggestCharacterType(const [], cat), CharacterType.soldadoNormal,
          reason: cat.name);
    }
  });

  test('o tipo mais comum no grupo vence a categoria', () {
    const tipos = [
      CharacterType.comandante,
      CharacterType.comandante,
      CharacterType.heroi,
    ];
    expect(suggestCharacterType(tipos, ContentCategory.heroes),
        CharacterType.comandante);
  });

  test('empate: vale o da categoria; sem ele, a ordem do enum', () {
    const empate = [CharacterType.heroi, CharacterType.soldadoNormal];
    expect(suggestCharacterType(empate, ContentCategory.heroes),
        CharacterType.heroi);
    expect(suggestCharacterType(empate, ContentCategory.troops),
        CharacterType.soldadoNormal);
    const semCategoria = [CharacterType.comandante, CharacterType.heroi];
    expect(suggestCharacterType(semCategoria, ContentCategory.troops),
        CharacterType.heroi,
        reason: 'heroi vem antes de comandante no enum');
  });
}
