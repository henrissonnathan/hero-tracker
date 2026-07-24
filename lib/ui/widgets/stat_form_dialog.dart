import 'package:flutter/material.dart';
import '../../models/stat_type.dart';

/// Formata um valor numérico sem casas decimais desnecessárias, mas sem
/// arredondar/truncar valores fracionários (ex.: 12.5 permanece "12.5").
String _formatNum(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

/// Dados de formulário de um status/template — mesma forma para
/// [CharacterStat] (personagem) e `GroupStatTemplate` (grupo); cada
/// chamador converte para o modelo que precisa.
class StatFormResult {
  final String name;
  final StatType type;
  final double value;
  final double? maxValue;
  final String? triggerText;
  final String? formulaText;
  final String? category;

  const StatFormResult({
    required this.name,
    required this.type,
    required this.value,
    this.maxValue,
    this.triggerText,
    this.formulaText,
    this.category,
  });
}

/// Dialog compartilhado de criar/editar status — usado tanto pelo status de
/// personagem (character_screen) quanto pelo template de status do grupo
/// (game_screen). Extraído para cá para não duplicar a UI (L1).
class StatFormDialog extends StatefulWidget {
  final String title;
  final String valueLabel;
  final StatFormResult? initial;

  /// Retorna mensagem de erro se o nome não for válido (ex.: duplicado), ou
  /// null se estiver ok.
  final String? Function(String name)? validateName;

  /// Quando true, mostra o campo de categoria/sub-grupo (usado pelos templates
  /// do grupo; o status de personagem não usa categoria).
  final bool showCategory;

  /// Categorias já existentes, oferecidas como atalho (chips).
  final List<String> categories;

  /// Categoria pré-preenchida ao criar um status novo dentro de uma categoria.
  final String? initialCategory;

  const StatFormDialog({
    super.key,
    required this.title,
    this.valueLabel = 'Valor',
    this.initial,
    this.validateName,
    this.showCategory = false,
    this.categories = const [],
    this.initialCategory,
  });

  @override
  State<StatFormDialog> createState() => _StatFormDialogState();
}

class _StatFormDialogState extends State<StatFormDialog> {
  late TextEditingController _name;
  late TextEditingController _value;
  late TextEditingController _trigger;
  late TextEditingController _formula;
  late TextEditingController _category;
  StatType _type = StatType.number;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _value = TextEditingController(text: s != null ? _formatNum(s.value) : '');
    _trigger = TextEditingController(text: s?.triggerText ?? '');
    _formula = TextEditingController(text: s?.formulaText ?? '');
    _category =
        TextEditingController(text: s?.category ?? widget.initialCategory ?? '');
    _type = s?.type ?? StatType.number;
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _trigger.dispose();
    _formula.dispose();
    _category.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final error = widget.validateName?.call(name);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    final v = double.tryParse(_value.text) ?? 0;
    Navigator.pop(
      context,
      StatFormResult(
        name: name,
        type: _type,
        value: v,
        maxValue: null,
        triggerText: _type == StatType.trigger ? _trigger.text.trim() : null,
        formulaText: _type == StatType.formula ? _formula.text.trim() : null,
        category: widget.showCategory && _category.text.trim().isNotEmpty
            ? _category.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nome do status',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              autofocus: true,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            // Tipo
            SegmentedButton<StatType>(
              segments: StatType.values
                  .map((t) => ButtonSegment(
                        value: t,
                        label: Text(t.label,
                            style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            if (_type == StatType.trigger)
              TextField(
                controller: _trigger,
                decoration: const InputDecoration(
                    labelText: 'Texto do gatilho',
                    hintText: 'ex.: Ao atacar: +10% de dano',
                    border: OutlineInputBorder()),
                maxLines: 3,
              )
            else if (_type == StatType.formula)
              TextField(
                controller: _formula,
                decoration: const InputDecoration(
                    labelText: 'Fórmula',
                    hintText: 'ex.: vitalidade × constituição',
                    border: OutlineInputBorder()),
                maxLines: 2,
              )
            else ...[
              TextField(
                controller: _value,
                decoration: InputDecoration(
                  labelText: _type == StatType.percent
                      ? '${widget.valueLabel} (%)'
                      : widget.valueLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            if (widget.showCategory) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoria / sub-grupo (opcional)',
                  hintText: 'ex.: Recursos, Status base, Bônus...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.categories
                        .map((c) => ActionChip(
                              label: Text(c,
                                  style: const TextStyle(fontSize: 11)),
                              onPressed: () => _category.text = c,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
