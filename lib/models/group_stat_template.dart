import 'character_stat.dart';
import 'stat_type.dart';

/// Template de status definido no nível do [GameGroup] — a "base" que todo
/// personagem novo do grupo herda ao ser criado.
///
/// É uma cópia unidirecional: [toCharacterStat] gera um [CharacterStat]
/// independente no momento da criação do personagem. Editar ou apagar o
/// template depois não afeta personagens já criados.
class GroupStatTemplate {
  final int? id;
  final int groupId;
  final String name;
  final StatType type;
  final double defaultValue;
  final double? maxValue; // opcional — barras de progresso
  final String? triggerText; // StatType.trigger
  final String? formulaText; // StatType.formula (só texto nesta sprint)
  final int sortOrder;

  /// Categoria/sub-grupo opcional para classificar o status (ex.: "Recursos",
  /// "Status base"). null = "Sem categoria". Só organiza — não afeta a cópia
  /// para o personagem.
  final String? category;

  const GroupStatTemplate({
    this.id,
    required this.groupId,
    required this.name,
    required this.type,
    this.defaultValue = 0,
    this.maxValue,
    this.triggerText,
    this.formulaText,
    this.sortOrder = 0,
    this.category,
  });

  GroupStatTemplate copyWith({
    int? id,
    int? groupId,
    String? name,
    StatType? type,
    double? defaultValue,
    double? maxValue,
    String? triggerText,
    String? formulaText,
    int? sortOrder,
    String? category,
  }) =>
      GroupStatTemplate(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        type: type ?? this.type,
        defaultValue: defaultValue ?? this.defaultValue,
        maxValue: maxValue ?? this.maxValue,
        triggerText: triggerText ?? this.triggerText,
        formulaText: formulaText ?? this.formulaText,
        sortOrder: sortOrder ?? this.sortOrder,
        category: category ?? this.category,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'groupId': groupId,
        'name': name,
        'type': type.name,
        'defaultValue': defaultValue,
        if (maxValue != null) 'maxValue': maxValue,
        if (triggerText != null) 'triggerText': triggerText,
        if (formulaText != null) 'formulaText': formulaText,
        'sortOrder': sortOrder,
        // incondicional: permite LIMPAR a categoria num update (voltar p/ null)
        'category': category,
      };

  factory GroupStatTemplate.fromMap(Map<String, dynamic> map) =>
      GroupStatTemplate(
        id: map['id'] as int?,
        groupId: map['groupId'] as int,
        name: map['name'] as String,
        type: StatType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => StatType.number,
        ),
        defaultValue: (map['defaultValue'] as num?)?.toDouble() ?? 0,
        maxValue: (map['maxValue'] as num?)?.toDouble(),
        triggerText: map['triggerText'] as String?,
        formulaText: map['formulaText'] as String?,
        sortOrder: map['sortOrder'] as int? ?? 0,
        category: map['category'] as String?,
      );

  /// Gera um [CharacterStat] independente para [characterId] — cópia de
  /// valores, não referência ao template.
  CharacterStat toCharacterStat(int characterId) => CharacterStat(
        characterId: characterId,
        name: name,
        type: type,
        value: defaultValue,
        maxValue: maxValue,
        triggerText: triggerText,
        formulaText: formulaText,
        sortOrder: sortOrder,
      );
}
