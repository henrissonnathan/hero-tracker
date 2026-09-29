import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/game_group.dart';
import '../models/group_stat_template.dart';
import '../models/stat_type.dart';
import '../repositories/tracker_repository.dart';
import '../services/export_service.dart';
import 'widgets/item_actions.dart';
import 'widgets/stat_form_dialog.dart';
import 'widgets/stat_type_visual.dart';

/// Rótulo da seção para templates sem categoria.
const _semCategoria = 'Sem categoria';

/// Tela exclusiva das estatísticas do jogo: cria/edita os templates de status
/// e os organiza em categorias/sub-grupos (Recursos, Status base, Bônus...).
///
/// Os templates são a "base": todo personagem novo do grupo nasce com eles.
/// A categoria só organiza a exibição — não afeta a cópia para o personagem.
class StatsScreen extends StatefulWidget {
  final GameGroup group;
  const StatsScreen({super.key, required this.group});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<GroupStatTemplate> _templates = [];
  List<GroupStatTemplate> _inherited = [];
  // Categorias criadas pelo usuário que ainda não têm nenhum status.
  // (Categorias que já têm status persistem sozinhas via template.category.)
  final Set<String> _extraCategories = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = TrackerRepository.instance;
    final templates = await repo.getTemplatesByGroup(widget.group.id!);
    // Sub-grupo sem templates próprios herda os do ancestral (read-only aqui).
    final inherited = templates.isEmpty && widget.group.parentId != null
        ? await repo.getEffectiveTemplates(widget.group.id!)
        : <GroupStatTemplate>[];
    if (mounted) {
      setState(() {
        _templates = templates;
        _inherited = inherited;
        _loading = false;
      });
    }
  }

  /// Categorias distintas já usadas (para atalhos no dialog), ordenadas.
  List<String> get _categoryNames {
    final set = <String>{};
    for (final t in _templates) {
      final c = (t.category ?? '').trim();
      if (c.isNotEmpty) set.add(c);
    }
    set.addAll(_extraCategories);
    final list = set.toList()..sort();
    return list;
  }

  /// Nomes que a fórmula pode usar (os próprios, ou os herdados).
  List<String> get _statNames =>
      (_templates.isNotEmpty ? _templates : _inherited)
          .map((t) => t.name)
          .toList();

  /// Gatilhos já escritos neste modelo — reusar é um toque no formulário.
  List<String> get _triggers => _templates
      .where((t) => t.type == StatType.trigger)
      .map((t) => t.triggerText ?? '')
      .toList();

  String _catKey(GroupStatTemplate t) {
    final c = (t.category ?? '').trim();
    return c.isEmpty ? _semCategoria : c;
  }

  /// Templates agrupados por categoria, categorias em ordem alfabética e
  /// "Sem categoria" sempre por último.
  List<MapEntry<String, List<GroupStatTemplate>>> get _sections {
    final map = <String, List<GroupStatTemplate>>{};
    for (final t in _templates) {
      (map[_catKey(t)] ??= []).add(t);
    }
    // Categorias criadas vazias aparecem como seções sem status ainda.
    for (final c in _extraCategories) {
      map.putIfAbsent(c, () => []);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == _semCategoria) return 1;
        if (b == _semCategoria) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return keys.map((k) => MapEntry(k, map[k]!)).toList();
  }

  Future<void> _add({String? presetCategory}) async {
    final result = await showDialog<StatFormResult>(
      context: context,
      builder: (_) => StatFormDialog(
        title: 'Novo Status do Jogo',
        valueLabel: 'Valor padrão',
        showCategory: true,
        categories: _categoryNames,
        availableStatNames: _statNames,
        knownTriggers: _triggers,
        initialCategory: presetCategory,
        validateName: (name) => _templates
                .any((t) => t.name.toLowerCase() == name.toLowerCase())
            ? 'Já existe um status "$name" neste grupo'
            : null,
      ),
    );
    if (result == null) return;
    final saved = await TrackerRepository.instance.insertTemplate(
      GroupStatTemplate(
        groupId: widget.group.id!,
        name: result.name,
        type: result.type,
        defaultValue: result.value,
        maxValue: result.maxValue,
        triggerText: result.triggerText,
        formulaText: result.formulaText,
        category: result.category,
        // .last.sortOrder+1 evita colisão após deletar-e-adicionar.
        sortOrder: _templates.isEmpty ? 0 : _templates.last.sortOrder + 1,
      ),
    );
    setState(() => _templates.add(saved));
  }

  /// Recebe um pacote JSON e preenche ESTE jogo: status do modelo e
  /// personagens que ainda não existem. Nada que já existe é sobrescrito.
  Future<void> _importPack() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Escolher pacote (modelo + personagens)',
    );
    final path = picked?.files.single.path;
    if (path == null) return; // cancelou
    final r =
        await ExportService.instance.importGroupPack(path, widget.group.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(r.message)));
    if (r.success) _load();
  }

  Future<void> _exportPack() async {
    String msg;
    try {
      msg = await ExportService.instance.exportGroupPack(widget.group);
    } catch (_) {
      msg = 'Não foi possível salvar o pacote (verifique permissão/espaço).';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Cria uma categoria/sub-grupo vazia (o usuário adiciona os status depois).
  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova categoria / sub-grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria',
            hintText: 'ex.: Recursos, Status base, Bônus...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Criar')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    // Já existe (ignorando maiúsc/minúsc)? a seção já aparece; não duplica.
    final existe =
        _categoryNames.any((c) => c.toLowerCase() == name.toLowerCase());
    if (!existe) setState(() => _extraCategories.add(name));
  }

  Future<void> _edit(GroupStatTemplate template) async {
    final result = await showDialog<StatFormResult>(
      context: context,
      builder: (_) => StatFormDialog(
        title: 'Editar Status do Jogo',
        valueLabel: 'Valor padrão',
        showCategory: true,
        categories: _categoryNames,
        availableStatNames: _statNames,
        knownTriggers: _triggers,
        initial: StatFormResult(
          name: template.name,
          type: template.type,
          value: template.defaultValue,
          maxValue: template.maxValue,
          triggerText: template.triggerText,
          formulaText: template.formulaText,
          category: template.category,
        ),
        validateName: (name) => _templates.any((t) =>
                t.id != template.id &&
                t.name.toLowerCase() == name.toLowerCase())
            ? 'Já existe um status "$name" neste grupo'
            : null,
      ),
    );
    if (result == null) return;
    // Construção direta (não copyWith): garante que category volte a null se
    // o usuário limpar o campo.
    final updated = GroupStatTemplate(
      id: template.id,
      groupId: template.groupId,
      name: result.name,
      type: result.type,
      defaultValue: result.value,
      maxValue: result.maxValue,
      triggerText: result.triggerText,
      formulaText: result.formulaText,
      category: result.category,
      sortOrder: template.sortOrder,
    );
    await TrackerRepository.instance.updateTemplate(updated);
    setState(() {
      final i = _templates.indexWhere((t) => t.id == template.id);
      if (i >= 0) _templates[i] = updated;
    });
  }

  Future<void> _delete(GroupStatTemplate template) async {
    final ok = await confirmDelete(context,
        itemName: template.name,
        detalhe:
            'Personagens já criados mantêm seus status (é uma cópia).');
    if (ok) {
      await TrackerRepository.instance.deleteTemplate(template.id!);
      setState(() => _templates.removeWhere((t) => t.id == template.id));
    }
  }

  /// Renomeia uma categoria (ou joga tudo para "Sem categoria" com nome vazio),
  /// atualizando todos os templates dela.
  Future<void> _renameCategory(String current) async {
    final controller = TextEditingController(
        text: current == _semCategoria ? '' : current);
    final novo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renomear categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria (vazio = Sem categoria)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (novo == null) return; // cancelou
    final target = novo.isEmpty ? null : novo;
    final affected =
        _templates.where((t) => _catKey(t) == current).toList();
    // Construção direta (não copyWith): garante a troca da categoria inclusive
    // para null (copyWith preservaria a antiga quando target==null).
    for (final t in affected) {
      await TrackerRepository.instance.updateTemplate(GroupStatTemplate(
        id: t.id,
        groupId: t.groupId,
        name: t.name,
        type: t.type,
        defaultValue: t.defaultValue,
        maxValue: t.maxValue,
        triggerText: t.triggerText,
        formulaText: t.formulaText,
        category: target,
        sortOrder: t.sortOrder,
      ));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas — ${widget.group.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Nova categoria / sub-grupo',
            onPressed: _addCategory,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.import_export),
            tooltip: 'Pacote JSON (modelo + personagens)',
            onSelected: (v) {
              if (v == 'importar') _importPack();
              if (v == 'exportar') _exportPack();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'importar',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Receber pacote'),
                  subtitle: Text('modelo + personagens de um arquivo'),
                ),
              ),
              PopupMenuItem(
                value: 'exportar',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Enviar pacote deste jogo'),
                  subtitle: Text('salva um arquivo .json'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_templates.isEmpty && _extraCategories.isEmpty)
              ? _emptyBody()
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final section in _sections)
                      _CategorySection(
                        title: section.key,
                        templates: section.value,
                        onRename: () => _renameCategory(section.key),
                        onAddHere: section.key == _semCategoria
                            ? null
                            : () => _add(presetCategory: section.key),
                        onEdit: _edit,
                        onDelete: _delete,
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(),
        icon: const Icon(Icons.add_chart),
        label: const Text('Novo status'),
      ),
    );
  }

  Widget _emptyBody() {
    if (_inherited.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Este grupo herda os status do grupo pai — personagens novos nascem com eles. Crie um status aqui para o grupo passar a ter os seus próprios.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._inherited.map((t) => ListTile(
                dense: true,
                leading: StatTypeBadge(t.type, size: 26),
                title: Text(t.name,
                    style: TextStyle(color: Colors.grey.shade400)),
                subtitle: Text('${t.type.label} · herdado do grupo pai'),
                trailing: Icon(Icons.link,
                    size: 18, color: Colors.grey.shade500),
              )),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('Nenhum status ainda',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Crie os status do jogo (Vida, Defesa, Ouro...) e organize em categorias. Todo personagem novo do grupo nasce com eles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma seção (categoria) com seus templates.
class _CategorySection extends StatelessWidget {
  final String title;
  final List<GroupStatTemplate> templates;
  final VoidCallback onRename;
  final VoidCallback? onAddHere;
  final void Function(GroupStatTemplate) onEdit;
  final void Function(GroupStatTemplate) onDelete;

  const _CategorySection({
    required this.title,
    required this.templates,
    required this.onRename,
    this.onAddHere,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                if (onAddHere != null)
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Adicionar status nesta categoria',
                    onPressed: onAddHere,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                IconButton(
                  icon: const Icon(Icons.drive_file_rename_outline, size: 18),
                  tooltip: 'Renomear categoria',
                  onPressed: onRename,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const Divider(height: 8),
            // A linha inteira edita (alvo grande); o lixo fica à parte.
            ...templates.map((t) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onEdit(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        StatTypeBadge(t.type),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(t.type.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ),
                        ItemActionsMenu(
                          itemName: t.name,
                          onEdit: () => onEdit(t),
                          onDelete: () => onDelete(t),
                        ),
                      ],
                    ),
                  ),
                )),
            if (templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Sem status ainda — use o + para adicionar.',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
