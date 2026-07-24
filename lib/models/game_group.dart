import 'content_category.dart';

/// Grupo de jogo — agrupa personagens/heróis de um mesmo contexto.
///
/// Suporta hierarquia via [parentId]:
/// - parentId == null → grupo raiz (aparece na HomeScreen)
/// - parentId != null → sub-grupo de outro grupo
///
/// Configuração de esquadrão:
/// - [maxHeroesPerSquad]: max de heróis por esquadrão. null = sem limite.
/// - [maxCommandersPerSquad]: max de comandantes por esquadrão. null = sem limite.
class GameGroup {
  final int? id;
  final int? parentId; // null = raiz; não-null = sub-grupo
  final String name;
  final String? description;
  final String? iconEmoji;

  /// Caminho da foto interna usada como ícone (null = usa [iconEmoji]).
  /// O arquivo é sempre uma cópia PNG gerada pelo app em pasta interna.
  final String? iconImagePath;
  final DateTime createdAt;

  /// Limite de heróis no esquadrão (null = sem limite).
  final int? maxHeroesPerSquad;

  /// Limite de comandantes no esquadrão (null = sem limite).
  /// Comandantes não entram em batalha diretamente.
  final int? maxCommandersPerSquad;

  /// Categoria de conteúdo do grupo (heróis, tropas, pesquisa, construção, geral).
  final ContentCategory contentCategory;

  const GameGroup({
    this.id,
    this.parentId,
    required this.name,
    this.description,
    this.iconEmoji = '⚔️',
    this.iconImagePath,
    required this.createdAt,
    this.maxHeroesPerSquad,
    this.maxCommandersPerSquad,
    this.contentCategory = ContentCategory.general,
  });

  bool get isRoot => parentId == null;

  GameGroup copyWith({
    int? id,
    int? parentId,
    bool clearParent = false,
    String? name,
    String? description,
    bool clearDescription = false,
    String? iconEmoji,
    String? iconImagePath,
    bool clearIconImage = false,
    DateTime? createdAt,
    int? maxHeroesPerSquad,
    bool clearMaxHeroes = false,
    int? maxCommandersPerSquad,
    bool clearMaxCommanders = false,
    ContentCategory? contentCategory,
  }) =>
      GameGroup(
        id: id ?? this.id,
        parentId: clearParent ? null : (parentId ?? this.parentId),
        name: name ?? this.name,
        description:
            clearDescription ? null : (description ?? this.description),
        iconEmoji: iconEmoji ?? this.iconEmoji,
        iconImagePath:
            clearIconImage ? null : (iconImagePath ?? this.iconImagePath),
        createdAt: createdAt ?? this.createdAt,
        maxHeroesPerSquad: clearMaxHeroes
            ? null
            : (maxHeroesPerSquad ?? this.maxHeroesPerSquad),
        maxCommandersPerSquad: clearMaxCommanders
            ? null
            : (maxCommandersPerSquad ?? this.maxCommandersPerSquad),
        contentCategory: contentCategory ?? this.contentCategory,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (parentId != null) 'parentId': parentId,
        'name': name,
        'description': description,
        'iconEmoji': iconEmoji,
        'iconImagePath': iconImagePath,
        'createdAt': createdAt.toIso8601String(),
        if (maxHeroesPerSquad != null) 'maxHeroesPerSquad': maxHeroesPerSquad,
        if (maxCommandersPerSquad != null)
          'maxCommandersPerSquad': maxCommandersPerSquad,
        'contentCategory': contentCategory.dbValue,
      };

  factory GameGroup.fromMap(Map<String, dynamic> map) => GameGroup(
        id: map['id'] as int?,
        parentId: map['parentId'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        iconEmoji: map['iconEmoji'] as String? ?? '⚔️',
        iconImagePath: map['iconImagePath'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        maxHeroesPerSquad: map['maxHeroesPerSquad'] as int?,
        maxCommandersPerSquad: map['maxCommandersPerSquad'] as int?,
        contentCategory:
            ContentCategory.fromString(map['contentCategory'] as String?),
      );
}
