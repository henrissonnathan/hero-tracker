import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../models/skill_node.dart';
import '../repositories/tracker_repository.dart';
import '../theme/app_theme.dart';
import 'widgets/item_actions.dart';
import 'widgets/option_card.dart';

/// Tela da árvore de habilidades de um grupo.
///
/// Exibe os nós em estrutura hierárquica:
/// raiz → filhos → netos, com linhas de conexão.
/// Nós com parentId desbloqueado podem ser ativados.
class SkillTreeScreen extends StatefulWidget {
  final GameGroup group;
  const SkillTreeScreen({super.key, required this.group});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  List<SkillNode> _nodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nodes =
        await TrackerRepository.instance.getSkillNodes(widget.group.id!);
    if (mounted) setState(() { _nodes = nodes; _loading = false; });
  }

  Future<void> _addNode({int? parentId}) async {
    final parent = parentId != null
        ? _nodes.firstWhere((n) => n.id == parentId)
        : null;
    final result = await showDialog<SkillNode>(
      context: context,
      builder: (_) => _SkillNodeDialog(
        groupId: widget.group.id!,
        parentId: parentId,
        parentName: parent?.name,
      ),
    );
    if (result != null) {
      final saved = await TrackerRepository.instance
          .insertSkillNode(result.copyWith(sortOrder: _nodes.length));
      setState(() => _nodes.add(saved));
    }
  }

  Future<void> _toggleUnlock(SkillNode node) async {
    // Verifica se o pai está desbloqueado (ou é raiz)
    if (!node.isUnlocked && node.parentId != null) {
      final parent = _nodes.firstWhere(
        (n) => n.id == node.parentId,
        orElse: () => node,
      );
      if (!parent.isUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Desbloqueie "${parent.name}" primeiro!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    final updated = node.copyWith(isUnlocked: !node.isUnlocked);
    await TrackerRepository.instance.updateSkillNode(updated);
    setState(() {
      final i = _nodes.indexWhere((n) => n.id == node.id);
      if (i >= 0) _nodes[i] = updated;
    });
  }

  Future<void> _deleteNode(SkillNode node) async {
    final ok = await confirmDelete(context,
        itemName: node.name,
        detalhe: 'As sub-habilidades dela ficam soltas, no primeiro nível.');
    if (ok) {
      await TrackerRepository.instance.deleteSkillNode(node.id!);
      // As sub-habilidades viram raiz no banco (FK SET NULL) — recarregar
      // faz a tela mostrar isso, em vez de sumir com elas até reabrir.
      await _load();
    }
  }

  /// Retorna os filhos diretos de [parentId] (null = raízes).
  List<SkillNode> _childrenOf(int? parentId) => _nodes
      .where((n) => n.parentId == parentId)
      .toList();

  @override
  Widget build(BuildContext context) {
    final roots = _childrenOf(null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Árvore — ${widget.group.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNode(),
            tooltip: 'Adicionar habilidade raiz',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : roots.isEmpty
              ? _EmptyState(onAdd: () => _addNode())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: roots
                        .map((r) => _NodeTree(
                              node: r,
                              allNodes: _nodes,
                              onAddChild: (id) => _addNode(parentId: id),
                              onToggle: _toggleUnlock,
                              onDelete: _deleteNode,
                              depth: 0,
                            ))
                        .toList(),
                  ),
                ),
    );
  }
}

// ─── Widget de nó com seus filhos recursivos ──────────────────────────────────

class _NodeTree extends StatelessWidget {
  final SkillNode node;
  final List<SkillNode> allNodes;
  final void Function(int) onAddChild;
  final void Function(SkillNode) onToggle;
  final void Function(SkillNode) onDelete;
  final int depth;

  const _NodeTree({
    required this.node,
    required this.allNodes,
    required this.onAddChild,
    required this.onToggle,
    required this.onDelete,
    required this.depth,
  });

