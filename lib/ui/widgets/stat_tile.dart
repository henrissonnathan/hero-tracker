import 'package:flutter/material.dart';
import '../../models/character_stat.dart';
import '../../models/stat_type.dart';
import '../../theme/app_theme.dart';

/// Card de exibição de um [CharacterStat].
class StatTile extends StatelessWidget {
  final CharacterStat stat;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIncrement; // para StatType.count
  final VoidCallback? onDecrement; // para StatType.count

  const StatTile({
    super.key,
    required this.stat,
    this.onEdit,
    this.onDelete,
    this.onIncrement,
    this.onDecrement,
  });

  Color get _typeColor {
    switch (stat.type) {
      case StatType.count:
        return AppTheme.countColor;
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                Text(
                  stat.type.label,
                  style: TextStyle(
                      fontSize: 11,
                      color: _typeColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
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
                    color: Colors.white.withOpacity(0.85),
                    fontStyle: FontStyle.italic),
              )
            else if (stat.type == StatType.formula)
              _FormulaDisplay(stat: stat, color: _typeColor)
            else if (stat.type == StatType.count && stat.maxValue != null)
              _CountBar(stat: stat, color: _typeColor)
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
          ],
        ),
      ),
    );
  }
}

class _CountBar extends StatelessWidget {
  final CharacterStat stat;
  final Color color;
  const _CountBar({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = stat.maxValue != null && stat.maxValue! > 0
        ? (stat.value / stat.maxValue!).clamp(0.0, 1.0)
        : 0.0;
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.functions, size: 14, color: color),
          const SizedBox(width: 6),
          Ex