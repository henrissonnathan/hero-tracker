import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/character_stat.dart';
import '../models/character_type.dart';
import '../models/star_rank.dart';
import '../repositories/tracker_repository.dart';
import '../theme/app_theme.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    _load();
  }

  Future<void> _load() async {
    final stats = await TrackerRepository.instance
        .getStatsByCharacter(_character.id!);
    if (mounted) setState(() { _stats = stats; _loading = false; });
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

  Future<void> _addStat() async {
    final result = await showDialog<StatFormResult>(
      context: context,
      builder: (_) => const StatFormDialog(title: 'Novo Status'),
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
        initial: StatFormResult(
          name: stat.name,
          type: stat.type,
          value: stat.value,
          maxValue: stat.maxValue,
          triggerText: stat.triggerText,
          formulaText: stat.formulaText,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_character.name),
        actions: [
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
                  onStarChanged: _updateStarRank,
                  onLevelChanged: _updateLevel,
                )),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final stat = _stats[i];
                      return StatTile(
                        stat: stat,
                        onEdit: () => _editStat(stat),
                        onDelete: () => _deleteStat(stat),
                      );
                    },
                    childCount: _stats.length,
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
  final void Function(StarRank) onStarChanged;
  final void Function(int delta) onLevelChanged;

  const _HeaderCard({
    required this.character,
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
            AppTheme.gold.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                        Text(character.characterType.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(character.characterType.label,
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

