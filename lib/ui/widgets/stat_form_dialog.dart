import 'package:flutter/material.dart';
import '../../models/stat_type.dart';
import 'stat_type_visual.dart';

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

/// Como cada tipo aparece na hora de escolher: o que ele mapeia no jogo e um
/// exemplo (explicação do dono, skill PROD). Ordem = do mais usado ao menos.
class _TipoInfo {
  final StatType type;
  final String explica;
  final String exemplo;
  const _TipoInfo(this.type, this.explica, this.exemplo);
}

const _tipos = [
  _TipoInfo(StatType.number, 'Valor do jogo: recurso, custo, tempo',
      'Comida 1.500.000'),
  _TipoInfo(StatType.percent, 'Bônus em porcentagem', '+10% de ataque'),
  _TipoInfo(StatType.trigger, 'O que precisa acontecer', 'defendendo a base'),
  _TipoInfo(StatType.formula, 'Conta com outros status', 'Ataque × 2'),
];

/// Palavras que quase sempre indicam porcentagem. Ao CRIAR, o tipo já vem
/// escolhido por elas — o dono troca com um toque se não for. Nunca mexe no
/// tipo depois que ele tocou num cartão, nem ao editar.
const _pistasDePorcentagem = [
  'bônus', 'bonus', '%', 'redução', 'reducao', 'chance', 'taxa',
];

/// Operadores que a fórmula aceita com um toque (× e ÷ não existem no
/// teclado), com o nome falado — o leitor de tela não lê "×" como "vezes".
const _operadores = {
  '+': 'mais',
  '-': 'menos',
  '×': 'vezes',
  '÷': 'dividido por',
  '(': 'abre parêntese',
  ')': 'fecha parêntese',
};

/// Atalhos de valor para porcentagem — os bônus mais comuns em jogo.
const _atalhosDePorcentagem = [5, 10, 15, 20, 25, 30];

