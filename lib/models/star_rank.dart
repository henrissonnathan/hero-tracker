/// Representa o rank em estrelas de um personagem.
///
/// Sistema: cada estrela tem [subLevelsPerStar] sub-níveis.
/// Quando os sub-níveis completam [subLevelsPerStar], sobe 1 estrela.
///
/// Visualização:
/// - Estrelas cheias: ⭐ sólidas
/// - Estrela atual: mostra rachaduras/fragmentos baseado nos sub-níveis
/// - Estrelas futuras: vazias
class StarRank {
  /// Número de sub-níveis para avançar 1 estrela (padrão: 8)
  static const int subLevelsPerStar = 8;

  final int stars; // estrelas completas (0..N)
  final int subLevel; // sub-nível da estrela atual (0..subLevelsPerStar-1)

  const StarRank({this.stars = 0, this.subLevel = 0});

  StarRank copyWith({int? stars, int? subLevel}) =>
      StarRank(stars: stars ?? this.stars, subLevel: subLevel ?? this.subLevel);

  /// Avança 1 sub-nível. Ao completar [subLevelsPerStar], sobe 1 estrela.
  StarRank advanceSubLevel() {
    final nextSub = subLevel + 1;
    if (nextSub >= subLevelsPerStar) {
      return StarRank(stars: stars + 1, subLevel: 0);
    }
    return StarRank(stars: stars, subLevel: nextSub);
  }

  /// Sobe diretamente N sub-níveis (pode cruzar várias estrelas).
  StarRank advanceBy(int levels) {
    int totalSub = stars * subLevelsPerStar + subLevel + levels;
    return StarRank(
      stars: totalSub ~/ subLevelsPerStar,
      subLevel: totalSub % subLevelsPerStar,
    );
  }

  /// Sobe exatamente 1 estrela inteira (ignora sub-níveis atuais).
  StarRank advanceStar() => StarRank(stars: stars + 1, subLevel: subLevel);

  Map<String, dynamic> toMap() => {'stars': stars, 'subLevel': subLevel};

  factory StarRank.fromMap(Map<String, dynamic> map) => StarRank(
        stars: map['stars'] as int? ?? 0,
        subLevel: map['subLevel'] as int? ?? 0,
      );

  @override
  String toString() => '⭐$stars (sub: $subLevel/$subLevelsPerStar)';
}
