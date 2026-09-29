# 📋 RELATÓRIO DE RETROFIT — Hero Tracker × ROADMAP v2

> Comparação do código existente (schema v9, commit atual sem push) com o ROADMAP v2 aprovado (14 fases + ajustes do crítico) e a visão PROD (`hero-tracker-produto`). Data: 2026-07-24.

---

## ✅ O que fica como está

- **`lib/models/character_ability.dart` (estrutura geral)** — já tem as duas partes da visão (texto livre + efeito flat/% + isActive); a Fase 3 nasce em cima dele sem mudança de shape.
- **CRUD de habilidades no repositório (`tracker_repository.dart:267-300`)** — SQL seguro com `?` + whereArgs; quando o modelo ganhar `targetStatId`, a coluna flui pelo toMap/fromMap sozinha.
- **Semântica "valor salvo nunca muda" + toggle `isActive`** — é exatamente "tracker, não simulador"; a Fase 3 usa o toggle direto no comparador.
- **`lib/models/character_type.dart`** — vira fóssil de fallback na Fase 9 sem mexer no arquivo; só não portar `entersBattle` (anti-padrão 4).
- **`lib/models/group_stat_template.dart`** — cópia unidirecional já é o desenho final exigido pelo anti-padrão 7.
- **`lib/models/stat_type.dart`** — os 4 tipos batem 1:1 com a tabela da visão PROD (Gatilho/Número/Porcentagem/Cálculo).
- **Cadeia de migrações v1→v9 (`database_helper.dart:99-157`)** — já segue "1 migração por fase, aditiva, sem DROP"; a Fase 1 só adiciona o teste de paridade ao lado.
- **Colunas fósseis atuais (`characterType`, `maxHeroesPerSquad/maxCommandersPerSquad`, `triggerText`)** — corretas hoje; viram fósseis não lidos nas Fases 4 e 9, nunca DROP.
- **CRUD geral do `tracker_repository.dart`** — nenhuma fase reescreve o repositório; as fases 3-11 só adicionam métodos ao lado.
- **`lib/services/icon_image_store.dart`** — o pipeline seguro (validação antes de decodificar, PNG próprio, `isWithin`) já é o que a Fase 12 manda reusar; ela só adiciona testes.
- **`lib/ui/stats_screen.dart`** — coração do "mapear o jogo" já nasceu alinhado; retoques (Desfazer, cores, bottom sheet) já têm fase dona (5/13/14).
- **`lib/ui/widgets/star_rank_display.dart`** — widget puro de exibição; só os 2 greys entram na varredura mecânica da Fase 13.
- **`lib/ui/widgets/group_icon.dart`** — já é genérico com fallback duplo; a Fase 12 reusa como está para personagem e facção.
- **`test/group_stat_template_test.dart`** — cobre contratos que todas as fases preservam (cópia não-referência, toggle de habilidade); testes novos nascem em arquivos próprios.
- **`docs/ROADMAP.md`** — é o próprio plano aprovado; único cuidado é o CLAUDE.md passar a apontar para ele (sem dois roadmaps concorrentes).

---

## 🔧 O que se ajusta

