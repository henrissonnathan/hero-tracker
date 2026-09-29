/// Habilidade de herói — duas partes:
/// 1. A **descrição** livre ("quando em campo ele dá mais 20 de ataque").
/// 2. A **configuração** que realmente faz: gatilho ([triggerText], ex.:
///    "atacando uma base") + efeito ([targetStatName] recebe [bonusValue],
///    fixo ou percentual).
///
/// [isActive] é a simulação visual: com a habilidade ativa, o stat alvo é
/// EXIBIDO com o bônus somado — o valor salvo do stat nunca muda.
class CharacterAbility {
  final int? id;
  final int characterId;
  final String name;
  final String? description;
  final String? triggerText;

  /// Nome do stat alvo (stats são dinâmicos — referência por nome).
  /// null = habilidade só descritiva, sem efeito configurado.
  final String? targetStatName;
  final double bonusValue;

  /// 'flat' (+20) ou 'percent' (+20%).
  final String bonusKind;
  final bool isActive;
  final int sortOrder;

  const CharacterAbility({
    this.id,
    required this.characterId,
    required this.name,
    this.description,
    this.triggerText,
    this.targetStatName,
    this.bonusValue = 0,
    this.bonusKind = 'flat',
    this.isActive = false,
    this.sortOrder = 0,
  });

  /// true quando há efeito configurado (stat alvo definido).
  bool get hasEffect =>
      targetStatName != null && targetStatName!.trim().isNotEmpty;

  CharacterAbility copyWith({
    int? id,
    int? characterId,
    String? name,
    String? description,
    String? triggerText,
    String? targetStatName,
    double? bonusValue,
    String? bonusKind,
    bool? isActive,
    int? sortOrder,
  }) =>
      CharacterAbility(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        name: name ?? this.name,
        description: description ?? this.description,
        triggerText: triggerText ?? this.triggerText,
        targetStatName: targetStatName ?? this.targetStatName,
        bonusValue: bonusValue ?? this.bonusValue,
        bonusKind: bonusKind ?? this.bonusKind,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'characterId': characterId,
        'name': name,
        'description': description,
        'triggerText': triggerText,
        'targetStatName': targetStatName,
        'bonusValue': bonusValue,
        'bonusKind': bonusKind,
        'isActive': isActive ? 1 : 0,
        'sortOrder': sortOrder,
      };

  factory CharacterAbility.fromMap(Map<String, dynamic> map) =>
      CharacterAbility(
        id: map['id'] as int?,
        characterId: map['characterId'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
        triggerText: map['triggerText'] as String?,
        targetStatName: map['targetStatName'] as String?,
        bonusValue: (map['bonusValue'] as num?)?.toDouble() ?? 0,
        bonusKind: map['bonusKind'] as String? ?? 'flat',
        isActive: (map['isActive'] as int? ?? 0) == 1,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  /// Rótulo do bônus: "+20", "-5" ou "+10%".
  String get bonusLabel {
    final v = bonusValue % 1 == 0
        ? bonusValue.toStringAsFixed(0)
        : bonusValue.toString();
    final sign = bonusValue >= 0 ? '+' : '';
    return bonusKind == 'percent' ? '$sign$v%' : '$sign$v';
  }
}
