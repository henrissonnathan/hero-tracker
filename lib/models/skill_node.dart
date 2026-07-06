/// Nó de uma árvore de habilidades.
///
/// Cada grupo pode ter uma árvore com estrutura hierárquica:
/// - parentId == null → habilidade raiz (sem pré-requisito)
/// - parentId != null → requer o nó pai desbloqueado primeiro
///
/// Exemplo:
///   [Ataque Básico] → [Ataque Duplo] → [Ataque Triplo]
///                  ↘ [Crítico +10%]
class SkillNode {
  final int? id;
  final int groupId;
  final int? parentId;
  final String name;
  final String? description;
  final String iconEmoji;
  final bool isUnlocked;
  final int costPoints; // pontos necessários para desbloquear
  final int sortOrder;

  const SkillNode({
    this.id,
    required this.groupId,
    this.parentId,
    required this.name,
    this.description,
    this.iconEmoji = '🔷',
    this.isUnlocked = false,
    this.costPoints = 1,
    this.sortOrder = 0,
  });

  bool get isRoot => parentId == null;

  SkillNode copyWith({
    int? id,
    int? groupId,
    int? parentId,
    bool clearParent = false,
    String? name,
    String? description,
    String? iconEmoji,
    bool? isUnlocked,
    int? costPoints,
    int? sortOrder,
  }) =>
      SkillNode(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        parentId: clearParent ? null : (parentId ?? this.parentId),
        name: name ?? this.name,
        description: description ?? this.description,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        costPoints: costPoints ?? this.costPoints,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'groupId': groupId,
        if (parentId != null) 'parentId': parentId,
        'name': name,
        if (description != null) 'description': description,
        'iconEmoji': iconEmoji,
        'isUnlocked': isUnlocked ? 1 : 0,
        'costPoints': costPoints,
        'sortOrder': sortOrder,
      };

  factory SkillNode.fromMap(Map<String, dynamic> map) => SkillNode(
        id: map['id'] as int?,
        groupId: map['groupId'] as int,
        parentId: map['parentId'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        iconEmoji: map['iconEmoji'] as String? ?? '🔷',
        isUnlocked: (map['isUnlocked'] as int? ?? 0) == 1,
        costPoints: map['costPoints'] as int? ?? 1,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );
}
