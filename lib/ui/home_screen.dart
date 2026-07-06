import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../repositories/tracker_repository.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GameGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await TrackerRepository.instance.getRootGroups();
    if (mounted) setState(() { _groups = groups; _loading = false; });
  }

  Future<void> _addGroup() async {
    final result = await showDialog<GameGroup>(
      context: context,
      builder: (_) => const _GroupDialog(),
    );
    if (result != null) {
      final saved = await TrackerRepository.instance.insertGroup(result);
      setState(() => _groups.add(saved));
    }
  }

  Future<void> _editGroup(GameGroup group) async {
    final result = await showDialog<GameGroup>(
      context: context,
      builder: (_) => _GroupDialog(initial: group),
    );
    if (result != null) {
      await TrackerRepository.instance.updateGroup(result);
      setState(() {
        final i = _groups.indexWhere((g) => g.id == result.id);
        if (i >= 0) _groups[i] = result;
      });
    }
  }

  Future<void> _deleteGroup(GameGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar grupo'),
        content: Text('Deletar "${group.name}" e todos os personagens?'),
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
      await TrackerRepository.instance.deleteGroup(group.id!);
      setState(() => _groups.removeWhere((g) => g.id == group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGroup,
            tooltip: 'Novo grupo',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _EmptyState(onAdd: _addGroup)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _groups.length,
                  itemBuilder: (ctx, i) => _GroupCard(
                    group: _groups[i],
                    onTap: () async {
                      await Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(group: _groups[i]),
                        ),
                      );
                      _load();
                    },
                    onEdit: () => _editGroup(_groups[i]),
                    onDelete: () => _deleteGroup(_groups[i]),
                  ),
                ),
      floatingActionButton: _groups.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addGroup,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GameGroup group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(group.iconEmoji ?? '⚔️',
            style: const TextStyle(fontSize: 32)),
        title: Text(group.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: group.description != null
            ? Text(group.description!,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
            : null,
        onTap: onTap,
        trailing: PopupMenuButton<String>(
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
          const Text('⚔️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Nenhum grupo ainda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Crie um grupo para começar a rastrear seus heróis.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Novo Grupo'),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog para criar/editar grupo ──────────────────────────────────────────

class _GroupDialog extends StatefulWidget {
  final GameGroup? initial;
  const _GroupDialog({this.initial});

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late TextEditingController _name;
  late TextEditingController _desc;
  String _emoji = '⚔️';

  final _emojis = ['⚔️', '🛡️', '🏰', '🐉', '🧙', '🗡️', '🪄', '🎲', '🏹', '⚡'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _desc = TextEditingController(text: widget.initial?.description ?? '');
    _emoji = widget.initial?.iconEmoji ?? '⚔️';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.initial == null ? 'Novo Grupo' : 'Editar Grupo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: _emojis
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: e == _emoji
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nome do grupo', border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder()),
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
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              (widget.initial ?? GameGroup(
                          name: '', createdAt: DateTime.now()))
                      .copyWith(
                name: _name.text.trim(),
                description: _desc.text.trim().isEmpty
                    ? null
                    : _desc.text.trim(),
                iconEmoji: _emoji,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