| Peça | Ajuste | Fase do v2 | Risco se nada for feito |
|------|--------|------------|--------------------------|
| `targetStatName` por nome (`character_ability.dart:18-19`; `character_screen.dart:58, 315-318, 629`) | Ganha `targetStatId` + backfill por nome; leitura passa a usar ID (fallback por nome só transitório) | **Fase 3** (v10) | Renomear um status HOJE já quebra o efeito em silêncio; habilidade que ficar órfã antes da v10 não é religada pelo backfill — dano permanente que cresce com o uso |
| `_boostedValueFor` (`character_screen.dart:51-65`) | Extrair para função Dart pura em arquivo próprio (motor único, chave por ID); a tela chama o motor | **Fase 3** | Se o comparador nascer com cópia da lógica, ficam dois motores que divergem — o retrabalho que a F3 existe para evitar |
| `_AbilityDialog` (`character_screen.dart:609-835`) | Dropdown de alvo por ID (F3); campo de gatilho vira chips do jogo (F4); casca pode virar bottom sheet (F14) | **Fases 3, 4, 14** | Baixo — estrutura de duas partes se mantém |
| `_AbilityCard` (`character_screen.dart:525-607`) | Nome do stat via ID (F3); linha "⚡" lê gatilhos N:N (F4); delete ganha SnackBar Desfazer (F5) | **Fases 3, 4, 5** | Delete sem desfazer (`character_screen.dart:203-206`) é perda de dado a um toque acidental até a F5 |
| Export/import de habilidades (`export_service.dart:30-34, 115-131`) | Incluir `targetStatId` com remap id-antigo→id-novo no MESMO sprint da coluna + bump do contrato | **Fases 2, 3, 4** | Sem remap, backup restaurado religa habilidades a stats ERRADOS do banco antigo — corrupção silenciosa |
| `exportAll` (`export_service.dart:20-60`) | Extrair `buildExportJson()` testável; incluir `skill_nodes`; version → 2; `docs/CONTRATO-JSON.md` | **Fase 2** | Bug de perda de dados ATIVO: backup de hoje não contém a árvore — restaurar perde todos os skill_nodes |
| `importFromFile` (`export_service.dart:63-157`) | Validação rígida + ler `version` + transação única + mensagem genérica + skill_nodes com remap | **Fase 2** | JSON truncado no meio do loop deixa o banco meio-importado; `$e` vaza erro interno na UI |
| PRAGMA foreign_keys (`database_helper.dart:36-41, 213-216`; `tracker_repository.dart:91, 126`) | Mover para `onConfigure` do `openDatabase`; remover `enableForeignKeys()` e as 2 chamadas inline | **Fase 1** | Deletar nó pai antes do 1º delete de grupo/personagem não dispara SET NULL — filhos órfãos permanentes; todo CASCADE novo das fases 3-11 nasceria desligado na prática |
| `getAllIconImagePaths` (`tracker_repository.dart:35-46`) | Virar UNION (groups + characters + factions) NO MESMO commit da v17 | **Fase 12** | Se a foto de personagem entrar sem essa query mudar junto, o cleanup do boot apaga todas as fotos novas — PNG deletado do disco, irreversível |
| `skill_node.dart` | Ganha `treeId` (v13) e `currentLevel/maxLevel` (v14); `costPoints`/`isUnlocked` viram fósseis | **Fases 7 e 8** | Baixo — só volume de backfill crescendo com o uso |
| `skill_tree_screen.dart` | Parametrizar por `skill_tree` (não GameGroup); card "3/10" com +/−; dialog ganha `initial` (fim do deletar-e-recriar); bloqueio de pai sai | **Fases 7 e 8** | Editar-via-deletar hoje derruba a subárvore dos filhos; bloqueio de desbloqueio contradiz "o app registra, não impõe" |
| `character.dart` | `unitTypeId` (v15), `factionId` (v16), `iconImagePath` (v17) — tudo aditivo nullable | **Fases 9, 11, 12** | Nenhum real — backfills previstos |
| `game_group.dart` | Limites copiados p/ `unit_types.maxPerSquad` (F9); `contentCategory` vira vestigial (F14) | **Fases 9 e 14** | Só não investir nada novo em `contentCategory` |
| `character_stat.dart` — `formulaText` morto (linha 17; `displayValue:87-88`) | Avaliador de fórmulas em função pura; `displayValue` passa a calcular; fallback "não avaliável = mostra texto" | **Fase extra** (entre F8 e F9) | Risco que cresce: fórmulas digitadas até lá são texto sem sintaxe garantida e referem stats por NOME — renomear quebra em silêncio (mesma dívida que a F3 paga nas habilidades) |
| `home_screen.dart` | Menu Exportar/Importar (F2); `_GroupDialog` extraído p/ `widgets/` como caminho único de CRUD de grupo (F5) | **Fases 2 e 5** | Enquanto o dialog for privado, melhorias não chegam ao sub-grupo — duplicação cresce nas fases 6, 7, 11 |
| `_CharacterDialog`/`_CharacterCard` (`game_screen.dart:640-685, 771-967`) | "+1" de nível no card (F5); extração p/ `widgets/` + tipos do banco (F9); foto (F12); bottom sheet (F14) | **Fases 5, 9, 12, 14** | `game_screen.dart` já tem 1247 linhas — sem a extração vira o maior ponto de conflito do projeto |
| `_SubGroupDialog` (`game_screen.dart:1067-1198`) | Substituído pelo `_GroupDialog` extraído; sub-grupo ganha Editar/Deletar | **Fase 5** | Errar o nome de um sub-grupo hoje só se conserta deletando o pai inteiro — dado preso até a F5 |
| `stat_tile.dart` | Ligar `onIncrement/onDecrement` já prontos (chamador `character_screen.dart:243`); tokens de tema (F13); fim do "X" de deletar (F14) | **Fases 5, 13, 14** | Nenhum — só não deixar a F5 reimplementar o que já existe |
| `stat_form_dialog.dart` | Casca AlertDialog vira bottom sheet; lógica interna aproveitada integral | **Fase 14** | SegmentedButton de 5 tipos já transborda em tela estreita — suportável até lá |
| `test/widget_test.dart` | Trocar `Future.delayed` fixos por `pumpUntilFound`; smoke do `HeroTrackerApp` real | **Fase 1** | 1,4s desperdiçado por rodada + flakiness; regressão no boot real passa invisível |
| `CLAUDE.md` (schema, estrutura, fases) | Ver Quick-wins abaixo | **quick-win agora** (também na Fase 1) | Sessão futura planeja migração v10+ sobre um "v4" mental — receita de colisão com as v5-v9 reais |

---

## ♻️ O que se reescreve

