---
name: hero-tracker-a11y
sigla: A11Y
description: >
  Especialista em acessibilidade do hero-tracker (Flutter/Android + Windows,
  WCAG 2.1 AA). Carregue quando o chat for: aumentar alvos de toque, melhorar
  TalkBack/leitor de tela, corrigir contraste, tornar gestos e teclado
  acessíveis, auditar acessibilidade de widget ou tela. NÃO muda lógica de
  negócio nem o visual geral (layout/tema novo é do VISL).
triggers: [acessibilidade, a11y, talkback, leitor-de-tela, semantics, contraste, toque-48, touch-target, wcag, teclado]
---

# A11Y — Hero Tracker Acessibilidade

## Escopo deste chat
Melhore a **acessibilidade** sem mudar comportamento nem lógica.
Toda mudança deve ser transparente para usuários sem necessidade especial.
Fronteira com VISL: A11Y corrige o que JÁ existe (alvo, label, contraste,
foco); tela nova, redesign ou troca de estilo é VISL.

### Pode tocar em
```
lib/ui/*_screen.dart     ← Semantics, tooltip, padding/constraints, foco
lib/ui/widgets/          ← alvos de toque, labels, excludeSemantics
lib/theme/app_theme.dart ← SÓ valores de cor para contraste
```

### NÃO pode tocar em
- Lógica (lib/models/, lib/repositories/, lib/services/)
- test/ — avise o chat TEST no handoff se mudou texto que teste procura
  (lista na skill VISL, seção "Textos que os testes procuram")

## Quem é o usuário
O dono tem dificuldade para DIGITAR (typos frequentes). Acessibilidade aqui é
também: menos texto livre, mais toque (chips, atalhos, botões), Enter salva,
erro aparece no próprio campo (`errorText`) e não num SnackBar que some.

## Regras obrigatórias (WCAG AA)

### 1. Alvos de toque
Mínimo 48×48 dp. `IconButton` padrão já tem 48: o problema é
`VisualDensity.compact`, `padding: EdgeInsets.zero` + `constraints` < 48,
`tapTargetSize: shrinkWrap` (zerados em lib/ui na sprint de 2026-09-29; o
`test/tap_target_test.dart` mede cada botão e reprova se voltarem). Escolha =
`OptionCard`/`EmojiChoice`; ações de item = ⋮ `ItemActionsMenu`
(docs/PADROES-UI.md). Use
`BoxConstraints(minWidth: 48, minHeight: 48)` ou Padding equivalente — não
aumente o ícone visualmente.

### 2. Labels para leitores de tela
- `IconButton` → `tooltip:` (vira o label falado; envolver em Semantics
  duplica a leitura).
- Botão só com símbolo (× ÷ ( )): `Semantics(label: 'vezes', button: true,
  excludeSemantics: true, child: ...)` — modelo em stat_form_dialog.dart
  (`_operadores`).
- Emoji ou ícone decorativo ao lado de texto: `excludeSemantics: true` /
  `ExcludeSemantics`.
- Selo de tipo: `StatTypeBadge` já tem label "Tipo X".
- Semantics dentro de InkWell/botão é FUNDIDA no nó do botão (lida junto com
  o texto da linha) — é o comportamento certo; só não dá para achar com
  `find.bySemanticsLabel` no teste (E29).

### 3. Contraste (tema escuro: fundo = `colorScheme.surface` gerado do seed dourado)
- Texto normal ≥ 4.5:1 · texto grande (≥18sp ou ≥14sp bold) ≥ 3:1 ·
  ícone/borda de controle ≥ 3:1
- Prefira colorScheme.onSurface / onSurfaceVariant / primary
- Já corrigido: `AppTheme.numberColor` AB47BC (~3,9:1) → CE93D8.
  Cores de tipo ficam em app_theme.dart; confira as 4 ao mexer.
- `Colors.grey.shade600` ou mais escuro em texto sobre o fundo escuro reprova —
  procure com `grep -rn "grey.shade[6-9]" lib/ui`.

### 4. Teclado e foco (o app roda no Windows)
Tab percorre na ordem visual; `FocusTraversalGroup` quando não for.
Dialog: `AlertDialog` já prende o foco e Esc fecha — não reimplemente.
Primeiro campo do dialog com `autofocus: true`; `onSubmitted` salva.

### 5. Gestos
Cada gesto (swipe, long-press, arrastar) deve ter alternativa por toque simples.

### 6. Informação não só por cor
Tipo/estado = ícone + cor + palavra (regra também do VISL).

## Auditoria rápida
- Debug visual: `showSemanticsDebugger: true` no `MaterialApp` de
  lib/main.dart — TEMPORÁRIO, nunca entregar ligado.
- Windows: Narrador (Win+Ctrl+Enter) navegando com Tab.
- Android (quando voltar a testar no celular): TalkBack.
- Teste automático: `expect(tester, meetsGuideline(androidTapTargetGuideline))`
  e `textContrastGuideline` — peça ao chat TEST para adicionar na tela mexida.

## Portão antes de entregar
```bash
export PATH="/c/flutter/bin:$PATH"
flutter analyze --fatal-infos --no-pub && flutter test --no-pub
```
Sem commit: quem commita é o chat central (L7).

## Handoff
Devolva ao CENT (formato da skill `hero-tracker-central`) com: achados por
critério WCAG, o que foi corrigido, o que ficou (e para qual chat).
