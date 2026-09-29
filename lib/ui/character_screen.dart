import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/character_ability.dart';
import '../models/character_stat.dart';
import '../models/character_type.dart';
import '../models/star_rank.dart';
import '../models/stat_type.dart';
import '../models/unit_type_label.dart';
import '../repositories/tracker_repository.dart';
import '../theme/app_theme.dart';
import 'widgets/group_icon.dart';
import 'widgets/star_rank_display.dart';
import 'widgets/stat_tile.dart';
import 'widgets/stat_form_dialog.dart';

class CharacterScreen extends StatefulWidget {
  final Character character;
  const CharacterScreen({super.key, required this.character});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  late Character _character;
  List<CharacterStat> _stats = [];
  List<CharacterAbility> _abilities = [];
  bool _loading = true;

  /// Como este jogo chama os tipos de unidade (o cabeçalho usa).
  UnitTypeNames _typeNames = UnitTypeNames.padrao;

  /// Quantos status por linha (1, 2 ou 3). Preferência de visualização —
  /// fica no shared_preferences, vale para todos os personagens.
  static const _kColumnsKey = 'stats_columns';
  static const _kColumnsDefault = 2;
  int _columns = _kColumnsDefault;

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _load();
    _loadColumns();
  }

  Future<void> _loadColumns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_kColumnsKey) ?? _kColumnsDefault;
      if (mounted) setState(() => _columns = v.clamp(1, 3));
    } catch (_) {
      // Sem preferência salva/plugin: segue com o padrão.
    }
  }

  Future<void> _setColumns(int v) async {
    setState(() => _columns = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kColumnsKey, v);
    } catch (_) {
      // Não conseguiu guardar: a escolha ainda vale nesta tela.
    }
  }

  Future<void> _load() async {
    final stats = await TrackerRepository.instance
        .getStatsByCharacter(_character.id!);
    final abilities = await TrackerRepository.instance
        .getAbilitiesByCharacter(_character.id!);
    final names = await TrackerRepository.instance
        .getEffectiveTypeNames(_character.groupId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _abilities = abilities;
        _typeNames = names;
        _loading = false;
      });
    }
  }

  /// Valor exibido do stat com os bônus das habilidades ATIVAS somados
  /// (simulação visual — o valor salvo nunca muda). null = sem bônus.
  double? _boostedValueFor(CharacterStat stat) {
    if (stat.type == StatType.trigger || stat.type == StatType.formula) {
      return null;
    }
    double bonus = 0;
    for (final a in _abilities) {
      if (!a.isActive || !a.hasEffect) continue;
      if (a.targetStatName!.toLowerCase() != stat.name.toLowerCase()) continue;
      bonus += a.bonusKind == 'percent'
          ? stat.value * a.bonusValue / 100
          : a.bonusValue;
    }
    if (bonus == 0) return null;
    return stat.value + bonus;
  }

  Future<void> _updateStat(CharacterStat stat) async {
    await TrackerRepository.instance.updateStat(stat);
    setState(() {
      final i = _stats.indexWhere((s) => s.id == stat.id);
      if (i >= 0) _stats[i] = stat;
    });
  }

  Future<void> _deleteStat(CharacterStat stat) async {
    await TrackerRepository.instance.deleteStat(stat.id!);
    setState(() => _stats.removeWhere((s) => s.id == stat.id));
  }

  /// Gatilhos já escritos neste personagem (status e habilidades) — o
  /// formulário oferece reusar com um toque.
  List<String> get _knownTriggers => [
        ..._stats
            .where((s) => s.type == StatType.trigger)
            .map((s) => s.triggerText ?? ''),
        ..._abilities.map((a) => a.triggerText ?? ''),
      ];

  Future<void> _addStat() async {
    final result = await showDialog<StatFormResult>(
      context: context,
      builder: (_) => StatFormDialog(
        title: 'Novo Status',
        availableStatNames: _stats.map((s) => s.name).toList(),
        knownTriggers: _knownTriggers,
        validateName: (name) => _stats
                .any((s) => s.name.toLowerCase() == name.toLowerCase())
            ? 'Já existe um status "$name"'
            : null,
      ),
    );
    if (result != null) {
      final saved = await TrackerRepository.instance.insertStat(
        CharacterStat(
          characterId: _character.id!,
          name: result.name,
          type: result.type,
          value: result.value,
          maxValue: result.maxValue,
          triggerText: result.triggerText,
          formulaText: result.formulaText,
          sortOrder: _stats.length,
        ),
      );
      setState(() => _stats.add(saved));
    }
  }

  Future<void> _editStat(CharacterStat stat) async {
    final result = await showDialog<StatFormResult>(
      context: context,
      builder: (_) => StatFormDialog(
        title: 'Editar Status',
        availableStatNames: _stats.map((s) => s.name).toList(),
        knownTriggers: _knownTriggers,
        initial: StatFormResult(
          name: stat.name,
          type: stat.type,
          value: stat.value,
          maxValue: stat.maxValue,
          triggerText: stat.triggerText,
          formulaText: stat.formulaText,
        ),
        validateName: (name) => _stats.any((s) =>
                s.id != stat.id &&
                s.name.toLowerCase() == name.toLowerCase())
            ? 'Já existe um status "$name"'
            : null,
      ),
    );
    if (result != null) {
      await _updateStat(CharacterStat(
        id: stat.id,
        characterId: stat.characterId,
        name: result.name,
        type: result.type,
        value: result.value,
        maxValue: result.maxValue,
        triggerText: result.triggerText,
        formulaText: result.formulaText,
        sortOrder: stat.sortOrder,
      ));
    }
  }

  Future<void> _updateStarRank(StarRank rank) async {
    final updated = _character.copyWith(starRank: rank);
    await TrackerRepository.instance.updateCharacter(updated);
    setState(() => _character = updated);
  }

  Future<void> _updateLevel(int delta) async {
    final newLevel = (_character.level + delta).clamp(1, 9999);
    final updated = _character.copyWith(level: newLevel);
    await TrackerRepository.instance.updateCharacter(updated);
    setState(() => _character = updated);
  }

  // ─── Habilidades ──────────────────────────────────────────────────────────

  /// Alvos válidos para efeito: só stats numéricos (gatilho/fórmula não têm
  /// valor que receba bônus); nomes únicos para o dropdown.
  List<String> get _statTargetNames => _stats
      .where(
          (s) => s.type != StatType.trigger && s.type != StatType.formula)
      .map((s) => s.name)
      .toSet()
      .toList();

  Future<void> _addAbility() async {
    final result = await showDialog<CharacterAbility>(
      context: context,
      builder: (_) => _AbilityDialog(
        characterId: _character.id!,
        statNames: _statTargetNames,
      ),
    );
    if (result != null) {
      final saved = await TrackerRepository.instance.insertAbility(
        result.copyWith(
            sortOrder:
                _abilities.isEmpty ? 0 : _abilities.last.sortOrder + 1),
      );
      setState(() => _abilities.add(saved));
    }
  }

  Future<void> _editAbility(CharacterAbility ability) async {
    final result = await showDialog<CharacterAbility>(
      context: context,
      builder: (_) => _AbilityDialog(
        characterId: _character.id!,
        statNames: _statTargetNames,
        initial: ability,
      ),
    );
    if (result != null) {
      await TrackerRepository.instance.updateAbility(result);
      setState(() {
        final i = _abilities.indexWhere((a) => a.id == ability.id);
        if (i >= 0) _abilities[i] = result;
      });
    }
  }

  Future<void> _deleteAbility(CharacterAbility ability) async {
    await TrackerRepository.instance.deleteAbility(ability.id!);
    setState(() => _abilities.removeWhere((a) => a.id == ability.id));
  }

  Future<void> _toggleAbility(CharacterAbility ability, bool active) async {
    final updated = ability.copyWith(isActive: active);
    await TrackerRepository.instance.updateAbility(updated);
    setState(() {
      final i = _abilities.indexWhere((a) => a.id == ability.id);
      if (i >= 0) _abilities[i] = updated;
    });
  }

  Widget _statTile(CharacterStat stat, {required bool compacto}) => StatTile(
        stat: stat,
        boostedValue: _boostedValueFor(stat),
        margin: compacto ? const EdgeInsets.all(4) : null,
        onEdit: () => _editStat(stat),
        onDelete: () => _deleteStat(stat),
      );

  /// Uma linha de status: 1 card inteiro, ou [_columns] cards lado a lado
  /// com a mesma altura (a do maior).
  Widget _statRow(int row) {
    final start = row * _columns;
    final linha = _stats.sublist(
        start, (start + _columns).clamp(start, _stats.length));
    if (_columns == 1) return _statTile(linha.first, compacto: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final s in linha)
              Expanded(child: _statTile(s, compacto: true)),
            // Linha incompleta: os vazios seguram a largura para o último
            // card não ficar esticado no dobro do tamanho dos outros.
            for (var i = linha.length; i < _columns; i++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_character.name),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_module_outlined),
            tooltip: 'Status por linha',
            initialValue: _columns,
            onSelected: _setColumns,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('1 por linha (grande)')),
              PopupMenuItem(value: 2, child: Text('2 por linha')),
              PopupMenuItem(value: 3, child: Text('3 por linha (compacto)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _addStat,
            tooltip: 'Novo status',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _HeaderCard(
                  character: _character,
                  names: _typeNames,
                  onStarChanged: _updateStarRank,
                  onLevelChanged: _updateLevel,
                )),
                // Status em 1, 2 ou 3 colunas. Não é SliverGrid de propósito:
                // grid exige altura fixa e o card muda de altura conforme o
                // tipo (barra de %, fórmula, linha de bônus) — estouraria.
                // IntrinsicHeight deixa a linha com a altura do maior card.
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, row) => _statRow(row),
                    childCount:
                        (_stats.length + _columns - 1) ~/ _columns,
                  ),
                ),
                if (_stats.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart,
                                size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 12),
                            Text('Nenhum status ainda',
                                style: TextStyle(
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _addStat,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Status'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // ⚡ Habilidades do herói
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
                    child: Row(
                      children: [
                        const Text('⚡ Habilidades',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'Nova habilidade',
                          onPressed: _addAbility,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_abilities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Nenhuma habilidade — descrição + gatilho + bônus em um status.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final ability = _abilities[i];
                        return _AbilityCard(
                          ability: ability,
                          statExists: !ability.hasEffect ||
                              _stats.any((s) =>
                                  s.name.toLowerCase() ==
                                  ability.targetStatName!.toLowerCase()),
                          onToggle: (v) => _toggleAbility(ability, v),
                          onEdit: () => _editAbility(ability),
                          onDelete: () => _deleteAbility(ability),
                        );
                      },
                      childCount: _abilities.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStat,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Header com estrelas e informações do personagem ─────────────────────────

class _HeaderCard extends StatelessWidget {
  final Character character;
  final UnitTypeNames names;
  final void Function(StarRank) onStarChanged;
  final void Function(int delta) onLevelChanged;

  const _HeaderCard({
    required this.character,
    required this.names,
    required this.onStarChanged,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha:0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Foto só aparece se existir — sem foto o cabeçalho fica igual
              // ao de sempre (o emoji do tipo já aparece logo abaixo do nome).
              if (character.iconImagePath != null) ...[
                GroupIcon(
                    imagePath: character.iconImagePath,
                    emoji: names.emojiOf(character.characterType),
                    size: 64,
                    emojiSize: 28),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(character.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(names.emojiOf(character.characterType),
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(names.labelOf(character.characterType),
                            style: TextStyle(
                                fontSize: 12,
                                color: character.characterType ==
                                        CharacterType.heroi
                                    ? Colors.amber.shade600
                                    : character.characterType ==
                                            CharacterType.comandante
                                        ? Colors.blue.shade300
                                        : Colors.grey.shade500,
                                fontWeight: FontWeight.w600)),
                        if (!character.characterType.entersBattle) ...[
                          const SizedBox(width: 8),
                          Text('· não entra em batalha',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                    if (character.role != null) ...[
                      const SizedBox(height: 2),
                      Text(character.role!,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StarRankDisplay(rank: character.starRank, maxStars: 10),
          const SizedBox(height: 10),
          // Controles de nível
          Row(
            children: [
              Text('Nível',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              _RankButton(
                label: '−',
                tooltip: 'Diminuir nível',
                onTap: character.level > 1 ? () => onLevelChanged(-1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${character.level}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _RankButton(
                label: '+',
                tooltip: 'Aumentar nível',
                onTap: () => onLevelChanged(1),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Controles de rank
          Row(
            children: [
              _RankButton(
                label: '+1 sub',
                tooltip: 'Avançar 1 sub-nível',
                onTap: () => onStarChanged(character.starRank.advanceSubLevel()),
              ),
              const SizedBox(width: 8),
              _RankButton(
                label: '+1 ⭐',
                tooltip: 'Avançar 1 estrela completa',
                onTap: () => onStarChanged(character.starRank.advanceStar()),
                highlight: true,
              ),
              const SizedBox(width: 8),
              _RankButton(
                label: '−1 ⭐',
                tooltip: 'Reduzir 1 estrela',
                onTap: character.starRank.stars > 0
                    ? () => onStarChanged(StarRank(
                          stars: character.starRank.stars - 1,
                          subLevel: character.starRank.subLevel,
                        ))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback? onTap;
  final bool highlight;

  const _RankButton({
    required this.label,
    required this.tooltip,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: highlight ? AppTheme.gold : null,
          side: BorderSide(
              color: highlight
                  ? AppTheme.gold
                  : Colors.grey.shade600),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}


// ─── Habilidades: card e dialog ──────────────────────────────────────────────

class _AbilityCard extends StatelessWidget {
  final CharacterAbility ability;

  /// false quando o efeito aponta para um stat que não existe mais.
  final bool statExists;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AbilityCard({
    required this.ability,
    required this.statExists,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ability.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if ((ability.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(ability.description!,
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade400)),
                  ],
                  if (ability.hasEffect) ...[
                    const SizedBox(height: 4),
                    Text(
                      '⚡ ${(ability.triggerText ?? '').isEmpty ? 'sempre' : ability.triggerText} '
                      '→ ${ability.bonusLabel} ${ability.targetStatName}',
                      style: TextStyle(
                          fontSize: 12,
                          color: statExists ? primary : Colors.red.shade300,
                          fontWeight: FontWeight.w600),
                    ),
                    if (!statExists)
                      Text('status não existe mais — efeito inerte',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red.shade300)),
                  ],
                ],
              ),
            ),
            if (ability.hasEffect)
              Switch(
                value: ability.isActive,
                onChanged: statExists ? onToggle : null,
              ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Deletar',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityDialog extends StatefulWidget {
  final int characterId;
  final List<String> statNames;
  final CharacterAbility? initial;

  const _AbilityDialog({
    required this.characterId,
    required this.statNames,
    this.initial,
  });

  @override
  State<_AbilityDialog> createState() => _AbilityDialogState();
}

class _AbilityDialogState extends State<_AbilityDialog> {
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _trigger;
  late TextEditingController _bonus;
  String? _targetStat; // null = sem efeito
  String _bonusKind = 'flat';
  String? _nameError;
  String? _bonusError;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _name = TextEditingController(text: a?.name ?? '');
    _desc = TextEditingController(text: a?.description ?? '');
    _trigger = TextEditingController(text: a?.triggerText ?? '');
    _bonus = TextEditingController(
        text: a != null && a.hasEffect
            ? (a.bonusValue % 1 == 0
                ? a.bonusValue.toStringAsFixed(0)
                : a.bonusValue.toString())
            : '');
    _bonusKind = a?.bonusKind ?? 'flat';
    // Stat alvo: casa por nome ignorando maiúsculas (adota o nome atual da
    // lista); se o stat não existir mais, PRESERVA o nome órfão — editar a
    // habilidade não pode apagar o efeito silenciosamente.
    final t = a?.targetStatName;
    if (t == null || t.trim().isEmpty) {
      _targetStat = null;
    } else {
      _targetStat = widget.statNames.firstWhere(
        (n) => n.toLowerCase() == t.toLowerCase(),
        orElse: () => t,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _trigger.dispose();
    _bonus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar Habilidade' : 'Nova Habilidade'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: 'Nome',
                  border: const OutlineInputBorder(),
                  errorText: _nameError),
              autofocus: !isEdit,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'ex.: quando em campo dá mais 20 de ataque',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _trigger,
              decoration: const InputDecoration(
                  labelText: 'Gatilho (condição)',
                  hintText: 'ex.: atacando uma base',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Text('Efeito (opcional)',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (widget.statNames.isEmpty && _targetStat == null)
              Text('Sem status disponíveis — crie status primeiro.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500))
            else ...[
              DropdownButtonFormField<String?>(
                initialValue: _targetStat,
                decoration: const InputDecoration(
                    labelText: 'Status alvo', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('— sem efeito —')),
                  ...widget.statNames.map((n) =>
                      DropdownMenuItem<String?>(value: n, child: Text(n))),
                  // Alvo órfão (stat apagado): mantém o efeito configurado
                  // em vez de apagá-lo silenciosamente ao salvar.
                  if (_targetStat != null &&
                      !widget.statNames.contains(_targetStat))
                    DropdownMenuItem<String?>(
                        value: _targetStat,
                        child: Text('$_targetStat (não existe)')),
                ],
                onChanged: (v) => setState(() => _targetStat = v),
              ),
              if (_targetStat != null &&
                  !widget.statNames.contains(_targetStat))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'O status alvo não existe mais — o efeito fica inerte '
                      'até recriar o status ou escolher outro.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.red.shade300)),
                ),
              if (_targetStat != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bonus,
                        decoration: InputDecoration(
                            labelText: 'Bônus (ex.: 20 ou -5)',
                            border: const OutlineInputBorder(),
                            errorText: _bonusError),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        onChanged: (_) {
                          if (_bonusError != null) {
                            setState(() => _bonusError = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'flat', label: Text('+N')),
                        ButtonSegment(value: 'percent', label: Text('%')),
                      ],
                      selected: {_bonusKind},
                      onSelectionChanged: (s) =>
                          setState(() => _bonusKind = s.first),
                    ),
                  ],
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
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _nameError = 'Informe o nome');
              return;
            }
            double bonus = 0;
            if (_targetStat != null) {
              final raw = _bonus.text.trim().replaceAll(',', '.');
              final parsed = raw.isEmpty ? 0.0 : double.tryParse(raw);
              if (parsed == null) {
                setState(() => _bonusError = 'Valor inválido');
                return;
              }
              bonus = parsed;
            }
            final base = widget.initial ??
                CharacterAbility(
                    characterId: widget.characterId, name: '');
            Navigator.pop(
              context,
              CharacterAbility(
                id: base.id,
                characterId: base.characterId,
                name: name,
                description:
                    _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                triggerText:
                    _trigger.text.trim().isEmpty ? null : _trigger.text.trim(),
                targetStatName: _targetStat,
                bonusValue: bonus,
                bonusKind: _bonusKind,
                // Efeito removido → desliga; senão preserva o estado do toggle.
                isActive: _targetStat == null ? false : base.isActive,
                sortOrder: base.sortOrder,
              ),
            );
          },
          child: Text(isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