| Peça | O que muda | Fase | O que aproveitar do atual |
|------|-----------|------|---------------------------|
| Gatilho como texto livre (`character_ability.dart:14`; `character_screen.dart:702-708, 569-570`) | Gatilhos passam a pertencer ao JOGO: tabelas `game_triggers` + `ability_triggers` (N:N), backfill deduplicado por nome; `triggerText` vira fóssil NÃO lido | **Fase 4** (v11) | O conteúdo já digitado (vira os gatilhos via backfill) e o conceito "sem gatilho = conta sempre", que a UI já exibe |
| Chips de `ContentCategory` (`game_screen.dart:202-206, 296-330`) | Categoria fixa de estratégia sai da GameScreen (decisão fechada); filtro passa a tags de tropa (F6) e facções (F11) | **Fase 14** | Só o padrão visual de FilterChip para os filtros novos |
| `_applyStrategyTemplate` (`game_screen.dart:74-117, 258-262`) | É o "conteúdo curado por jogo" que a visão proíbe; substituído pelo wizard "Novo jogo" com chips genéricos; específico vem por presets do usuário (F10) | **Fase 14** | A mecânica de criar vários sub-grupos de uma vez sem duplicar por nome (linhas 103-105) |
| `_SquadSummaryBar`/`_TypeChip`/`_typeCounts`/`_squadWarning` (`game_screen.dart:209-234, 443-549`) + textos chumbados (linhas 654, 899) | Contadores passam a ler `unit_types` do banco com `maxPerSquad` por tipo dinâmico; colunas antigas nunca mais lidas; textos de estratégia saem da UI | **Fase 9** (v15) | O desenho visual do `_TypeChip` "emoji N/M" e a lógica de limite excedido |

---

## ⚡ Quick-wins de agora

1. **CLAUDE.md — schema**: trocar "versão atual: 4" pelo v9 real (`database_helper.dart:11`) — hoje faltam iconImagePath, group_stat_templates, character_abilities e as migrações v5-v9.
2. **CLAUDE.md — estrutura de arquivos**: listar `stats_screen.dart`, `widgets/group_icon.dart`, `widgets/stat_form_dialog.dart`, `services/icon_image_store.dart`, `models/group_stat_template.dart`, `models/character_ability.dart`.
3. **CLAUDE.md — fases**: substituir a seção "Fases do projeto" (roadmap v1: Sprint 4-7) por um ponteiro para `docs/ROADMAP.md` como fonte única — evita ressuscitar features que o v2 descartou.
4. **CLAUDE.md — drift do StatType**: remover o tipo `count`, que não existe mais em `lib/models/stat_type.dart` (linhas antigas caem em `number` via orElse).
5. **Remover `_SimpleNameDialog`** (`game_screen.dart:1202-1247`): código morto, nunca instanciado — 46 linhas de ruído; `flutter analyze` continua verde.

---

## 🧭 Conclusão honesta

Das ~33 peças auditadas, **15 ficam intactas, 4 se reescrevem e o resto se ajusta de forma aditiva** — na prática, **cerca de 85% do que foi construído sobrevive ao plano v2**, e mesmo as 4 reescritas aproveitam pedaços (backfill dos gatilhos digitados, visual dos chips, mecânica de sub-grupos). Isso é bom e esperado por dois motivos: o roadmap v2 foi desenhado deliberadamente como aditivo (fósseis, nunca DROP, fallback L1), então "ajustar" quase sempre significa acrescentar coluna/tabela ao lado do que existe; e as fundações — migrações versionadas, SQL parametrizado, cópia unidirecional de templates, pipeline seguro de imagem — já nasceram alinhadas à visão. O que morre é exatamente o conteúdo "chumbado de jogo de estratégia" (categorias fixas, template estratégico, enum de tipos) que a lei "genérico > específico" sempre condenou. Os dois riscos que não esperam fase são os já cobertos pelas Fases 1-3: backup sem árvore (perda ativa) e vínculo por nome (degrada a cada renomeação) — razão a mais para elas virem primeiro.
---

## 🔧 Complemento do crítico (peças que faltaram — incorporadas)

| Peça | Veredito | Fase | Motivo |
|------|----------|------|--------|
| `lib/theme/app_theme.dart` | ajustar | F13 | GoogleFonts.nunitoTextTheme depende de rede (F13 embute a fonte como asset) e concentra as cores chumbadas que viram tokens de tema |
| `lib/main.dart` | ajustar | F1 + F13 | F1: smoke de boot do widget raiz REAL; F13: `theme: AppTheme.dark` fixo vira tema dinâmico do ThemeController |
| `lib/models/star_rank.dart` | ajustar | F5 | o modelo só AVANÇA (advanceSubLevel/advanceBy/advanceStar) — o "−1 sub" da F5 exige método de regressão novo |
| `lib/models/content_category.dart` | manter (fóssil) | F14 | os chips saem da GameScreen na F14, mas o enum fica como legado não removido (nunca DROP) |
| `lib/repositories/desktop_database_init.dart` | manter | — | nenhuma fase do v2 o toca; segue como está |
| `COMMIT_PUSH_HERO.bat` (e .bat da raiz) | ajustar | F1 | ganha o gate: chama TESTAR.bat antes e aborta se falhar |

Com isso as ~39 peças do projeto estão 100% classificadas.
