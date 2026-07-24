/// Categoria de conteúdo de um [GameGroup].
///
/// Usada para filtrar/organizar grupos por tipo de progressão no jogo:
/// heróis, tropas, pesquisa, construção ou geral.
enum ContentCategory {
  heroes,
  troops,
  research,
  building,
  general;

  String get dbValue => name;

  String get label => const {
        ContentCategory.heroes: 'Heróis',
        ContentCategory.troops: 'Tropas',
        ContentCategory.research: 'Pesquisa',
        ContentCategory.building: 'Construção',
        ContentCategory.general: 'Geral',
      }[this]!;

  /// Ícone padrão para cada categoria.
  String get emoji => const {
        ContentCategory.heroes: '⚔️',
        ContentCategory.troops: '🪖',
        ContentCategory.research: '🔬',
        ContentCategory.building: '🏗️',
        ContentCategory.general: '📋',
      }[this]!;

  static ContentCategory fromString(String? value) => ContentCategory.values
      .firstWhere((e) => e.name == value, orElse: () => ContentCategory.general);
}
