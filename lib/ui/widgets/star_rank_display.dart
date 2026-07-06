import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/star_rank.dart';
import '../../theme/app_theme.dart';

/// Exibe o rank em estrelas de um personagem.
///
/// Estrelas completas: douradas e sólidas.
/// Estrela atual (em progresso): dourada com rachaduras — quanto mais alto
/// o sub-nível, mais "cheia" ela aparece.
/// Estrelas futuras: cinza vazias.
class StarRankDisplay extends StatelessWidget {
  final StarRank rank;
  final int maxStars;
  final double starSize;
  final bool showSubLevelText;

  const StarRankDisplay({
    super.key,
    required this.rank,
    this.maxStars = 10,
    this.starSize = 24,
    this.showSubLevelText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 2,
          children: List.generate(maxStars, (i) {
            if (i < rank.stars) {
              // Estrela completa
              return Icon(Icons.star, size: starSize, color: AppTheme.gold);
            } else if (i == rank.stars) {
              // Estrela atual — com fragmentos
              return _PartialStar(
                size: starSize,
                fill: rank.subLevel / StarRank.subLevelsPerStar,
              );
            } else {
              // Estrela vazia
              return Icon(Icons.star_border,
                  size: starSize, color: Colors.grey.shade700);
            }
          }),
        ),
        if (showSubLevelText && rank.subLevel > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+${rank.subLevel}/${StarRank.subLevelsPerStar} sub-níveis',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.goldLight.withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }
}

/// Estrela parcialmente preenchida (com "rachaduras") para o sub-nível atual.
class _PartialStar extends StatelessWidget {
  final double size;
  final double fill; // 0.0 a 1.0

  const _PartialStar({required this.size, required this.fill});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(fill: fill),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double fill;
  const _StarPainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 * 0.95;
    final innerR = outerR * 0.4;

    final path = _starPath(cx, cy, outerR, innerR);

    // Fundo cinza
    canvas.drawPath(
        path, Paint()..color = Colors.grey.shade700);

    // Preenchimento dourado com clip horizontal
    if (fill > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * fill, size.height));
      canvas.drawPath(path, Paint()..color = AppTheme.gold);
      canvas.restore();
    }

    // Borda dourada (sempre visível)
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Rachaduras — linhas diagonais sobre a parte preenchida
    if (fill > 0 && fill < 1) {
      final crackPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = 0.8;
      final segments = StarRank.subLevelsPerStar;
      final filled = (fill * segments).round();
      for (int i = 1; i < filled; i++) {
        final angle = -math.pi / 2 + (i / segments) * 2 * math.pi;
        final x2 = cx + outerR * math.cos(angle);
        final y2 = cy + outerR * math.sin(angle);
        canvas.drawLine(Offset(cx, cy), Offset(x2, y2), crackPaint);
      }
    }
  }

  Path _starPath(double cx, double cy, double outerR, double innerR) {
    const points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + (i * math.pi / points);
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill;
}
