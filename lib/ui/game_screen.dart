import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../models/character.dart';
import '../models/character_type.dart';
import '../models/character_type_suggestion.dart';
import '../models/content_category.dart';
import '../models/group_stat_template.dart';
import '../models/stat_type.dart';
import '../models/unit_type_label.dart';
import '../repositories/tracker_repository.dart';
import '../services/icon_image_store.dart';
import 'character_screen.dart';
import 'skill_tree_screen.dart';
import 'stats_screen.dart';
import 'widgets/group_icon.dart';
import 'widgets/item_actions.dart';
import 'widgets/option_card.dart';
import 'widgets/star_rank_display.dart';
import 'widgets/stat_type_visual.dart';

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

  /// Como ESTE jogo chama os tipos de unidade (ex.: "Herói" → "Comandante").
  UnitTypeNames _typeNames = UnitTypeNames.padrao;

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
    final typeNames = await TrackerRepository.instance
        .getEffectiveTypeNames(_group.id!);
    if (mounted) {
      setState(() {
        _characters = chars;
        _subGroups = subs;
        _templates = templates;
        _inheritedTemplates = inherited;
        _typeNames = typeNames;
        _loading = false;
      });
    }
  }

  /// Renomear os tipos de unidade deste jogo (sem código).
  Future<void> _editTypeNames() async {
    final mudou = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _TypeNamesDialog(groupId: _group.id!, names: _typeNames),
    );
    if (mudou == true) _load();
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

  /// Abre a tela do personagem e recarrega ao voltar (ele muda lá dentro).
  Future<void> _openCharacter(Character c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CharacterScreen(character: c)),
    );
    _load();
  }

  /// Grava um personagem novo: nasce com os status marcados nas caixinhas
  /// (padrão: todos os do modelo) e entra na lista na hora.
  Future<Character> _saveNewCharacter(
      Character c, Set<int>? templateIds) async {
    // Transação única: se um insert falha, nada fica gravado pela metade.
    final saved = await TrackerRepository.instance
        .insertCharacterWithTemplates(c, onlyTemplateIds: templateIds);
    if (mounted) setState(() => _characters.add(saved));
    return saved;
  }

  Future<void> _addCharacter() async {
    // Antes de carregar, modelo e nomes existentes ainda estão vazios: o
    // personagem nasceria sem status e a checagem de nome repetido falharia.
    if (_loading) return;
    // Modelo efetivo: os do grupo, ou os herdados do ancestral.
    final effective =
        _templates.isNotEmpty ? _templates : _inheritedTemplates;
    final criado = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(
        groupId: _group.id!,
        templates: effective,
        names: _typeNames,
        initialType: suggestCharacterType(
            _characters.map((c) => c.characterType), _group.contentCategory),
        takenNames: _characters.map((c) => c.name).toList(),
        onCreate: _saveNewCharacter,
      ),
    );
    // "Criar e abrir": o dialog já gravou — abre direto para preencher.
    if (criado != null && mounted) await _openCharacter(criado);
  }

  Future<void> _editCharacter(Character c) async {
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(
        groupId: _group.id!,
        initial: c,
        names: _typeNames,
        takenNames: _characters
            .where((x) => x.id != c.id)
            .map((x) => x.name)
            .toList(),
      ),
    );
    if (result != null) {
      await TrackerRepository.instance.updateCharacter(result);
      // Foto antiga trocada/removida → apaga o PNG interno que ficou órfão.
      final oldIcon = c.iconImagePath;
      if (oldIcon != null && oldIcon != result.iconImagePath) {
        IconImageStore.deleteIcon(oldIcon);
      }
      setState(() {
        final i = _characters.indexWhere((x) => x.id == c.id);
        if (i >= 0) _characters[i] = result;
      });
    }
  }

  Future<void> _deleteCharacter(Character c) async {
    final ok = await confirmDelete(context,
        itemName: c.name,
        detalhe: 'Os status, as habilidades e a foto vão junto.');
    if (ok) {
      await TrackerRepository.instance.deleteCharacter(c.id!);
      IconImageStore.deleteIcon(c.iconImagePath);
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
        warnings.add('${_typeNames.labelOf(CharacterType.heroi)}: '
            '$h / ${_group.maxHeroesPerSquad} (excedido)');
      }
    }
    if (_group.maxCommandersPerSquad != null) {
      final c = counts[CharacterType.comandante] ?? 0;
      if (c > _group.maxCommandersPerSquad!) {
        warnings.add('${_typeNames.labelOf(CharacterType.comandante)}: '
            '$c / ${_group.maxCommandersPerSquad} (excedido)');
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
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _addSubGroup,
            tooltip: 'Novo sub-grupo',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addCharacter,
            tooltip: 'Novo personagem',
          ),
          // Os ajustes do jogo ficam juntos aqui — a barra tinha 5 ícones e
          // não cabia na largura de celular.
          PopupMenuButton<String>(
            tooltip: 'Ajustes do jogo',
            onSelected: (v) {
              if (v == 'nomes') _editTypeNames();
              if (v == 'esquadrao') _editSquadConfig();
              if (v == 'template') _applyStrategyTemplate();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'nomes',
                  child: Text('Nomes dos tipos de unidade')),
              PopupMenuItem(
                  value: 'esquadrao', child: Text('Configurar esquadrão')),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'template',
                  child: Text('Template estratégico (4 sub-grupos)')),
            ],
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
                    names: _typeNames,
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
                      names: _typeNames,
                      onTap: () => _openCharacter(_characters[i]),
                      onEdit: () => _editCharacter(_characters[i]),
                      onDelete: () => _deleteCharacter(_characters[i]),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCharacter,
        tooltip: 'Novo personagem',
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
  final UnitTypeNames names;
  final String? warning;

  const _SquadSummaryBar({
    required this.group,
    required this.typeCounts,
    required this.names,
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
            ? Colors.orange.withValues(alpha:0.12)
            : Theme.of(context).colorScheme.primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: warning != null
              ? Colors.orange.withValues(alpha:0.4)
              : Theme.of(context).colorScheme.primary.withValues(alpha:0.2),
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
                  emoji: names.emojiOf(CharacterType.heroi),
                  count: heroes,
                  max: group.maxHeroesPerSquad!,
                  exceeded: heroes > group.maxHeroesPerSquad!,
                ),
              if (group.maxCommandersPerSquad != null) ...[
                const SizedBox(width: 6),
                _TypeChip(
                  emoji: names.emojiOf(CharacterType.comandante),
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
            ? Colors.orange.withValues(alpha:0.2)
            : Colors.grey.withValues(alpha:0.15),
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
  final UnitTypeNames names;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.names,
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
              // Foto do personagem — sem foto, cai no emoji do tipo.
              GroupIcon(
                imagePath: character.iconImagePath,
                emoji: names.emojiOf(character.characterType),
                size: 44,
                emojiSize: 22,
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
                            color: tc.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            names.labelOf(character.characterType),
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
                          '${names.emojiOf(CharacterType.comandante)} '
                          'Não entra em batalha diretamente',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha:0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              ItemActionsMenu(
                itemName: character.name,
                onEdit: onEdit,
                onDelete: onDelete,
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

  /// Nomes dos tipos neste jogo (o seletor de tipo usa eles).
  final UnitTypeNames names;

  /// Status do modelo do grupo (efetivos) — escolhidos na CRIAÇÃO (todos
  /// marcados por padrão). Vazio/edição: a seção não aparece.
  final List<GroupStatTemplate> templates;

  /// Tipo já marcado ao criar (`suggestCharacterType`): quase nunca o dono
  /// precisa tocar no tipo.
  final CharacterType initialType;

  /// Nomes que já existem no grupo — repetido é bloqueado com aviso (o
  /// pacote JSON acha o personagem pelo nome). Na edição, sem o próprio.
  final List<String> takenNames;

  /// Criação: grava o personagem com os status marcados e devolve o salvo.
  /// A tela cuida do banco e da lista; o dialog decide se fecha ("Criar e
  /// abrir") ou continua aberto ("Criar outro").
  /// [templateIds] null = todos os do modelo.
  final Future<Character> Function(Character c, Set<int>? templateIds)?
      onCreate;

  const _CharacterDialog({
    required this.groupId,
    this.initial,
    this.names = UnitTypeNames.padrao,
    this.templates = const [],
    this.initialType = CharacterType.soldadoNormal,
    this.takenNames = const [],
    this.onCreate,
  });

  @override
  State<_CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<_CharacterDialog> {
  late TextEditingController _name;
  late TextEditingController _role;
  final FocusNode _nameFocus = FocusNode();
  late CharacterType _type;
  late Set<int> _selectedTemplateIds;
  late Set<String> _taken;

  String? _imagePath;
  bool _importing = false;
  bool _saving = false;
  String? _pickError;
  String? _nameError;
  String? _saveError;

  /// Nomes criados com "Criar outro" nesta abertura do dialog (feedback).
  final List<String> _criados = [];

  /// PNGs internos criados por ESTE dialog — os que não forem salvos são
  /// apagados no dispose (cancelar, fechar, trocar de foto).
  final List<String> _imported = [];

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _role = TextEditingController(text: widget.initial?.role ?? '');
    _type = widget.initial?.characterType ?? widget.initialType;
    _imagePath = widget.initial?.iconImagePath;
    // Todos marcados por padrão.
    _selectedTemplateIds =
        widget.templates.map((t) => t.id).whereType<int>().toSet();
    _taken = widget.takenNames.map((n) => n.trim().toLowerCase()).toSet();
  }

  @override
  void dispose() {
    for (final path in _imported) {
      IconImageStore.deleteIcon(path);
    }
    _name.dispose();
    _role.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// Mesmo cofre da foto de grupo: valida o tamanho ANTES de decodificar e
  /// grava um PNG novo, gerado pelo app, na pasta interna.
  Future<void> _pickImage() async {
    if (_importing) return;
    setState(() {
      _importing = true;
      _pickError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: IconImageStore.allowedExtensions,
      );
      final source = result?.files.single.path;
      if (source == null) return; // usuário cancelou
      final imported = await IconImageStore.importIcon(source);
      if (!mounted) {
        // Dialog fechou durante o import — apaga o PNG para não órfãozar.
        IconImageStore.deleteIcon(imported);
        return;
      }
      if (imported == null) {
        setState(() => _pickError =
            'Arquivo recusado — escolha uma imagem válida '
            '(png, jpg, webp, bmp ou gif, até 20 MB).');
        return;
      }
      setState(() {
        _imported.add(imported);
        _imagePath = imported;
      });
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Erro do nome (aparece no próprio campo) ou null se está ok.
  String? _validarNome() {
    final nome = _name.text.trim();
    if (nome.isEmpty) return 'Dê um nome ao personagem';
    // Editar sem trocar o nome sempre pode: grupos antigos (ou vindos de
    // backup) podem ter nomes repetidos, e isso não pode travar a edição.
    final original = widget.initial?.name.trim().toLowerCase();
    if (original != null && nome.toLowerCase() == original) return null;
    if (_taken.contains(nome.toLowerCase())) {
      return 'Já existe "$nome" neste grupo';
    }
    return null;
  }

  /// true se o nome passou; senão mostra o erro e devolve o foco ao campo.
  bool _nomeOk() {
    final erro = _validarNome();
    if (erro == null) return true;
    setState(() => _nameError = erro);
    _nameFocus.requestFocus();
    return false;
  }

  Character _montar() {
    final role = _role.text.trim();
    final base = widget.initial ??
        Character(groupId: widget.groupId, name: '', createdAt: DateTime.now());
    return base.copyWith(
      name: _name.text.trim(),
      role: role.isEmpty ? null : role,
      clearRole: role.isEmpty,
      characterType: _type,
      iconImagePath: _imagePath,
      clearIconImage: _imagePath == null,
    );
  }

  /// [abrir] true = "Criar e abrir" (fecha e a tela abre o novo);
  /// false = "Criar outro" (grava, avisa aqui dentro e limpa o nome).
  Future<void> _criar({required bool abrir}) async {
    // Durante o import de foto não cria: a foto chegaria no personagem errado.
    if (_saving || _importing || !_nomeOk()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final novo = _montar();
      // A foto que vai de fato no personagem — o _imagePath pode mudar
      // durante o await.
      final foto = novo.iconImagePath;
      final salvo = await widget.onCreate!(
          novo, widget.templates.isEmpty ? null : {..._selectedTemplateIds});
      // Foto gravada no personagem sai da lista de limpeza do dispose.
      if (foto != null) _imported.remove(foto);
      if (!mounted) return;
      if (abrir) {
        // Só fecha a SI MESMO (nunca a tela de baixo).
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.pop(context, salvo);
        }
        return;
      }
      setState(() {
        _criados.add(salvo.name);
        _taken.add(salvo.name.toLowerCase());
        _name.clear();
        _role.clear();
        _imagePath = null; // foto é de cada personagem; tipo e modelo ficam
      });
      _nameFocus.requestFocus();
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = 'Não foi possível salvar — tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _salvarEdicao() {
    if (_importing || !_nomeOk()) return;
    // Foto salva sai da lista de limpeza do dispose.
    if (_imagePath != null) _imported.remove(_imagePath);
    Navigator.pop(context, _montar());
  }

  /// Enter no nome = ação principal.
  void _acaoPrincipal() =>
      _isEdit ? _salvarEdicao() : _criar(abrir: true);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ocupado = _saving || _importing;
    // Enquanto grava, Esc/toque fora/Cancelar não fecham (senão o pop do fim
    // da gravação fecharia a tela de baixo, e a foto seria apagada).
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(_isEdit ? 'Editar personagem' : 'Novo personagem'),
        content: SizedBox(
          // Largura fixa (limitada pela tela): evita que as listas expansíveis
          // peçam "largura intrínseca" ao dialog.
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                    helperText: _isEdit ? null : 'Enter cria e abre',
                  ),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  onSubmitted: (_) => _acaoPrincipal(),
                ),
                if (_criados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _criados.length == 1
                                ? '"${_criados.last}" criado'
                                : '"${_criados.last}" criado · '
                                    '${_criados.length} nesta vez',
                            style: TextStyle(fontSize: 13, color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _rotulo('Tipo de unidade', Icons.category_outlined),
                const SizedBox(height: 8),
                Row(
                  children: CharacterType.values.map((t) {
                    final selected = _type == t;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OptionCard(
                          selected: selected,
                          semanticLabel: 'Tipo ${widget.names.labelOf(t)}',
                          onTap: () => setState(() => _type = t),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.names.emojiOf(t),
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(widget.names.labelOf(t),
                                  style: TextStyle(
                                    fontSize: 12,
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
                    '${widget.names.emojiOf(CharacterType.comandante)} '
                    '${widget.names.labelOf(CharacterType.comandante)} não entra '
                    'em batalha diretamente, mas pode ser monitorado e ter notas.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
                // Status do modelo — só na criação. Recolhido numa linha de
                // resumo: o normal é querer todos.
                if (!_isEdit && widget.templates.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _modeloDoGrupo(cs),
                ],
                _maisOpcoes(cs),
                if (_saveError != null)
                  Text(_saveError!,
                      style: TextStyle(color: cs.error, fontSize: 13)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          if (_isEdit)
            FilledButton.icon(
              onPressed: ocupado ? null : _salvarEdicao,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: ocupado ? null : () => _criar(abrir: false),
              icon: const Icon(Icons.add),
              label: const Text('Criar outro'),
            ),
            FilledButton.icon(
              onPressed: ocupado ? null : () => _criar(abrir: true),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Criar e abrir'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rotulo(String texto, IconData icone) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(children: [
      Icon(icone, size: 16, color: cor),
      const SizedBox(width: 6),
      Text(texto,
          style: TextStyle(
              fontSize: 13, color: cor, fontWeight: FontWeight.w600)),
    ]);
  }

  /// "✓ N de M status do modelo" — abre a lista com Todos/Nenhum.
  Widget _modeloDoGrupo(ColorScheme cs) {
    final ids = widget.templates.map((t) => t.id).whereType<int>().toSet();
    final marcados = _selectedTemplateIds.length;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.checklist),
      title: const Text('Status do modelo'),
      subtitle: Text('✓ $marcados de ${ids.length} vão para o personagem'),
      children: [
        // Wrap: com fonte grande, os dois botões descem de linha em vez de
        // estourar a largura do dialog.
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () =>
                  setState(() => _selectedTemplateIds = {...ids}),
              icon: const Icon(Icons.done_all),
              label: const Text('Todos'),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _selectedTemplateIds = {}),
              icon: const Icon(Icons.remove_done),
              label: const Text('Nenhum'),
            ),
          ],
        ),
        ...widget.templates.map((t) {
          final id = t.id;
          if (id == null) return const SizedBox.shrink();
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            // O subtítulo já fala o tipo; o selo é só visual aqui.
            secondary:
                ExcludeSemantics(child: StatTypeBadge(t.type, size: 26)),
            title: Text(t.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(t.type.label),
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
    );
  }

  /// Função/classe e foto: opcionais, recolhidos (abertos na edição se já
  /// tiverem algo).
  Widget _maisOpcoes(ColorScheme cs) {
    final temAlgo = _role.text.trim().isNotEmpty || _imagePath != null;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      initiallyExpanded: _isEdit && temAlgo,
      leading: const Icon(Icons.tune),
      title: const Text('Mais opções'),
      subtitle: const Text('Função/classe e foto'),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        TextField(
          controller: _role,
          decoration: const InputDecoration(
              labelText: 'Função/Classe (opcional)',
              hintText: 'ex.: Tank, DPS, Support',
              prefixIcon: Icon(Icons.work_outline),
              border: OutlineInputBorder()),
          onSubmitted: (_) => _acaoPrincipal(),
        ),
        const SizedBox(height: 12),
        // Foto do personagem (opcional) — vira PNG interno do app.
        Row(
          children: [
            GroupIcon(
                imagePath: _imagePath,
                emoji: widget.names.emojiOf(_type),
                size: 44,
                emojiSize: 26),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importing ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(_imagePath == null ? 'Usar foto' : 'Trocar foto'),
              ),
            ),
            if (_imagePath != null)
              IconButton(
                tooltip: 'Remover foto (voltar ao emoji)',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _imagePath = null),
              ),
          ],
        ),
        if (_pickError != null) ...[
          const SizedBox(height: 8),
          Text(_pickError!, style: TextStyle(color: cs.error, fontSize: 12)),
        ],
      ],
    );
  }
}

// ─── Dialog: nomes dos tipos de unidade (por jogo) ───────────────────────────

/// Renomeia os 3 tipos de unidade SEM tocar em código: cada jogo chama do seu
/// jeito ("Herói" → "Comandante" no RoK, "Governante", "Oficial"…).
/// Por dentro nada muda — nenhum personagem é migrado.
class _TypeNamesDialog extends StatefulWidget {
  final int groupId;
  final UnitTypeNames names;
  const _TypeNamesDialog({required this.groupId, required this.names});

  @override
  State<_TypeNamesDialog> createState() => _TypeNamesDialogState();
}

class _TypeNamesDialogState extends State<_TypeNamesDialog> {
  final _labels = <CharacterType, TextEditingController>{};
  final _emojis = <CharacterType, TextEditingController>{};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    for (final t in CharacterType.values) {
      _labels[t] = TextEditingController(text: widget.names.labelOf(t));
      _emojis[t] = TextEditingController(text: widget.names.emojiOf(t));
    }
  }

  @override
  void dispose() {
    for (final c in _labels.values) {
      c.dispose();
    }
    for (final c in _emojis.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final repo = TrackerRepository.instance;
    for (final t in CharacterType.values) {
      final nome = _labels[t]!.text.trim();
      final emoji = _emojis[t]!.text.trim();
      // Voltou a ser igual ao padrão do app → apaga o registro em vez de
      // guardar uma cópia do padrão (menos lixo, e o padrão volta a valer se
      // o app mudar).
      final ehPadrao = (nome.isEmpty || nome == t.label) &&
          (emoji.isEmpty || emoji == t.emoji);
      if (ehPadrao) {
        await repo.deleteTypeLabel(widget.groupId, t.dbValue);
      } else {
        await repo.upsertTypeLabel(UnitTypeLabel(
          groupId: widget.groupId,
          typeKey: t.dbValue,
          label: nome.isEmpty ? t.label : nome,
          emoji: emoji.isEmpty ? t.emoji : emoji,
        ));
      }
    }
    if (mounted) Navigator.pop(context, true);
  }

  void _restaurar() {
    setState(() {
      for (final t in CharacterType.values) {
        _labels[t]!.text = t.label;
        _emojis[t]!.text = t.emoji;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nomes dos tipos de unidade'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cada jogo chama do seu jeito. No Rise of Kingdoms, por exemplo, '
              '"Herói" é "Comandante". Vale para este jogo e os sub-grupos '
              'dele — os personagens não mudam.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            for (final t in CharacterType.values) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: TextField(
                      controller: _emojis[t],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          labelText: 'Ícone', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _labels[t],
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        helperText: 'padrão: ${t.emoji} ${t.label}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _salvando ? null : _restaurar,
            child: const Text('Restaurar padrão')),
        TextButton(
            onPressed: _salvando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
            onPressed: _salvando ? null : _salvar,
            child: const Text('Salvar')),
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
  String? _nameError;
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

  /// Ação principal (botão e Enter no nome). Nome vazio → aviso no campo.
  void _salvar() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _nameError = 'Dê um nome ao sub-grupo');
      return;
    }
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
                return OptionCard(
                  selected: selected,
                  semanticLabel: 'Categoria ${cat.label}',
                  onTap: () => _onCategoryChanged(cat),
                  child: Text(
                    '${cat.emoji} ${cat.label}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: 'Nome do sub-grupo',
                  border: const OutlineInputBorder(),
                  errorText: _nameError),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _salvar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.check),
          label: const Text('Criar'),
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
