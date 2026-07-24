import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../models/character.dart';
import '../models/character_type.dart';
import '../models/content_category.dart';
import '../models/group_stat_template.dart';
import '../models/stat_type.dart';
import '../repositories/tracker_repository.dart';
import 'character_screen.dart';
import 'skill_tree_screen.dart';
import 'stats_screen.dart';
import 'widgets/group_icon.dart';
import 'widgets/star_rank_display.dart';

class GameScreen extends StatefulWidget {
  final GameGroup group;
  const GameScreen({super.key, required this.group});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameGroup _group;
  List<Character> _characters = [];
  List<GameGroup> _subGroups = [];
  List<GroupStatTemplate> _templates = [];
  // Usados só quando _templates é vazio: sub-grupo herda os do ancestral.
  List<GroupStatTemplate> _inheritedTemplates = [];
  bool _loading = true;
  ContentCategory? _selectedCategory; // null = todos

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _load();
  }

  Future<void> _load() async {
    final chars = await TrackerRepository.instance
        .getCharactersByGroup(_group.id!);
    final subs = await TrackerRepository.instance
        .getSubGroups(_group.id!);
    final templates = await TrackerRepository.instance
        .getTemplatesByGroup(_group.id!);
    // Sub-grupo sem templates próprios herda os do ancestral — carregamos
    // para exibir (read-only) em vez de mentir que "nasce sem status".
    final inherited = templates.isEmpty && _group.parentId != null
        ? await TrackerRepository.instance.getEffectiveTemplates(_group.id!)
        : <GroupStatTemplate>[];
    if (mounted)
      setState(() {
        _characters = chars;
        _subGroups = subs;
        _templates = templates;
        _inheritedTemplates = inherited;
        _loading = false;
      });
  }

  Future<void> _addSubGroup() async {
    final result = await showDialog<GameGroup>(
      context: context,
      builder: (_) => _SubGroupDialog(parentId: _group.id!),
    );
    if (result != null) {
      final sg = await TrackerRepository.instance.insertGroup(result);
      setState(() => _subGroups.add(sg));
    }
  }

  /// Cria os 4 sub-grupos padrão de jogo estratégico de uma vez.
  Future<void> _applyStrategyTemplate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Template Estratégico'),
        content: const Text(
          'Cria 4 sub-grupos padrão:\n\n'
          '⚔️ Heróis\n🪖 Tropas\n🔬 Pesquisa\n🏗️ Construção\n\n'
          'Sub-grupos existentes com o mesmo nome não serão duplicados.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar')),
        ],
      ),
    );
    if (confirm != true) return;

    final templates = [
      (name: 'Heróis',    emoji: '⚔️', cat: ContentCategory.heroes),
      (name: 'Tropas',    emoji: '🪖', cat: ContentCategory.troops),
      (name: 'Pesquisa',  emoji: '🔬', cat: ContentCategory.research),
      (name: 'Construção',emoji: '🏗️', cat: ContentCategory.building),
    ];

    final existingNames = _subGroups.map((sg) => sg.name).toSet();
    for (final t in templates) {
      if (existingNames.contains(t.name)) continue;
      final sg = await TrackerRepository.instance.insertGroup(
        GameGroup(
          parentId: _group.id,
          name: t.name,
          iconEmoji: t.emoji,
          createdAt: DateTime.now(),
          contentCategory: t.cat,
        ),
      );
      if (mounted) setState(() => _subGroups.add(sg));
    }
  }

  Future<void> _openStatsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsScreen(group: _group)),
    );
    _load();
  }

  Future<void> _addCharacter() async {
    // Modelo efetivo: os do grupo, ou os herdados do ancestral.
    final effective =
        _templates.isNotEmpty ? _templates : _inheritedTemplates;
    Set<int>? chosen;
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(
        groupId: _group.id!,
        templates: effective,
        onTemplateSelection: (ids) => chosen = ids,
      ),
    );
    if (result != null) {
      final saved =
          await TrackerRepository.instance.insertCharacter(result);
      // Personagem novo nasce com os stats marcados nas caixinhas
      // (padrão: todos os do modelo).
      await TrackerRepository.instance.applyGroupTemplatesToCharacter(
        saved,
        onlyTemplateIds: chosen,
      );
      setState(() => _characters.add(saved));
    }
  }

  Future<void> _editCharacter(Character c) async {
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(groupId: _group.id!, initial: c),
    );
    if (result != null) {
      await TrackerRepository.instance.updateCharacter(result);
      setState(() {
        final i = _characters.indexWhere((x) => x.id == c.id);
        if (i >= 0) _characters[i] = result;
      });
    }
  }

  Future<void> _deleteCharacter(Character c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar personagem'),
        content: Text('Deletar "${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deletar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await TrackerRepository.instance.deleteCharacter(c.id!);
      setState(() => _characters.removeWhere((x) => x.id == c.id));
    }
  }

  Future<void> _editSquadConfig() async {
    final result = await showDialog<GameGroup>(
      context: context,
      builder: (_) => _SquadConfigDialog(group: _group),
    );
    if (result != null) {
      await TrackerRepository.instance.updateGroup(result);
      setState(() => _group = result);
    }
  }

  /// Sub-grupos filtrados pela categoria selecionada.
  List<GameGroup> get _filteredSubGroups => _selectedCategory == null
      ? _subGroups
      : _subGroups
          .where((sg) => sg.contentCategory == _selectedCategory)
          .toList();

  /// Conta quantos personagens de cada tipo existem.
  Map<CharacterType, int> get _typeCounts {
    final m = <CharacterType, int>{};
    for (final c in _characters) {
      m[c.characterType] = (m[c.characterType] ?? 0) + 1;
    }
    return m;
  }

  /// Verifica se algum limite de esquadrão foi ultrapassado.
  String? get _squadWarning {
    final counts = _typeCounts;
    final warnings = <String>[];
    if (_group.maxHeroesPerSquad != null) {
      final h = counts[CharacterType.heroi] ?? 0;
      if (h > _group.maxHeroesPerSquad!) {
        warnings.add('Heróis: $h / ${_group.maxHeroesPerSquad} (excedido)');
      }
    }
    if (_group.maxCommandersPerSquad != null) {
      final c = counts[CharacterType.comandante] ?? 0;
      if (c > _group.maxCommandersPerSquad!) {
        warnings.add('Comandantes: $c / ${_group.maxCommandersPerSquad} (excedido)');
      }
    }
    return warnings.isEmpty ? null : warnings.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_group.iconEmoji ?? '⚔️'} ${_group.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SkillTreeScreen(group: _group),
              ),
            ),
            tooltip: 'Árvore de habilidades',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _editSquadConfig,
            tooltip: 'Configurar esquadrão',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _applyStrategyTemplate,
            tooltip: 'Template estratégico (Heróis + Tropas + Pesquisa + Construção)',
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _addSubGroup,
            tooltip: 'Novo sub-grupo',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addCharacter,
            tooltip: 'Novo personagem',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Estatísticas do jogo — abre a tela exclusiva de gerência
                _StatsNavCard(
                  templateCount: _templates.length,
                  inheritedCount: _inheritedTemplates.length,
                  onOpen: _openStatsScreen,
                ),

                // Banner de configuração do esquadrão
                if (_group.maxHeroesPerSquad != null ||
                    _group.maxCommandersPerSquad != null)
                  _SquadSummaryBar(
                    group: _group,
                    typeCounts: _typeCounts,
                    warning: _squadWarning,
                  ),

                // Chips de categoria (só se houver sub-grupos)
                if (_subGroups.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 6),
                        ...ContentCategory.values.map((cat) {
                          final hasAny =
                              _subGroups.any((sg) => sg.contentCategory == cat);
                          if (!hasAny) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label:
                                  Text('${cat.emoji} ${cat.label}'),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() =>
                                  _selectedCategory = _selectedCategory == cat
                                      ? null
                                      : cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Sub-grupos
                if (_filteredSubGroups.isNotEmpty) ...[
                  Text('Sub-grupos',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ..._filteredSubGroups.map((sg) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: GroupIcon(
                              imagePath: sg.iconImagePath,
                              emoji: sg.iconEmoji ?? '📁',
                              size: 24),
                          title: Text(sg.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GameScreen(group: sg),
                              ),
                            );
                            _load();
                          },
                        ),
                      )),
                  const Divider(height: 20),
                ],

                // Personagens
                if (_characters.isEmpty)
                  _EmptyState(
                    onAdd: _addCharacter,
                    hasModel: _templates.isNotEmpty ||
                        _inheritedTemplates.isNotEmpty,
                    onCreateModel: _openStatsScreen,
                  )
                else
                  ...List.generate(
                    _characters.length,
                    (i) => _CharacterCard(
                      character: _characters[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CharacterScreen(character: _characters[i]),
                          ),
                        );
                        _load();
                      },
                      onEdit: () => _editCharacter(_characters[i]),
                      onDelete: () => _deleteCharacter(_characters[i]),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCharacter,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─── Seção de estatísticas base do jogo (templates do grupo) ────────────────

