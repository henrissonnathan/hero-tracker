# 🧩 Padrões de interface do Hero Tracker

> Criado em 2026-09-29 (sprint "Acessibilidade + criação de card").
> Toda tela nova ou mexida segue isto. Se um padrão não servir, mude AQUI
> primeiro (com OK do dono) e depois no código — nunca uma tela sozinha.
> Por quê: o dono tem dificuldade para digitar e testa no PC (Windows) —
> poucos cliques, pouca digitação, tudo alcançável por Tab/Enter, e leitura
> clara no tema escuro (WCAG 2.1 AA).

## 1. Escolher uma opção → `OptionCard`
`lib/ui/widgets/option_card.dart`

```dart
OptionCard(
  selected: _type == t,
  semanticLabel: 'Tipo ${names.labelOf(t)}',   // o que o leitor de tela fala
  onTap: () => setState(() => _type = t),
  child: Text('${t.emoji} ${t.label}'),        // visual livre
)
```
- Foco por Tab, Enter escolhe, "selecionado" é falado, o toque duplo do
  leitor de tela escolhe, mínimo 48×48.
- `Semantics(excludeSemantics: true)` em volta de algo clicável APAGA a
  ação de toque: exclua só o visual (`ExcludeSemantics` no conteúdo) ou
  devolva o `onTap:` no próprio Semantics.
- Moldura fixa: livre = borda fina `outline`; escolhido = borda grossa +
  fundo `primary` 15%.
- Ícone (emoji) em grade: `EmojiChoice(emoji:, selected:, onTap:)` — 48×48.
- **Nunca** `GestureDetector` para algo clicável (sem foco, sem estado falado).

## 2. Item de lista (card, linha, status) → tocar abre, ⋮ guarda o resto
`lib/ui/widgets/item_actions.dart`

- Tocar no item faz a ação principal:
  - card de **personagem / grupo / sub-grupo** → ABRE a tela dele;
  - **status**, **status do modelo**, **habilidade** → EDITA.
- Editar e Apagar ficam no **⋮** (`ItemActionsMenu(itemName:, onEdit:,
  onDelete:)`): um botão de 48×48 no lugar de dois ícones pequenos.
- Botão de ação que fica visível (ex.: "+" de sub-habilidade, toggle) usa
  `IconButton` padrão com `tooltip` — sem `VisualDensity.compact`, sem
  `padding: EdgeInsets.zero` + constraints < 48, sem `shrinkWrap`.
- Exceção: nó da árvore NÃO tem Editar, então o "×" de apagar fica visível
  (48×48, tooltip, `confirmDelete`) — ⋮ com um item só seria 1 toque a mais.
- O `AppTheme` fixa `materialTapTargetSize: padded` e
  `visualDensity: standard`: sem isso o Flutter encolhe tudo no Windows.

## 3. Apagar → `confirmDelete`
```dart
if (!await confirmDelete(context, itemName: stat.name)) return;
```
- SEMPRE confirma (dado do dono é sagrado). `detalhe:` diz o que vai junto
  ("Os status, as habilidades e a foto vão junto.").
- Palavra única no app: **Apagar** (não "Deletar"/"Remover").

## 4. Dialog de formulário
- Primeiro campo com `autofocus: true` (também na edição); **Enter** faz a
  ação principal (`onSubmitted`); **Esc** cancela (o `AlertDialog` já faz).
- Nome repetido: bloqueia CRIAR e RENOMEAR; editar sem trocar o nome sempre
  salva (dado antigo/backup pode ter repetidos).
- Enquanto grava: `PopScope(canPop: false)` + Cancelar desligado, e o pop
  final só fecha o próprio dialog (`ModalRoute.of(context)?.isCurrent`).
- Gravação que mexe em 2+ tabelas = transação única no repositório (ex.:
  `insertCharacterWithTemplates`), senão "tente de novo" mente.
- Erro aparece **no próprio campo** (`errorText`), nunca só num SnackBar.
- Campo principal primeiro; o opcional fica recolhido em "Mais opções".
- Texto livre só quando não há alternativa: prefira `OptionCard`, chips de
  atalho e reuso do que já foi digitado (ex.: gatilhos do jogo).
- Botões: `Cancelar` (TextButton) à esquerda; ação principal
  `FilledButton.icon` com VERBO ("Criar e abrir", "Salvar"); ação
  secundária `OutlinedButton.icon` ("Criar outro").

## 5. Depois de criar
- Criar algo que o dono vai preencher em seguida → **abre direto** a tela
  dele ("Criar e abrir").
- Criar vários seguidos → "Criar outro": grava, avisa DENTRO do dialog
  ("✓ Cao Cao criado"), limpa o nome, mantém as escolhas e o foco no nome.

## 6. Cor, tipo e texto
- Tipo de status: sempre `StatTypeBadge` / `stat_type_visual.dart` (ícone +
  cor + palavra — nunca só cor).
- Cor nova: `Theme.of(context).colorScheme.*`. Texto secundário:
  `onSurfaceVariant` (o `Colors.grey.shade600+` reprova no contraste).

## 7. Checklist de tela nova/mexida
- [ ] Nada clicável menor que 48×48; todo `IconButton` com `tooltip`
- [ ] Escolha = `OptionCard`/`EmojiChoice`; item de lista = tocar + ⋮
- [ ] Apagar com `confirmDelete`
- [ ] Dialog: autofocus, Enter, erro no campo, verbo no botão
- [ ] Teste de widget (L5) + medida de alvo de toque (test/tap_target_test.dart)
