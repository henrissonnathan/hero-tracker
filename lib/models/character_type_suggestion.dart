import 'character_type.dart';
import 'content_category.dart';

/// Tipo que o dialog de criação já traz marcado — para o dono quase nunca
/// precisar tocar no tipo.
///
/// Regra: o tipo MAIS COMUM entre os personagens que o grupo já tem (quem
/// mapeia 6 comandantes cria o 7º comandante). Grupo vazio: pela categoria
/// do grupo — Heróis → herói; o resto (tropas, pesquisa, construção, geral)
/// → soldado, que é como o mapa de exemplo guarda tropas, pesquisas e
/// prédios. Empate: o da categoria, se estiver entre os empatados; senão a
/// ordem do enum.
CharacterType suggestCharacterType(
  Iterable<CharacterType> existing,
  ContentCategory category,
) {
  final padrao = category == ContentCategory.heroes
      ? CharacterType.heroi
      : CharacterType.soldadoNormal;
  final contagem = <CharacterType, int>{};
  for (final t in existing) {
    contagem[t] = (contagem[t] ?? 0) + 1;
  }
  if (contagem.isEmpty) return padrao;
  final maior = contagem.values.reduce((a, b) => a > b ? a : b);
  final empatados =
      CharacterType.values.where((t) => contagem[t] == maior).toList();
  return empatados.contains(padrao) ? padrao : empatados.first;
}