class _StatsNavCard extends StatelessWidget {
  final int templateCount;
  final int inheritedCount;
  final Future<void> Function() onOpen;

  const _StatsNavCard({
    required this.templateCount,
    required this.inheritedCount,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (templateCount > 0) {
      subtitle = '$templateCount status · toque para gerenciar e organizar';
    } else if (inheritedCount > 0) {
      subtitle =
          '$inheritedCount herdado(s) do grupo pai · toque para ver/personalizar';
    } else {
      subtitle = 'Nenhum status ainda · toque para criar';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Text('📊', style: TextStyle(fontSize: 26)),
        title: const Text('Estatísticas do jogo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

// ─── Barra de resumo do esquadrão ────────────────────────────────────────────

class _SquadSummaryBar extends StatelessWidget {
  final GameGroup group;
  final Map<CharacterType, int> typeCounts;
  final String? warning;

  const _SquadSummaryBar({
    required this.group,
    required this.typeCounts,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final heroes = typeCounts[CharacterType.heroi] ?? 0;
    final commanders = typeCounts[CharacterType.comandante] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning != null
            ? Colors.orange.withOpacity(0.12)
            : Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: warning != null
              ? Colors.orange.withOpacity(0.4)
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14),
              const SizedBox(width: 4),
              Text('Esquadrão',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400)),
              const Spacer(),
              if (group.maxHeroesPerSquad != null)
                _TypeChip(
                  emoji: '⚔️',
                  count: heroes,
                  max: group.maxHeroesPerSquad!,
                  exceeded: heroes > group.maxHeroesPerSquad!,
                ),
              if (group.maxCommandersPerSquad != null) ...[
                const SizedBox(width: 6),
                _TypeChip(
                  emoji: '👑',
                  count: commanders,
                  max: group.maxCommandersPerSquad!,
                  exceeded: commanders > group.maxCommandersPerSquad!,
                ),
              ],
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Text(warning!,
                style: const TextStyle(
                    fontSize: 11, color: Colors.orange)),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String emoji;
  final int count;
  final int max;
  final bool exceeded;

  const _TypeChip({
    required this.emoji,
    required this.count,
    required this.max,
    required this.exceeded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: exceeded
            ? Colors.orange.withOpacity(0.2)
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $count/$max',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: exceeded ? Colors.orange : null,
        ),
      ),
    );
  }
}

// ─── Card de personagem ───────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _typeColor(BuildContext context) {
    switch (character.characterType) {
      case CharacterType.heroi:
        return Colors.amber.shade700;
      case CharacterType.comandante:
        return Theme.of(context).colorScheme.primary;
      case CharacterType.soldadoNormal:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _typeColor(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Emoji do tipo
              Text(
                character.characterType.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(character.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tc.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            character.characterType.label,
                            style: TextStyle(
                                fontSize: 11,
                                color: tc,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (character.role != null) ...[
                      const SizedBox(height: 2),
                      Text(character.role!,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StarRankDisplay(
                          rank: character.starRank,
                          starSize: 16,
                          showSubLevelText: false,
                        ),
                        const Spacer(),
                        Text(
                          'Nv. ${character.level}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    // Nota: comandante não entra em batalha
                    if (character.characterType == CharacterType.comandante)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '👑 Não entra em batalha diretamente',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    color: Colors.grey.shade400,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    color: Colors.red.shade300,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  /// true quando o grupo já tem modelo de status (próprio ou herdado).
  final bool hasModel;
  final VoidCallback? onCreateModel;

  const _EmptyState({
    required this.onAdd,
    this.hasModel = true,
    this.onCreateModel,
  });

  @override
  Widget build(BuildContext context) {
    // Sem modelo de status: guia a criar o modelo ANTES dos personagens
    // (personagens nascem seguindo o modelo). Criar sem modelo continua
    // possível como caminho secundário (fallback).
    if (!hasModel && onCreateModel != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Crie primeiro o modelo de status',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Defina os status do jogo (Vida, Defesa, Ouro...) — todo '
                'personagem novo já nasce seguindo esse modelo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreateModel,
                icon: const Icon(Icons.add_chart),
                label: const Text('Criar modelo de status'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAdd,
                child: Text('Criar personagem sem modelo',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧙', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Nenhum personagem ainda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Novo Personagem'),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog criar/editar personagem ──────────────────────────────────────────

class _CharacterDialog extends StatefulWidget {
  final int groupId;
  final Character? initial;

  /// Status do modelo do grupo (efetivos) — exibidos com caixinhas na CRIAÇÃO
  /// para escolher quais o personagem terá. Vazio/edição: seção não aparece.
  final List<GroupStatTemplate> templates;

  /// Chamado ao Criar com os ids dos templates marcados.
  final void Function(Set<int> ids)? onTemplateSelection;

  const _CharacterDialog({
    required this.groupId,
    this.initial,
    this.templates = const [],
    this.onTemplateSelection,
  });

  @override
  State<_CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<_CharacterDialog> {
  late TextEditingController _name;
  late TextEditingController _role;
  late CharacterType _type;
  late Set<int> _selectedTemplateIds;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _role = TextEditingController(text: widget.initial?.role ?? '');
    _type = widget.initial?.characterType ?? CharacterType.soldadoNormal;
    // Todos marcados por padrão.
    _selectedTemplateIds =
        widget.templates.map((t) => t.id).whereType<int>().toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar Personagem' : 'Novo Personagem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nome', border: OutlineInputBorder()),
              autofocus: !isEdit,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _role,
              decoration: const InputDecoration(
                  labelText: 'Função/Classe (opcional)',
                  hintText: 'ex.: Tank, DPS, Support',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Text('Tipo de unidade',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Seletor de tipo com cards visuais
            Row(
              children: CharacterType.values.map((t) {
                final selected = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(t.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_type == CharacterType.comandante) ...[
              const SizedBox(height: 8),
              Text(
                '👑 Comandantes não entram em batalha diretamente, mas podem ser monitorados e têm notas.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            // Status do modelo — só na criação, com caixinhas: nem todo
            // status vale para todo personagem.
            if (!isEdit && widget.templates.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Status do modelo (desmarque os que não valem)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...widget.templates.map((t) {
                final id = t.id;
                if (id == null) return const SizedBox.shrink();
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${t.name} · ${t.type.label}',
                      style: const TextStyle(fontSize: 13)),
                  value: _selectedTemplateIds.contains(id),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedTemplateIds.add(id);
                    } else {
                      _selectedTemplateIds.remove(id);
                    }
                  }),
                );
              }),
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
            if (_name.text.trim().isEmpty) return;
            widget.onTemplateSelection?.call(_selectedTemplateIds);
            final base = widget.initial ??
                Character(
                  groupId: widget.groupId,
                  name: '',
                  createdAt: DateTime.now(),
                );
            Navigator.pop(
              context,
              base.copyWith(
                name: _name.text.trim(),
                role: _role.text.trim().isEmpty ? null : _role.text.trim(),
                clearRole: _role.text.trim().isEmpty,
                characterType: _type,
              ),
            );
          },
          child: Text(isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}

// ─── Dialog de configuração do esquadrão ─────────────────────────────────────

class _SquadConfigDialog extends StatefulWidget {
  final GameGroup group;
  const _SquadConfigDialog({required this.group});

  @override
  State<_SquadConfigDialog> createState() => _SquadConfigDialogState();
}

class _SquadConfigDialogState extends State<_SquadConfigDialog> {
  late TextEditingController _maxHeroes;
  late TextEditingController _maxCommanders;

  @override
  void initState() {
    super.initState();
    _maxHeroes = TextEditingController(
      text: widget.group.maxHeroesPerSquad?.toString() ?? '',
    );
    _maxCommanders = TextEditingController(
      text: widget.group.maxCommandersPerSquad?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _maxHeroes.dispose();
    _maxCommanders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Esquadrão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Defina quantos heróis e comandantes podem existir neste grupo. Deixe em branco para sem limite.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxHeroes,
            decoration: const InputDecoration(
              labelText: '⚔️  Max de heróis por esquadrão',
              hintText: 'Sem limite',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxCommanders,
            decoration: const InputDecoration(
              labelText: '👑  Max de comandantes por esquadrão',
              hintText: 'Sem limite',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            'Comandantes não entram em batalha diretamente — são líderes/generais.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final maxH = int.tryParse(_maxHeroes.text.trim());
            final maxC = int.tryParse(_maxCommanders.text.trim());
            Navigator.pop(
              context,
              widget.group.copyWith(
                maxHeroesPerSquad: maxH,
                clearMaxHeroes: _maxHeroes.text.trim().isEmpty,
                maxCommandersPerSquad: maxC,
                clearMaxCommanders: _maxCommanders.text.trim().isEmpty,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ─── Dialog para criar sub-grupo com categoria ───────────────────────────────

class _SubGroupDialog extends StatefulWidget {
  final int parentId;
  const _SubGroupDialog({required this.parentId});

  @override
  State<_SubGroupDialog> createState() => _SubGroupDialogState();
}

class _SubGroupDialogState extends State<_SubGroupDialog> {
  late TextEditingController _name;
  ContentCategory _category = ContentCategory.general;
  String _emoji = '📁';

  static const _categoryEmojis = {
    ContentCategory.heroes:   '⚔️',
    ContentCategory.troops:   '🪖',
    ContentCategory.research: '🔬',
    ContentCategory.building: '🏗️',
    ContentCategory.general:  '📋',
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _onCategoryChanged(ContentCategory cat) {
    setState(() {
      _category = cat;
      _emoji = _categoryEmojis[cat]!;
      // Preenche nome automaticamente se estiver vazio
      if (_name.text.isEmpty) _name.text = cat.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Sub-grupo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoria',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContentCategory.values.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => _onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${cat.emoji} ${cat.label}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nome do sub-grupo',
                  border: OutlineInputBorder()),
              autofocus: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return;
            Navigator.pop(
              context,
              GameGroup(
                parentId: widget.parentId,
                name: n,
                iconEmoji: _emoji,
                createdAt: DateTime.now(),
                contentCategory: _category,
              ),
            );
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

// ─── Dialog simples de nome ───────────────────────────────────────────────────

class _SimpleNameDialog extends StatefulWidget {
  final String title;
  final String hint;
  const _SimpleNameDialog({required this.title, required this.hint});

  @override
  State<_SimpleNameDialog> createState() => _SimpleNameDialogState();
}

class _SimpleNameDialogState extends State<_SimpleNameDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
            hintText: widget.hint, border: const OutlineInputBorder()),
        autofocus: true,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