  List<SkillNode> get _children =>
      allNodes.where((n) => n.parentId == node.id).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (depth > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Container(
                    width: 2,
                    height: 12,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          _NodeCard(
            node: node,
            onAddChild: () => onAddChild(node.id!),
            onToggle: () => onToggle(node),
            onDelete: () => onDelete(node),
          ),
          ..._children.map((child) => _NodeTree(
                node: child,
                allNodes: allNodes,
                onAddChild: onAddChild,
                onToggle: onToggle,
                onDelete: onDelete,
                depth: depth + 1,
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final SkillNode node;
  final VoidCallback onAddChild;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NodeCard({
    required this.node,
    required this.onAddChild,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = node.isUnlocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: unlocked
          ? AppTheme.gold.withValues(alpha:0.12)
          : Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: unlocked
              ? AppTheme.gold.withValues(alpha:0.5)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Semantics(
              container: true,
              button: true,
              toggled: unlocked,
              label: unlocked ? 'Desbloqueada' : 'Bloqueada',
              onTap: onToggle,
              excludeSemantics: true,
              child: Tooltip(
                message: unlocked ? 'Bloquear' : 'Desbloquear',
                child: InkResponse(
                  onTap: onToggle,
                  radius: 24,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: unlocked
                              ? AppTheme.gold.withValues(alpha: 0.25)
                              : Colors.grey.withValues(alpha: 0.15),
                          border: Border.all(
                            color: unlocked
                                ? AppTheme.gold
                                : Colors.grey.shade600,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(node.iconEmoji,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: unlocked ? AppTheme.goldLight : null,
                    ),
                  ),
                  if (node.description != null)
                    Text(
                      node.description!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400),
                    ),
                  if (node.costPoints > 1)
                    Text(
                      '${node.costPoints} pontos',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.gold.withValues(alpha:0.7)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: onAddChild,
              tooltip: 'Adicionar sub-habilidade',
              color: Colors.grey.shade500,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Apagar "${node.name}"',
              onPressed: onDelete,
              color: Colors.red.shade300,
            ),
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
          const Text('🔷', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Nenhuma habilidade ainda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Primeira Habilidade'),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog de nó ────────────────────────────────────────────────────────────

class _SkillNodeDialog extends StatefulWidget {
  final int groupId;
  final int? parentId;
  final String? parentName;

  const _SkillNodeDialog({
    required this.groupId,
    this.parentId,
    this.parentName,
  });

  @override
  State<_SkillNodeDialog> createState() => _SkillNodeDialogState();
}

class _SkillNodeDialogState extends State<_SkillNodeDialog> {
  late TextEditingController _name;
  String? _nameError;
  late TextEditingController _desc;
  late TextEditingController _cost;
  String _emoji = '🔷';

  final _emojis = [
    '🔷', '⚔️', '🛡️', '🔥', '💧', '⚡', '🌿', '💀',
    '✨', '🏹', '🪄', '🎯', '🔮', '💪', '🧠', '❤️',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _desc = TextEditingController();
    _cost = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _cost.dispose();
    super.dispose();
  }

  /// Ação principal (botão e Enter no nome). Nome vazio → aviso no campo.
  void _salvar() {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Dê um nome à habilidade');
      return;
    }
    Navigator.pop(
      context,
      SkillNode(
        groupId: widget.groupId,
        parentId: widget.parentId,
        name: _name.text.trim(),
        description: _desc.text.trim().isEmpty
            ? null
            : _desc.text.trim(),
        iconEmoji: _emoji,
        costPoints: int.tryParse(_cost.text) ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parentId == null
          ? 'Nova Habilidade'
          : 'Sub-habilidade de "${widget.parentName}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojis
                  .map((e) => EmojiChoice(
                        emoji: e,
                        selected: e == _emoji,
                        fontSize: 20,
                        onTap: () => setState(() => _emoji = e),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: 'Nome',
                  border: const OutlineInputBorder(),
                  errorText: _nameError),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(
                  labelText: 'Custo em pontos',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
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
