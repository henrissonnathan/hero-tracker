import 'character_type.dart';

/// Nome e emoji que ESTE jogo dá a um tipo de unidade (v11).
///
/// O app continua com os 3 tipos de sempre por dentro ([CharacterType]) — o
/// que muda é só como eles APARECEM. Assim o dono renomeia "Herói" para
/// "Comandante" (RoK), "Governante", "Oficial"… sem tocar em código e sem
/// migrar personagem nenhum.
///
/// Sem registro para um tipo = usa o nome/emoji padrão do [CharacterType].
class UnitTypeLabel {
  final int? id;
  final int groupId;

  /// Chave do tipo: o `dbValue` do [CharacterType] (soldadoNormal/heroi/
  /// comandante). Só estes três são aceitos — no import, chave estranha é
  /// descartada.
  final String typeKey;
  final String label;
  final String? emoji;

  const UnitTypeLabel({
    this.id,
    required this.groupId,
    required this.typeKey,
    required this.label,
    this.emoji,
  });

  CharacterType get type => CharacterTypeX.fromString(typeKey);

  UnitTypeLabel copyWith({
    int? id,
    int? groupId,
    String? typeKey,
    String? label,
    String? emoji,
  }) =>
      UnitTypeLabel(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        typeKey: typeKey ?? this.typeKey,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'groupId': groupId,
        'typeKey': typeKey,
        'label': label,
        'emoji': emoji,
      };

  factory UnitTypeLabel.fromMap(Map<String, dynamic> map) => UnitTypeLabel(
        id: map['id'] as int?,
        groupId: map['groupId'] as int,
        typeKey: map['typeKey'] as String,
        label: map['label'] as String,
        emoji: map['emoji'] as String?,
      );
}

/// Os nomes em vigor para um grupo — sempre responde algo, mesmo sem nenhum
/// registro salvo (cai no padrão do enum). É o que a UI usa.
class UnitTypeNames {
  final Map<String, UnitTypeLabel> _byKey;
  const UnitTypeNames(this._byKey);

  /// Nenhuma personalização: tudo no padrão do app.
  static const UnitTypeNames padrao = UnitTypeNames({});

  factory UnitTypeNames.fromList(Iterable<UnitTypeLabel> labels) =>
      UnitTypeNames({for (final l in labels) l.typeKey: l});

  String labelOf(CharacterType type) {
    final custom = _byKey[type.dbValue]?.label;
    return (custom == null || custom.trim().isEmpty) ? type.label : custom;
  }

  String emojiOf(CharacterType type) {
    final custom = _byKey[type.dbValue]?.emoji;
    return (custom == null || custom.trim().isEmpty) ? type.emoji : custom;
  }

  /// true se este tipo foi renomeado neste jogo (para a tela mostrar
  /// "Restaurar padrão" só quando faz sentido).
  bool isCustom(CharacterType type) => _byKey.containsKey(type.dbValue);
}