/// Dialog compartilhado de criar/editar status — usado tanto pelo status de
/// personagem (character_screen) quanto pelo template de status do grupo
/// (stats_screen). Extraído para cá para não duplicar a UI (L1).
///
/// Pensado para digitar o MÍNIMO (o dono tem dificuldade para digitar): o tipo
/// é escolhido num cartão que explica o que ele é, a fórmula se monta tocando
/// nos nomes dos status e nos operadores, e gatilho já usado entra com um toque.
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

  /// Nomes dos outros status — viram botões para montar a fórmula tocando.
  final List<String> availableStatNames;

  /// Gatilhos já usados neste jogo — reusar é um toque (o gatilho é da lista
  /// do jogo, não de um status só).
  final List<String> knownTriggers;

  const StatFormDialog({
    super.key,
    required this.title,
    this.valueLabel = 'Valor',
    this.initial,
    this.validateName,
    this.showCategory = false,
    this.categories = const [],
    this.initialCategory,
    this.availableStatNames = const [],
    this.knownTriggers = const [],
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

  /// true quando o dono escolheu o tipo (ou está editando): a sugestão pelo
  /// nome não mexe mais.
  late bool _tipoEscolhido;

  /// true quando o tipo atual veio da sugestão pelo nome (mostra o aviso).
  bool _tipoSugerido = false;

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
    _tipoEscolhido = s != null;
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

  void _onNameChanged(String nome) {
    if (_nameError != null) setState(() => _nameError = null);
    if (_tipoEscolhido) return;
    final n = nome.toLowerCase();
    final pareceBonus = _pistasDePorcentagem.any(n.contains);
    if (pareceBonus && _type != StatType.percent) {
      setState(() {
        _type = StatType.percent;
        _tipoSugerido = true;
      });
    } else if (!pareceBonus && _tipoSugerido) {
      // Apagou a palavra-pista: volta ao padrão em vez de ficar "preso".
      setState(() {
        _type = StatType.number;
        _tipoSugerido = false;
      });
    }
  }

  void _escolherTipo(StatType t) => setState(() {
        _type = t;
        _tipoEscolhido = true;
        _tipoSugerido = false;
      });

  /// Insere [pedaco] na fórmula onde está o cursor (ou no fim), separando com
  /// espaço — o resultado lê como conta: "Ataque + Defesa × 2".
  void _inserirNaFormula(String pedaco) {
    final texto = _formula.text;
    final sel = _formula.selection;
    final inicio = sel.isValid ? sel.start : texto.length;
    final fim = sel.isValid ? sel.end : texto.length;
    final antes = texto.substring(0, inicio);
    final depois = texto.substring(fim);
    final espacoAntes = antes.isEmpty || antes.endsWith(' ') ? '' : ' ';
    final espacoDepois = depois.isEmpty || depois.startsWith(' ') ? '' : ' ';
    final meio = '$espacoAntes$pedaco';
    setState(() {
      _formula.value = TextEditingValue(
        text: '$antes$meio$espacoDepois$depois',
        selection: TextSelection.collapsed(offset: (antes + meio).length),
      );
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Dê um nome ao status');
      return;
    }
    final error = widget.validateName?.call(name);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    final v = double.tryParse(_value.text.replaceAll(',', '.')) ?? 0;
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
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.label_outline),
                  labelText: 'Nome do status',
                  hintText: 'ex.: Vida, Bônus de ataque, Comida',
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: _onNameChanged,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              _rotulo('Que tipo de informação é?',
                  icone: Icons.category_outlined),
              const SizedBox(height: 6),
              _linhaDeCartoes(_tipos[0], _tipos[1]),
              const SizedBox(height: 8),
              _linhaDeCartoes(_tipos[2], _tipos[3]),
              if (_tipoSugerido) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Escolhido pelo nome. Toque em outro tipo se não for.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              ..._camposDoTipo(),
              if (widget.showCategory) ..._camposDeCategoria(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Salvar'),
        ),
      ],
    );
  }

  /// Rótulo de seção; com [icone], o ícone vem antes do texto.
  Widget _rotulo(String texto, {IconData? icone}) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;
    final rotulo = Text(texto,
        style:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cor));
    if (icone == null) return rotulo;
    return Row(children: [
      Icon(icone, size: 16, color: cor),
      const SizedBox(width: 6),
      Expanded(child: rotulo),
    ]);
  }

  Widget _linhaDeCartoes(_TipoInfo a, _TipoInfo b) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _cartaoTipo(a)),
            const SizedBox(width: 8),
            Expanded(child: _cartaoTipo(b)),
          ],
        ),
      );

  Widget _cartaoTipo(_TipoInfo t) {
    final cs = Theme.of(context).colorScheme;
    final sel = _type == t.type;
    return Semantics(
      button: true,
      selected: sel,
      label: '${t.type.label}. ${t.explica}. Exemplo: ${t.exemplo}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _escolherTipo(t.type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: sel ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel ? cs.primary : cs.outlineVariant,
                width: sel ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  StatTypeBadge(t.type, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.type.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.w600)),
                  ),
                  if (sel) Icon(Icons.check_circle, size: 18, color: cs.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(t.explica,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('ex.: ${t.exemplo}',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  /// Os campos mudam conforme o tipo: só aparece o que aquele tipo precisa.
  List<Widget> _camposDoTipo() {
    switch (_type) {
      case StatType.trigger:
        final usados = widget.knownTriggers
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .take(12)
            .toList();
        return [
          TextField(
            controller: _trigger,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.bolt),
                labelText: 'Quando isso vale?',
                hintText: 'ex.: defendendo a base, liderando cavalaria',
                border: OutlineInputBorder()),
            maxLines: 2,
          ),
          if (usados.isNotEmpty) ...[
            const SizedBox(height: 8),
            _rotulo('Já usados neste jogo — toque para reusar:',
                icone: Icons.history),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: usados
                  .map((g) => ActionChip(
                        avatar: const Icon(Icons.bolt, size: 18),
                        label: Text(g, style: const TextStyle(fontSize: 13)),
                        tooltip: 'Usar o gatilho "$g"',
                        onPressed: () => setState(() => _trigger.text = g),
                      ))
                  .toList(),
            ),
          ],
        ];
      case StatType.formula:
        final nomes = widget.availableStatNames
            .where((n) => n.trim().isNotEmpty && n != _name.text.trim())
            .toList();
        return [
          TextField(
            controller: _formula,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calculate_outlined),
                labelText: 'Conta',
                hintText: 'toque nos botões abaixo para montar',
                border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _rotulo('Toque para montar a conta:',
              icone: Icons.touch_app_outlined),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final op in _operadores.entries)
                Tooltip(
                  message: op.value,
                  child: Semantics(
                    button: true,
                    label: op.value,
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => _inserirNaFormula(op.key),
                        child:
                            Text(op.key, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Apagar a conta',
                icon: const Icon(Icons.backspace_outlined),
                onPressed: () => setState(() => _formula.clear()),
              ),
            ],
          ),
          if (nomes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: nomes
                  .map((n) => ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(n, style: const TextStyle(fontSize: 13)),
                        tooltip: 'Pôr "$n" na conta',
                        onPressed: () => _inserirNaFormula(n),
                      ))
                  .toList(),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Crie outros status primeiro — eles aparecem aqui como botões.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ];
      case StatType.percent:
        return [
          TextField(
            controller: _value,
            decoration: InputDecoration(
              prefixIcon: Icon(StatType.percent.icon),
              labelText: widget.valueLabel,
              suffixText: '%',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Redesenha para o atalho certo ficar marcado enquanto digita.
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _atalhosDePorcentagem
                .map((p) => ChoiceChip(
                      label: Text('$p%', style: const TextStyle(fontSize: 13)),
                      selected: _value.text.trim() == '$p',
                      onSelected: (_) => setState(() => _value.text = '$p'),
                    ))
                .toList(),
          ),
        ];
      case StatType.number:
        return [
          TextField(
            controller: _value,
            decoration: InputDecoration(
              prefixIcon: Icon(StatType.number.icon),
              labelText: widget.valueLabel,
              hintText: 'ex.: 1500000',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
          ),
        ];
    }
  }

  List<Widget> _camposDeCategoria() => [
        const SizedBox(height: 14),
        TextField(
          controller: _category,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.folder_outlined),
            labelText: 'Categoria / sub-grupo (opcional)',
            hintText: 'ex.: Recursos, Status base, Bônus...',
            border: OutlineInputBorder(),
          ),
        ),
        if (widget.categories.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.categories
                .map((c) => ActionChip(
                      avatar: const Icon(Icons.folder_outlined, size: 18),
                      label: Text(c, style: const TextStyle(fontSize: 13)),
                      tooltip: 'Pôr na categoria "$c"',
                      onPressed: () => setState(() => _category.text = c),
                    ))
                .toList(),
          ),
        ],
      ];
}
