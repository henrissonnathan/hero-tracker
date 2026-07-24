/// Tipos de status de um personagem.
enum StatType {
  /// Porcentagem 0–100 (ex.: Chance de crítico)
  percent,

  /// Número decimal livre (ex.: Multiplicador de dano)
  number,

  /// Texto condicional — gatilho/habilidade passiva
  /// (ex.: "Ao atacar: +10% de dano")
  trigger,

  /// Stat derivado — valor calculado por fórmula que referencia outros stats.
  /// O texto da fórmula fica em [CharacterStat.formulaText].
  /// (ex.: "vida = vitalidade × constituição")
  formula,
}

extension StatTypeLabel on StatType {
  String get label {
    switch (this) {
      case StatType.percent:
        return 'Porcentagem';
      case StatType.number:
        return 'Número';
      case StatType.trigger:
        return 'Gatilho';
      case StatType.formula:
        return 'Fórmula';
    }
  }

  String get unit {
    switch (this) {
      case StatType.percent:
        return '%';
      default:
        return '';
    }
  }

  bool get isTextBased =>
      this == StatType.trigger || this == StatType.formula;
}
