import 'star_rank.dart';
import 'character_type.dart';

/// Personagem/herói/tropa dentro de um [GameGroup].
class Character {
  final int? id;
  final int groupId;
  final String name;
  final String? role; // ex.: "Tank", "DPS", "Support"
  final String? notes;
  final StarRank starRank;
  final DateTime createdAt;

  /// Tipo da unidade: soldadoNormal, heroi ou comandante.
  final CharacterType characterType;

  const Character({
    this.id,
    required this.groupId,
    required this.name,
    this.role,
    this.notes,
    StarRank? starRank,
    required this.createdAt,
    this.characterType = CharacterType.soldadoNormal,
  }) : starRank = starRank ?? const StarRank();

  Character copyWith({
    int? id,
    int? groupId,
    String? name,
    String? role,
    bool clearRole = false,
    String? notes,
    StarRank? starRank,
    DateTime? createdAt,
    CharacterType? characterType,
  }) =>
      Character(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        role: clearRole ? null : (role ?? this.role),
        notes: notes ?? this.notes,
        starRank: starRank ?? this.starRank,
        createdAt: createdAt ?? this.createdAt,
        characterType: characterType ?? this.characterType,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'groupId': groupId,
        'name': name,
        if (role != null) 'role': role,
        if (notes != null) 'notes': notes,
        'starStars': starRank.stars,
        'starSubLevel': starRank.subLevel,
        'createdAt': createdAt.toIso8601String(),
        'characterType': characterType.dbValue,
      };

  factory Character.fromMap(Map<String, dynamic> map) => Character(
        id: map['id'] as int?,
        groupId: map['groupId'] as int,
        name: map['name'] as String,
        role: map['role'] as String?,
        notes: map['notes'] as String?,
        starRank: StarRank(
          stars: map['starStars'] as int? ?? 0,
          subLevel: map['starSubLevel'] as int? ?? 0,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        characterType:
            CharacterTypeX.fromString(map['characterType'] as String?),
        battleUses: map['battleUses'] as int?,
      );
}
