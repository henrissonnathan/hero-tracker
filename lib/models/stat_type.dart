/// Tipos de status de um personagem.
enum StatType {
  /// Valor inteiro (ex.: HP, ATK)
  count,

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
      case StatType.count:
        return 'Contagem';
      case StatType.percent:
        return 'Porcentagem';
      case StatType.number:
        return 'Nú