import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../models/character.dart';
import '../repositories/tracker_repository.dart';
import 'character_screen.dart';
import 'skill_tree_screen.dart';
import 'widgets/star_rank_display.dart';

class GameScreen extends StatefulWidget {
  final GameGroup group;
  const GameScreen({super.key, required this.group});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Character> _characters = [];
  List<GameGroup> _subGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chars = await TrackerRepository.instance
        .getCharactersByGroup(widget.group.id!);
    final subs = await TrackerRepository.instance
        .getSubGroups(widget.group.id!);
    if (mounted)
      setState(() { _characters = chars; _subGroups = subs; _loading = false; });
  }

  Future<void> _addSubGroup() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SimpleNameDialog(
          title: 'Novo Sub-grupo',
          hint: 'ex.: Tropas, Heróis, Bosses'),
    );
    if (result != null && result.isNotEmpty) {
      final sg = await TrackerRepository.instance.insertGroup(
        GameGroup(
          parentId: widget.group.id,
          name: result,
          iconEmoji: '📁',
          createdAt: DateTime.now(),
        ),
      );
      setState(() => _subGroups.add(sg));
    }
  }

  Future<void> _addCharacter() async {
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => _CharacterDialog(groupId: widget.group.id!),
    );
    if (result != null) {
      final saved =
          await TrackerRepository.instance.insertCharacter(result);
      setState(() => _characters.add(saved));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.group.iconEmoji ?? '⚔️'} ${widget.group.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SkillTreeScreen(group: widget.group),
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Sub-grupos
                if (_subGroups.isNotEmpty) ...[
                  Text('Sub-grupos',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ..._subGroups.map((sg) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(sg.iconEmoji ?? '📁',
                              style: const TextStyle(fontSize: 24)),
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
                  _EmptyState(onAdd: _addCharacter)
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

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(character.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        if (character.role != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(character.role!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    StarRankDisplay(
                      rank: character.starRank,
                      starSize: 18,
                      showSubLevelText: false,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: Colors.red.shade300,
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
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
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

// ─── Dialog para criar personagem ────────────────────────────────────────────

class _CharacterDialog extends StatefulWidget {
  final int groupId;
  const _CharacterDialog({required this.groupId});

  @override
  State<_CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<_CharacterDialog> {
  late TextEditingController _name;
  late TextEditingController _role;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _role = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Personagem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Nome', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _role,
            decoration: const InputDecoration(
                labelText: 'Função/Classe (opcional)',
                hintText: 'ex.: Tank, DPS, Support',
                border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Character(
                groupId: widget.groupId,
                name: _name.text.trim(),
                role: _role.text.trim().isEmpty ? null : _role.text.trim(),
                createdAt: DateTime.now(),
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
