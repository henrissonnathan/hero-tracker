---
name: hero-tracker-visual
sigla: VISL
description: >
  Especialista em aparência e interface do hero-tracker (Flutter/Material 3).
  Carregue quando o chat for trabalhar em: tema, cores, layout de telas,
  widgets visuais, tipografia, espaçamento, ícones, exibição de fotos, dark
  mode, responsividade, "poucos cliques". NÃO toca em lógica de negócio, SQL
  nem no pipeline de foto.
triggers: [aparência, visual, layout, tema, cor, dark-mode, widget, ícone, foto, responsiv, Material-3, cliques]
---

# VISL — Hero Tracker Visual

## Escopo deste chat
Trabalhe **somente** na camada de apresentação. Deixe o app bonito, consistente
e com poucos cliques, sem alterar regras de negócio nem schema de banco.
Acessibilidade fina (TalkBack, Semantics, auditoria WCAG) é do chat A11Y; aqui
basta não piorar (regras 1-2 abaixo valem sempre).

### Pode tocar em
```
lib/theme/app_theme.dart
lib/ui/home_screen.dart · game_screen.dart · character_screen.dart
lib/ui/stats_screen.dart · skill_tree_screen.dart · tests_info_screen.dart*
lib/ui/widgets/ stat_tile · stat_type_visual · star_rank_display
                group_icon · stat_form_dialog
lib/main.dart  (só MaterialApp: título/tema)
```
\* tests_info_screen.dart: só o visual. A lista `TestsInfo` é do chat TEST.

### NÃO pode tocar em
- lib/models/ · lib/repositories/ · lib/services/ — lógica e banco (FUNC/BANC/JSON)
- test/ — use o chat TEST para ajustar testes
- Pipeline de foto (`IconImageStore`: validar, re-codificar PNG, apagar órfão) —
  é FUNC. Aqui só a EXIBIÇÃO (`GroupIcon`, tamanho, fallback de emoji).

### Lógica que MORA na UI hoje (não quebre ao mexer no layout)
- `character_screen.dart` `_boostedValueFor` (~linha 87): soma o bônus das
  habilidades ativas (`bonusKind` flat soma, percent multiplica). Mudou layout
  → o valor "⚡ com habilidades" tem que continuar aparecendo.
- `home_screen.dart` (~linha 35): limpeza de fotos órfãs no boot usa
  `getAllIconImagePathsInUse()` — NUNCA trocar por uma lista só (apaga fotos).
- `stats_screen.dart` `_importPack/_exportPack`: botões do pacote JSON.
Mover qualquer uma dessas para fora da UI é tarefa FUNC, não VISL.

## Stack visual
- Material 3 (`useMaterial3: true`), tema SÓ escuro: `AppTheme.dark`
  (seed dourado `0xFFFFB700`). Não existe tema claro ainda (Fase 13 do ROADMAP).
- Código NOVO usa `Theme.of(context).colorScheme.*`. O código antigo tem ~70
  `Colors.grey/red/...` fixos em lib/ui — troque só na tela que você já está
  mexendo, não faça varredura (vira diff gigante).
- Exceção: as 4 cores de TIPO de status vêm de `AppTheme.*Color`, sempre lidas
  via `stat_type_visual.dart` (tabela abaixo).
- `google_fonts` (Nunito) SÓ dentro de `AppTheme`. Nunca chame `GoogleFonts.*`
  num widget: o teste roda sem rede e quebra (por isso existe
  `HeroTrackerApp(theme: ...)` em lib/main.dart para injetar tema de teste).
- Mobile-first, mas o dono testa no PC (Windows): confira nas duas larguras.

## Regras visuais obrigatórias
1. Alvos de toque ≥ 48×48 dp para toda área clicável (sem
   `VisualDensity.compact` nem `constraints` < 48 em ação principal)
2. Contraste ≥ 4.5:1 texto/fundo (WCAG AA) — prefira colorScheme.onSurface /
   onSurfaceVariant
3. Ícones de stat sempre via `stat_type_visual.dart` — não duplique lógica
4. Tipo/estado nunca só por texto ou só por cor: ícone + cor + palavra
5. Poucos cliques (PROD): linha inteira clicável para abrir/editar; ação
   destrutiva separada e com confirmação
6. Usuário tem dificuldade para digitar: prefira chips/atalhos/botões a
   texto livre; Enter salva, Esc cancela

## Tipos de status (fonte: lib/ui/widgets/stat_type_visual.dart)
| StatType | ícone (Icons.*)     | cor                                 |
|----------|---------------------|-------------------------------------|
| percent  | percent             | AppTheme.percentColor (verde)       |
| number   | tag                 | AppTheme.numberColor (roxo CE93D8)  |
| trigger  | bolt                | AppTheme.triggerColor (laranja)     |
| formula  | calculate_outlined  | AppTheme.formulaColor (ciano)       |

Selo pronto: `StatTypeBadge(type)`. Mudou ícone/cor? Mude SÓ no
stat_type_visual.dart / app_theme.dart — todas as telas seguem.

## Textos que os testes procuram (mudou? avise o chat TEST no handoff)
`'Nome do status'` (label), `'Salvar'`, `'Dê um nome ao status'`,
`'Escolhido pelo nome'`, `'10%'` (ChoiceChip), `'Número'`/`'Gatilho'`/
`'Fórmula'` (StatType.label), `'vezes'` (Semantics do ×), `'Combate'`/
`'Recursos'` dentro de `Card`, `StatTypeBadge` (byType), `'💬 Sua vez'` e
`'Backup'` (tela de testes), emojis de fallback `'🏰'` `'🛡️'` `'🐉'`, `Image`
na foto. Arquivos: widget_test, stat_form_dialog_test, stats_layout_test,
character_photo_test, tests_info_test, unit_type_label_test.

## Portão antes de entregar
```bash
export PATH="/c/flutter/bin:$PATH"
flutter analyze --fatal-infos --no-pub     # zero issues
flutter test --no-pub                      # todos verdes
```
Ver a tela de verdade: `flutter run -d windows` (exige Modo Desenvolvedor do
Windows ligado; se der "requires symlink support", peça ao dono).
Sem commit: quem commita é o chat central (L7).

## Handoff
Terminou ou a tarefa saiu do escopo → devolva ao chat central (CENT) no
formato de handoff da skill `hero-tracker-central`: arquivos tocados, portão
(analyze/testes), textos de teste alterados, o que ficou para outro chat.
