import 'package:flutter/material.dart';
import '../../models/character_stat.dart';
import '../../models/stat_type.dart';
import '../../theme/app_theme.dart';
import 'stat_type_visual.dart';

/// Card de exibição de um [CharacterStat].
class StatTile extends StatelessWidget {
  final CharacterStat stat;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIncrement; // +/- opcional para stats numéricos
  final VoidCallback? onDecrement; // +/- opcional para stats numéricos

  /// Valor com bônus de habilidades ativas (simulação visual).
  /// null = sem bônus, exibição normal.
  final double? boostedValue;

  /// Margem do card. null = a de sempre (1 status por linha). Em 2+ colunas a
  /// tela passa uma margem menor, senão o vão do meio fica com 24px.
  final EdgeInsetsGeometry? margin;

  const StatTile({
    super.key,
    required this.stat,
    this.onEdit,
    this.onDelete,
    this.onIncrement,
    this.onDecrement,
    this.boostedValue,
    this.margin,
  });

  Color get _typeColor {
    switch (stat.type) {
      case StatType.percent:
        return AppTheme.percentColor;
      case StatType.number:
        return AppTheme.numberColor;
      case StatType.trigger:
        return AppTheme.triggerColor;
      case StatType.formula:
        return AppTheme.formulaColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Icon(stat.type.icon, size: 14, color: _typeColor),
                const SizedBox(width: 3),
                Text(
                  stat.type.label,
                  style: TextStyle(
                      fontSize: 11,
                      color: _typeColor,
                      fontWeight: FontWeight.w600),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'Editar "${stat.name}"',
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Apagar "${stat.name}"',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (stat.type == StatType.trigger)
              Text(
                stat.triggerText ?? '',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha:0.85),
                    fontStyle: FontStyle.italic),
              )
            else if (stat.type == StatType.formula)
              _FormulaDisplay(stat: stat, color: _typeColor)
            else if (stat.type == StatType.percent)
              _PercentBar(stat: stat, color: _typeColor)
            else
              Row(
                children: [
                  if (onDecrement != null)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: onDecrement,
                      color: _typeColor,
                      visualDensity: VisualDensity.compact,
                    ),
                  Text(
                    stat.displayValue,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _typeColor),
                  ),
                  if (onIncrement != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onIncrement,
                      color: _typeColor,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            if (boostedValue != null) ...[
              const SizedBox(height: 4),
              Text(
                '⚡ com habilidades: ${_fmtBoosted(boostedValue!)}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtBoosted(double v) {
    // Mesma precisão do displayValue: number 2 casas, percent 1, inteiro 0.
    final s = v.toStringAsFixed(
        v % 1 == 0 ? 0 : (stat.type == StatType.number ? 2 : 1));
    return stat.type == StatType.percent ? '$s%' : s;
  }
}

/// Exibe a fórmula de um stat derivado.
class _FormulaDisplay extends StatelessWidget {
  final CharacterStat stat;
  final Color color;
  const _FormulaDisplay({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.functions, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stat.formulaText ?? '',
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  final CharacterStat stat;
  final Color color;
  const _PercentBar({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = (stat.value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(stat.displayValue,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
