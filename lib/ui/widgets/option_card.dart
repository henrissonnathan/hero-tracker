import 'package:flutter/material.dart';

/// Cartão de ESCOLHA (seleção única) — padrão do app para qualquer "escolha
/// uma opção": tipo de unidade, categoria, tipo de status, ícone.
///
/// Já resolve o que um `GestureDetector` esquecia: recebe foco (Tab) e Enter,
/// o leitor de tela diz o nome e se está selecionado, e a área de toque tem
/// no mínimo 48×48. O conteúdo ([child]) é livre; a moldura é sempre igual:
/// borda fina quando livre, borda grossa + fundo na cor primária quando
/// escolhido. Ver docs/PADROES-UI.md.
class OptionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  /// O que o leitor de tela fala (o [child] é visual e fica de fora).
  final String semanticLabel;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Posição do [child] dentro do cartão.
  final AlignmentGeometry alignment;

  /// Tamanho fixo (ex.: ícone quadrado). null = o conteúdo decide, com
  /// mínimo de 48×48.
  final double? size;

  const OptionCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.alignment = Alignment.center,
    this.size,
  });

  static const double minTarget = 48;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    // Um nó só para o leitor de tela: nome + "selecionado" + a AÇÃO de toque
    // e o foco que o InkWell expõe. Só o conteúdo visual fica de fora —
    // excluir o nó inteiro apagaria a ação ("botão" que não faz nada).
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            constraints: const BoxConstraints(
                minWidth: minTarget, minHeight: minTarget),
            padding: size == null ? padding : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: radius,
              border: Border.all(
                color: selected ? cs.primary : cs.outline,
                width: selected ? 2 : 1,
              ),
            ),
            // Fatores 1: centraliza/posiciona sem esticar o cartão (num Wrap,
            // um Align comum ocuparia a largura toda).
            child: Align(
              alignment: alignment,
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Escolha de ícone (emoji) num quadrado 48×48 — usado nos dialogs de grupo
/// e de nó da árvore.
class EmojiChoice extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  const EmojiChoice({
    super.key,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) => OptionCard(
        selected: selected,
        onTap: onTap,
        semanticLabel: 'Ícone $emoji',
        size: OptionCard.minTarget,
        child: Text(emoji, style: TextStyle(fontSize: fontSize)),
      );
}
