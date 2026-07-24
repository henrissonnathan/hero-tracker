import 'stat_type.dart';

/// Status de um personagem.
///
/// - [StatType.trigger]: texto em [triggerText]
/// - [StatType.formula]: fórmula em [formulaText]
///   ex.: "vitalidade × constituição"
/// - Demais tipos: valor numérico em [value]
class CharacterStat {
  final int? id;
  final int characterId;
  final String name;
  final StatType type;
  final double value;
  final double? maxValue; // opcional — barras de progresso
  final String? triggerText; // StatType.trigger
  final String? formulaText; // StatType.formula
  final int sortOrder;

  const CharacterStat({
    this.id,
    required this.characterId,
    required this.name,
    required this.type,
    this.value = 0,
    this.maxValue,
    this.triggerText,
    this.formulaText,
    this.sortOrder = 0,
  });

  CharacterStat copyWith({
    int? id,
    int? characterId,
    String? name,
    StatType? type,
    double? value,
    double? maxValue,
    String? triggerText,
    String? formulaText,
    int? sortOrder,
  }) =>
      CharacterStat(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        name: name ?? this.name,
        type: type ?? this.type,
        value: value ?? this.value,
        maxValue: maxValue ?? this.maxValue,
        triggerText: triggerText ?? this.triggerText,
        formulaText: formulaText ?? this.formulaText,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'characterId': characterId,
        'name': name,
        'type': type.name,
        'value': value,
        if (maxValue != null) 'maxValue': maxValue,
        if (triggerText != null) 'triggerText': triggerText,
        if (formulaText != null) 'formulaText': formulaText,
        'sortOrder': sortOrder,
      };

  factory CharacterStat.fromMap(Map<String, dynamic> map) => CharacterStat(
        id: map['id'] as int?,
        characterId: map['characterId'] as int,
        name: map['name'] as String,
        type: StatType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => StatType.number,
        ),
        value: (map['value'] as num?)?.toDouble() ?? 0,
        maxValue: (map['maxValue'] as num?)?.toDouble(),
        triggerText: map['triggerText'] as String?,
        formulaText: map['formulaText'] as String?,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  /// Texto de exibição do valor atual.
  String get displayValue {
    switch (type) {
      case StatType.trigger:
        return triggerText ?? '';
      case StatType.formula:
        return formulaText ?? '';
      case StatType.percent:
        return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
      case StatType.number:
        return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
  }
}
