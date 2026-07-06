/// Grupo de jogo — agrupa personagens/heróis de um mesmo contexto.
///
/// Suporta hierarquia via [parentId]:
/// - parentId == null → grupo raiz (aparece na HomeScreen)
/// - parentId != null → sub-grupo de outro grupo
class GameGroup {
  final int? id;
  final int? parentId; // null = raiz; não-null = sub-grupo
  final String name;
  final String? description;
  final String? iconEmoji;
  final DateTime createdAt;

  const GameGroup({
    this.id,
    this.parentId,
    required this.name,
    this.description,
    this.iconEmoji = '⚔️',
    required this.createdAt,
  });

  bool get isRoot => parentId == null;

  GameGroup copyWith({
    int? id,
    int? parentId,
    bool clearParent = false,
    String? name,
    String? description,
    String? iconEmoji,
    DateTime? createdAt,
  }) =>
      GameGroup(
        id: id ?? this.id,
        parentId: clearParent ? null : (parentId ?? this.parentId),
        name: name ?? this.name,
        description: description ?? this.description,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (parentId != null) 'parentId': parentId,
        'name': name,
        'description': description,
        'iconEmoji': iconEmoji,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GameGroup.fromMap(Map<String, dynamic> map) => GameGroup(
        id: map['id'] as int?,
        parentId: map['parentId'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        iconEmoji: map['iconEmoji'] as String? ?? '⚔️',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
