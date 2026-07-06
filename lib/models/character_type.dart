/// Tipo de unidade dentro de um grupo de jogo.
enum CharacterType {
  soldadoNormal,
  heroi,
  comandante,
}

extension CharacterTypeX on CharacterType {
  String get label {
    switch (this) {
      case CharacterType.soldadoNormal:
        return 'Soldado';
      case CharacterType.heroi:
        return 'Herói';
      case CharacterType.comandante:
        return 'Comandante';
    }
  }

  String get emoji {
    switch (this) {
      case CharacterType.soldadoNormal:
        return '🛡️';
      case CharacterType.heroi:
        return '⚔️';
      case CharacterType.comandante:
        return '👑';
    }
  }

  /// Comandantes não entram diretamente em batalha.
  bool get entersBattle => this != CharacterType.comandante;

  String get dbValue {
    switch (this) {
      case CharacterType.soldadoNormal:
        return 'soldadoNormal';
      case CharacterType.heroi:
        return 'heroi';
      case CharacterType.comandante:
        return 'comandante';
    }
  }

  static CharacterType fromString(String? s) {
    switch (s) {
      case 'heroi':
        return CharacterType.heroi;
      case 'comandante':
        return CharacterType.comandante;
      default:
        return CharacterType.soldadoNormal;
    }
  }
}
