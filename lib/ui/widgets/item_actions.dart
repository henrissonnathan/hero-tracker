import 'package:flutter/material.dart';

/// Menu ⋮ de um item de lista (card, linha, status) — padrão do app:
/// tocar no item ABRE/EDITA; o ⋮ guarda Editar e Apagar. Um botão só, de
/// 48×48, no lugar de dois ícones pequenos. Ver docs/PADROES-UI.md.
class ItemActionsMenu extends StatelessWidget {
  /// Nome do item — vai no tooltip ("Ações de Cao Cao").
  final String itemName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Tamanho do ícone ⋮ (a área de toque é sempre 48×48).
  final double iconSize;

  const ItemActionsMenu({
    super.key,
    required this.itemName,
    this.onEdit,
    this.onDelete,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final erro = Theme.of(context).colorScheme.error;
    return PopupMenuButton<String>(
      tooltip: 'Ações de "$itemName"',
      icon: Icon(Icons.more_vert, size: iconSize),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: erro),
              title: Text('Apagar', style: TextStyle(color: erro)),
            ),
          ),
      ],
    );
  }
}

/// Confirmação padrão antes de apagar (dado do dono é sagrado).
/// [detalhe] explica o que vai junto (ex.: "e todos os personagens").
/// Devolve true só se o dono tocar em Apagar.
Future<bool> confirmDelete(
  BuildContext context, {
  required String itemName,
  String? detalhe,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
      title: Text('Apagar "$itemName"?'),
      content: Text(detalhe ?? 'Isso não pode ser desfeito.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError),
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Apagar'),
        ),
      ],
    ),
  );
  return ok == true;
}
