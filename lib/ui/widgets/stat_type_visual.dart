import 'package:flutter/material.dart';

import '../../models/stat_type.dart';
import '../../theme/app_theme.dart';

/// Ícone e cor de cada tipo de status — FONTE ÚNICA para toda tela que mostra
/// o tipo (formulário, tela de estatísticas, card do status). O tipo nunca
/// aparece só como texto: ícone + cor + nome juntos (acessibilidade: não
/// depende de ler a palavra nem de enxergar a cor).
extension StatTypeVisual on StatType {
  IconData get icon {
    switch (this) {
      case StatType.number:
        return Icons.tag;
      case StatType.percent:
        return Icons.percent;
      case StatType.trigger:
        return Icons.bolt;
      case StatType.formula:
        return Icons.calculate_outlined;
    }
  }

  Color get color {
    switch (this) {
      case StatType.number:
        return AppTheme.numberColor;
      case StatType.percent:
        return AppTheme.percentColor;
      case StatType.trigger:
        return AppTheme.triggerColor;
      case StatType.formula:
        return AppTheme.formulaColor;
    }
  }
}

/// Selo redondo com o ícone do tipo (usado nas listas).
class StatTypeBadge extends StatelessWidget {
  final StatType type;
  final double size;
  const StatTypeBadge(this.type, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Tipo ${type.label}',
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(type.icon, size: size * 0.6, color: type.color),
        ),
      );
}
