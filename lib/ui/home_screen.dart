import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/game_group.dart';
import '../repositories/tracker_repository.dart';
import '../services/export_service.dart';
import '../services/icon_image_store.dart';
import '../services/seed_service.dart';
import 'game_screen.dart';
import 'tests_info_screen.dart';
import 'widgets/group_icon.dart';

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
    _sweepOrphanIcons();
  }

  /// Uma vez por sessão: apaga PNGs internos que ninguém usa (sobras de
  /// crash/fechamento no meio de um import). Roda no boot, antes de qualquer
  /// dialog existir. A lista precisa vir de getAllIconImagePathsInUse() —
  /// grupos E personagens dividem a mesma pasta.
  Future<void> _sweepOrphanIcons() async {
    final used = await TrackerRepository.instance.getAllIconImagePathsInUse();
    await IconImageStore.cleanupOrphans(used);
  }

  Future<void> _load() async {
    final groups = await TrackerRepository.instance.getRootGroups();
    if (mounted) setState(() { _groups = groups; _loading = false; });
  }

  // Backup pela tela (Fase 2): exportar/importar em 2 toques.
  Future<void> _exportData() async {
    String msg;
    try {
      msg = await ExportService.instance.exportAll();
    } catch (_) {
      msg = 'Não foi possível salvar o backup (verifique permissão/espaço).';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _importData() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Escolher backup do Hero Tracker',
    );
    final path = picked?.files.single.path;
    if (path == null) return; // cancelou
    final result = await ExportService.instance.importFromFile(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) _load();
  }

  // Simula um usuário: monta o mapa de exemplo do Rise of Kingdoms (4
  // sub-grupos) para analisar o app sem digitar nada. Aditivo e reversível.
  Future<void> _loadExample() async {
    final jaExiste = await SeedService.instance.exampleExists();
    if (!mounted) return;
    if (jaExiste) {
      // Refazer APAGA o exemplo atual — inclusive edições feitas nele.
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Refazer o exemplo'),
          content: const Text(
              'O exemplo já existe. Refazer APAGA o grupo de exemplo atual e '
              'tudo dentro dele (inclusive alterações que você tenha feito '
              'nele) e monta a versão mais nova.\n\n'
              'Seus outros grupos não são tocados.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Refazer',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (ok != true) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montando o mapa de exemplo...')));
    try {
      if (jaExiste) await SeedService.instance.removeExample();
      await SeedService.instance.createExample();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível criar o exemplo.')));
      return;
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pronto! Abra "${SeedService.exampleGroupName}" '
            '— tem 4 sub-grupos dentro.')));
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
      // Foto antiga substituída/removida → apaga o PNG interno órfão.
      final oldIcon = group.iconImagePath;
      if (oldIcon != null && oldIcon != result.iconImagePath) {
        IconImageStore.deleteIcon(oldIcon);
      }
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
      IconImageStore.deleteIcon(group.iconImagePath);
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
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (v) {
              if (v == 'example') _loadExample();
              if (v == 'export') _exportData();
              if (v == 'import') _importData();
              if (v == 'tests') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TestsInfoScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'example',
                  child: Text('Carregar exemplo (dados de teste)')),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'export', child: Text('Exportar dados (backup)')),
              PopupMenuItem(
                  value: 'import', child: Text('Importar dados')),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'tests',
                  child: Text('Testes do app (o que já é testado)')),
            ],
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
        leading: GroupIcon(
            imagePath: group.iconImagePath,
            emoji: group.iconEmoji,
            size: 32),
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
  String? _imagePath;
  bool _importing = false;
  String? _pickError;

  /// PNGs internos criados por ESTE dialog — os que não forem salvos
  /// são apagados no dispose (cancelar, fechar, trocar de foto).
  final List<String> _imported = [];

  final _emojis = ['⚔️', '🛡️', '🏰', '🐉', '🧙', '🗡️', '🪄', '🎲', '🏹', '⚡'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _desc = TextEditingController(text: widget.initial?.description ?? '');
    _emoji = widget.initial?.iconEmoji ?? '⚔️';
    _imagePath = widget.initial?.iconImagePath;
  }

  @override
  void dispose() {
    for (final path in _imported) {
      IconImageStore.deleteIcon(path);
    }
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

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
                        // escolher emoji desmarca a foto
                        onTap: () => setState(() {
                          _emoji = e;
                          _imagePath = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                // com foto ativa, nenhum emoji parece escolhido
                                color: e == _emoji && _imagePath == null
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
            Row(
              children: [
                GroupIcon(imagePath: _imagePath, emoji: _emoji, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importing ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                        _imagePath == null ? 'Usar foto' : 'Trocar foto'),
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
              Text(_pickError!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12)),
            ],
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
            // Foto salva sai da lista de limpeza do dispose.
            if (_imagePath != null) _imported.remove(_imagePath);
            Navigator.pop(
              context,
              (widget.initial ?? GameGroup(
                          name: '', createdAt: DateTime.now()))
                      .copyWith(
                name: _name.text.trim(),
                description: _desc.text.trim().isEmpty
                    ? null
                    : _desc.text.trim(),
                clearDescription: _desc.text.trim().isEmpty,
                iconEmoji: _emoji,
                iconImagePath: _imagePath,
                clearIconImage: _imagePath == null,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
