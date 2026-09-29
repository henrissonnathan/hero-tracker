# CLAUDE.md — Hero Tracker (Flutter/Android)

> Carregado automaticamente pelo Claude em toda sessão.
> Projeto: **Hero Tracker** — app Flutter/Android para rastrear heróis, tropas, pesquisa
> e construção em jogos estilo Rise of Kingdoms, Fate War, Art of Conquest.
> Stack: Flutter/Dart, sqflite, shared_preferences, google_fonts, intl.

---

## 📋 Skill Registry (Hero Tracker)

> Kit de skills: `D:\project\meu-kit-claude\.agents\`
> Auditoria completa das 44 skills do kit em 2026-07-24 (8 manter · 19 adaptar · 17 descartar).
> Legenda: `⚙` = adaptada p/ Dart/Flutter (triggers/exemplos traduzidos) · sem marca = mantida como está · `*` = sigla sugerida (arquivo sem SIG)

```
ALWAYS_ON — entram em TODA sessão:
  PROD  | hero-tracker-produto     |   | visão do produto — fonte da verdade do OBJETIVO (mapeador de jogos) — skill DO PROJETO: .claude/skills/hero-tracker-produto/
  GOVN  | skill-governor           |   | decisão-arquitetura | .agents/skills/* | SKILL_MAP.json
  HEAL  | skill-heal               | ⚙ | *.dart | schema-db | .agents/*
  NEXM  | nexus-memory-protocol    |   | sempre (ignorar DEP: arquitetura-formulario-trproc)
  ALOP  | anti-loop-protocol       | ⚙ | *.dart | correção-bug | migration-sqflite | hot-reload-fix
  SDDV  | spec-driven-development  |   | nova-feature | planejar | PRD/SPEC | refactor-grande
  MAPL  | map-leitura              | ⚙ | *.dart | pubspec.yaml | antes de abrir qualquer arquivo
  ATOM  | auto-test-on-modify      | ⚙ | lib/**/*.dart | test/**/*.dart | pré-commit → flutter analyze + flutter test
  RAUX* | raiz-auxiliar-protocol   | ⚙ | *.dart | modificar-existente | refatorar (= lei L1: helper AO LADO)
  PYPT  | python-patterns (→dart)  | ⚙ | *.dart | lib/models|repositories | test/ — SQL só com ? + whereArgs
  AGSY  | agents-sync-protocol     |   | merge-main | rebase | branch toca .agents/* | criar-skill/memory

CONTEXTUAIS — carregam só quando o gatilho dispara:
  skill                          | sigla  | triggers (Dart/Flutter)                     | quando ativa
  debugging-checklist-trproc     | DEBC ⚙ | bug|erro|exception|stacktrace|quebrou       | corrigir bug: root-cause primeiro, nunca band-aid
  verifica-teste                 | VTST ⚙ | flutter-test-FAILED|golden-diff|test/*.dart | teste vermelho → diagnosticar→corrigir→re-rodar (máx 3)
  testing-patterns-trproc        | TSPT ⚙ | escrever-teste|widget-test|test/*.dart      | padrões de teste: tiers unit/widget/db/regression (lei L5)
  fundamentos-logica-sistema     | LOGC ⚙ | nova-feature|master-detail|regra-de-negócio | modelar lógica antes da sintaxe; transação única sqflite
  database-performance           | DBPF*⚙ | lib/repositories/*.dart|query-sql|lentidão  | anti-N+1, Batch, índices, EXPLAIN QUERY PLAN
  sqlalchemy-2-patterns (→sqflite)| SQL2 ⚙ | rawQuery|sqflite|schema-db|query-em-loop    | SQL seguro (? + whereArgs), db.transaction()/batch()
  log-erros-seguro               | LOGS ⚙ | exception|crash|logging|migration-falhou    | kDebugMode+debugPrint; erro → arquivo, UI genérica
  branch-save-protocol           | BSPT ⚙ | git-commit|git-push|salvar|COMMIT_PUSH_HERO | fluxo L7: OK do usuário → suite verde → commit específico
  clean-test-artifacts           | CTAR ⚙ | antes-commit|antes-PR|fim-de-teste          | limpar debugPrint/dados TEST no banco/screenshots órfãos
  system-integrity-tester        | SINT*⚙ | antes-release|BUILD_APK|migration           | bateria: CRUD FFI em memória + migrations completas + analyze/test
  auto-doc-protocol              | ADOC*⚙ | nova-pasta-em-lib|lib/**/*.dart|README*.md  | README_LOCAL.md por pasta relevante de lib/
  agent-tracker                  | ATRK*  | tarefas-complexas|multi-arquivo|sprint-novo | log de progresso em refatoração multi-tela
  spec-reviewer                  | SPRV ⚙ | /spec-reviewer|revisar-spec|validar-spec    | entrevista de SPEC (autofill Flutter/sqflite, sem api/auth)
  skill-creator                  | SKCR*⚙ | criar-skill|editar-skill|.agents/skills/*   | pipeline de criação/edição de skills do kit
  skills-vs-agentes              | SKVA   | decidir-skill-ou-agente|planejar-automacao  | skill-first, anti-overengineering
  claude-workflows               | FLOW   | workflow|paralelizar-agentes|escalar         | fan-out multi-agente (raro aqui: repo pequeno)
  caveman (+ família)            | CAVE   | /caveman|economizar-token|responde-curto     | resposta enxuta, nível full (DO PROJETO: .claude/skills/caveman*)
    caveman-compress|-commit|-review|-help|-stats|cavecrew → mesma pasta; agents cavecrew-* em .claude/agents/
    hook .claude/hooks/caveman_lembrete.py (UserPromptSubmit) lembra o nível; nível em .claude/caveman/nivel (fora do git)
  segundo-cerebro-obsidian       | CERE   | obsidian|vault|/segundo-cerebro             | PKM pessoal (manual, nunca em sessão de código)
  hero-tracker-visual    | VISL ⚙ | aparência|visual|layout|tema|cor|widget|ícone|foto|dark-mode    | ajustes visuais sem tocar lógica; Material 3
  hero-tracker-func      | FUNC ⚙ | model|repository|CRUD|seed|habilidade|bônus|herança|foto-segura  | regra de negócio; schema→BANC, arquivo→JSON
  hero-tracker-banco     | BANC ⚙ | schema|migration|onUpgrade|ALTER-TABLE|_dbVersion|coluna-nova      | migration de ponta a ponta (próxima = v12)
  hero-tracker-json      | JSON ⚙ | JSON|contrato|backup|export|import|pacote|formatVersion|mapear-jogo | contrato oficial + pacote de jogo (2º app)
  hero-tracker-testes    | TEST ⚙ | teste|test|flutter-test|cobertura|mock|FFI|bateria|verde|vermelho  | bateria de testes: escrever, corrigir, auditar
  hero-tracker-a11y      | A11Y ⚙ | acessibilidade|a11y|talkback|semantics|contraste|toque-48|wcag    | acessibilidade WCAG AA; sem tocar lógica
  hero-tracker-central   | CENT   | orquestrar|dividir|chats-filhos|handoff|integrar|sprint           | chat central: divide, roteia, integra, commit c/ OK

DESCARTADAS — TRPROC/Flask/web, NÃO carregar no hero-tracker:
  arquitetura-banco-dados       → schema do CRM Mesa
  arquitetura-formulario-trproc → cérebro exclusivo do TRPROC
  arquitetura-mesa-de-trabalho  → camadas/fluxo do CRM
  auditoria-sistema             → trilha jurídica LGPD/licitação
  cadastros-informativos        → módulo cinfo_* do TRPROC
  configuracao-pagina           → pipeline SSR Jinja/Flask
  deploy-dokploy                → deploy VPS; app é local
  dossie-tenant-security        → multi-tenant JWT inexistente
  iza-sync-patterns             → sync IZA Cloud específica
  javascript-patterns           → sem JS no projeto
  jinja-patterns                → sem templates HTML
  pergunta-dinamica             → formulários dinâmicos web
  security-regression-suite     → pentest web sem backend
  tenant-security               → sem auth nem tenant
  trproc-admin-toolkit          → scripts Python do TRPROC
  trproc-table-master           → tabelas dinâmicas web
  visual-design-system-check    → design web Jinja/CSS

BOOT (adaptação p/ hero-tracker):
  Seguir BOOT_SEQUENCE STEPs 0–4 normalmente.
  STEP_5 (arquitetura-formulario-trproc, descartada) → substituir pela leitura deste CLAUDE.md.
  Pilares do boot que NÃO se aplicam: P2 (municipio_id_fk), P13 (upload web), P16 (python-first → aqui é DART_FIRST).
  ORCH/MAPL dependem de CODE_MAP.min.json — gerar com o generator adaptado a lib/ e test/ antes de usar.
```

---

## 🏗️ CONTEXTO DO PROJETO

### Propósito (fonte da verdade: skill PROD do projeto — .claude/skills/hero-tracker-produto)
**Mapeador de jogos**: qualquer pessoa, SEM programar, mapeia como um jogo
funciona por dentro (números, bônus %, fórmulas, gatilhos, habilidades) e usa o
mapa para montar e COMPARAR builds de heróis em conjunto. Começa por estratégia
mobile (RoK/CoD é o caso fácil), serve para qualquer jogo (inclusive RPG).
100% offline/local; dados do usuário são sagrados.
Os dados alimentarão um 2º app futuro de TESTE/simulação via JSON documentado
com validação rígida (formato = contrato oficial estável).
Tipos de status = lentes de mapeamento: gatilho (o que deve acontecer p/ ter
efeito), número (recursos/custos/tempo), porcentagem (bônus %), cálculo
(fórmulas entre stats). Regra de decisão: toda feature serve ao MAPEAMENTO ou
à COMPARAÇÃO — senão, questionar.

### Stack obrigatória
- **Framework**: Flutter (Dart) — Android (alvo principal) + Windows desktop (dev/testes no PC)
- **Banco**: `sqflite` — schema versionado, migrations via `onUpgrade`
  (desktop usa `sqflite_common_ffi` via helper ao lado — Android intocado)
- **Configs**: `shared_preferences`
- **Fonte**: `google_fonts`
- **Export**: `share_plus`, `open_filex`, `file_picker`

### Estrutura de arquivos (pós-sprint 2 — 2026-07-19)

```
lib/
  main.dart
  models/
    character.dart          ← herói/tropa/unidade — tem: name, role, notes, starRank,
                              characterType, level (v2), groupId, iconImagePath (v10)
    character_stat.dart     ← atributo dinâmico — tipo: count/percent/number/trigger/formula
    character_type.dart     ← enum: soldadoNormal | heroi | comandante
    content_category.dart   ← enum: heroes | troops | research | building | general (v2)
    game_group.dart         ← grupo/jogo — tem: name, iconEmoji, parentId, maxHeroesPerSquad,
                              maxCommandersPerSquad, contentCategory (v2)
    skill_node.dart         ← nó de árvore de habilidades/pesquisa
    star_rank.dart          ← rank com estrelas + sub-níveis (8 sub/estrela)
    stat_type.dart          ← enum: percent | number | trigger | formula (count removido v8)
    group_stat_template.dart← template de status do grupo (modelo) + category
    unit_type_label.dart    ← nome/emoji do tipo por jogo (v11) + UnitTypeNames
                              (sempre responde: custom ou padrão do enum)
    character_ability.dart  ← habilidade de herói: descrição+gatilho+efeito+isActive
  repositories/
    database_helper.dart        ← singleton sqflite — versão atual: 11
    desktop_database_init.dart  ← ativa FFI em Windows/Linux (no-op em Android)
    tracker_repository.dart     ← CRUD completo: grupos, personagens, stats, skills
  services/
    export_service.dart     ← export/import JSON (inclui templates+habilidades)
    icon_image_store.dart   ← fotos seguras (grupo E personagem): valida dimensões,
                              re-codifica PNG interno; gera avatar do exemplo
    seed_service.dart       ← mapa de exemplo do Rise of Kingdoms (4 sub-grupos)
  theme/
    app_theme.dart          ← tema Material 3 com dark mode
  ui/
    character_screen.dart   ← tela do personagem: stats dinâmicos, star rank, nível
    game_screen.dart        ← tela do grupo: lista de personagens com filtro por categoria
    home_screen.dart        ← lista de jogos/grupos raiz (foto de grupo)
    skill_tree_screen.dart  ← árvore de habilidades/pesquisa
    stats_screen.dart       ← tela exclusiva do modelo de status (categorias)
    widgets/
      star_rank_display.dart
      stat_tile.dart        ← + boostedValue (bônus de habilidades ativas)
      stat_form_dialog.dart ← dialog compartilhado status/template (+categoria)
      group_icon.dart       ← foto do grupo com fallback emoji
android/
  app/src/main/
    AndroidManifest.xml
    kotlin/.../MainActivity.kt
windows/                    ← runner desktop (gerado 2026-07-23; título "Hero Tracker")
test/
  widget_test.dart          ← smoke test: HomeScreen carrega do banco (FFI)
```

### Schema do banco (versão 11 — fonte da verdade: `database_helper.dart`)

```
Tabelas atuais (v11):
  game_groups            ← + iconImagePath (v5)
  characters             ← type/level/star + iconImagePath (v10);
                           characterType vira legado na Fase 9 do roadmap
  character_stats        ← tipos: number|percent|trigger|formula ("count" removido na v8)
  group_stat_templates   ← modelo de status por grupo (v6) + category (v7)
  skill_nodes            ← árvore simples (ganha dono/níveis nas Fases 7-8)
  character_abilities    ← habilidades de herói (v9): descrição+gatilho+efeito+isActive
  unit_type_labels       ← nome/emoji que CADA JOGO dá aos 3 tipos (v11).
                           O enum CharacterType continua interno; só a EXIBIÇÃO
                           muda. Herda do ancestral (getEffectiveTypeNames).

Migrations incrementais (onUpgrade):
  v1→v2 parentId/skill_nodes/formulaText · v2→v3 characterType+squad
  v3→v4 level+contentCategory · v4→v5 iconImagePath · v5→v6 group_stat_templates
  v6→v7 category (guard PRAGMA) · v7→v8 count→number · v8→v9 character_abilities
  v9→v10 characters.iconImagePath (foto de herói/tropa)
  v10→v11 unit_type_labels (renomear tipo de unidade por jogo, sem código)
Próximas (roadmap v2): targetStatId · game_triggers · tags ...

⚠️ Fotos: grupo E personagem gravam PNG na MESMA pasta interna (group_icons/).
   A varredura de órfãos SÓ pode usar TrackerRepository.getAllIconImagePathsInUse()
   — passar só uma das listas apagaria as fotos da outra.
```

<details>
<summary>Schema v4 histórico (obsoleto — só referência)</summary>

### (histórico) Schema na versão 4

```sql
-- Schema atual (o _onCreate cria direto na v4)
CREATE TABLE game_groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parentId INTEGER,                                  -- v2
  name TEXT NOT NULL,
  description TEXT,
  iconEmoji TEXT DEFAULT '⚔️',
  createdAt TEXT NOT NULL,
  maxHeroesPerSquad INTEGER,                         -- v3
  maxCommandersPerSquad INTEGER,                     -- v3
  contentCategory TEXT NOT NULL DEFAULT 'general'    -- v4
);

CREATE TABLE characters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  groupId INTEGER NOT NULL,
  name TEXT NOT NULL,
  role TEXT, notes TEXT,
  starStars INTEGER DEFAULT 0,
  starSubLevel INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL,
  characterType TEXT DEFAULT 'soldadoNormal',        -- v3
  level INTEGER NOT NULL DEFAULT 1                   -- v4
);

CREATE TABLE character_stats (..., formulaText TEXT /* v2 */);
CREATE TABLE skill_nodes (...);                      -- v2

-- Migrations incrementais no onUpgrade:
-- v1→v2: game_groups.parentId + tabela skill_nodes + character_stats.formulaText
-- v2→v3: characters.characterType + game_groups.maxHeroesPerSquad/maxCommandersPerSquad
-- v3→v4: characters.level + game_groups.contentCategory
```

</details>

---

## 🛡️ LEIS INVIOLÁVEIS

```
L1: nunca-tocar-no-que-funciona → helper AO LADO + fallback
L2: sqflite → schema versionado com migrations (onUpgrade INCREMENTAL)
L3: sem-vibe-coding → planejar antes de implementar feature não-trivial
L4: 1 sprint por chat → nunca implementar tudo de uma vez
L5: widget-test → todo widget novo tem teste mínimo em test/
L6: SEMPRE português nas respostas ao usuário
L7: NUNCA commitar sem autorização explícita do usuário
```

---

## 🔄 WORKFLOW DE MUDANÇA

```
1. PLANO     → descrever o que vai mudar antes de agir. Aguardar OK.
2. MUDANÇA   → Edit/Write minimalista (helper AO LADO se possível)
3. MIGRATION → se mexer no schema: incrementar versão + onUpgrade no DatabaseHelper
4. BUILD     → flutter build apk --debug (verificar que compila)
5. COMMIT    → só commita com aprovação do usuário
```

**Comandos úteis:**
```powershell
# Rodar como app de PC (Windows) — fluxo atual de testes
flutter run -d windows

# Build release Android
.\BUILD_APK.bat

# Instalar no celular
.\INSTALAR_CELULAR.bat

# Commit + push
.\COMMIT_PUSH_HERO.bat
```

---

## 📌 Fases do projeto

```
Sprint 1 ✅ — Modelos base: GameGroup, Character (type + starRank), CharacterStat (5 tipos),
              SkillNode — commit ff65d7e
Sprint 2 ✅ — CharacterType (soldado/herói/comandante) + config de esquadrão — commit f203611
Sprint 3 ✅ — level no Character + ContentCategory no GameGroup + filtro de categoria na UI
Sprint 3.5 ✅ — Porte desktop Windows (2026-07-23): windows/ runner + sqflite_common_ffi
              (helper desktop_database_init.dart) + banco em %APPDATA% + smoke test.
Sprint 3.6 ✅ — Foto de grupo segura (IconImageStore, v5) — 2026-07-23/24
Sprint 3.7 ✅ — Modelo de status: templates por grupo (v6) + tela exclusiva com
              categorias (v7) + caixinhas na criação + fluxo modelo-primeiro
Sprint 3.8 ✅ — Contagem removida (v8) + Habilidades de herói (v9): descrição +
              gatilho + efeito + toggle de bônus — 2026-07-24
Sprint 3.9 ✅ — Mapa de exemplo do RoK (SeedService) + tela "Testes do app"
              (auto-verificada) + FOTO DE HERÓI/TROPA (v10) — 2026-07-25
Sprint 3.10 ✅ — Correção do dono: comandante NÃO tem Ataque/Defesa/Vida (é das
              tropas) + NOMES DOS TIPOS editáveis por jogo (v11, contrato JSON
              v3) + status em 1/2/3 colunas na tela do herói — 2026-07-25

DAQUI EM DIANTE: seguir docs/ROADMAP.md (v2, APROVADO 2026-07-24) — 14 fases +
extra de fórmulas, rumo à visão PROD (mapeador de jogos → comparador → contrato
JSON). Fases 1+2 aprovadas para a próxima sessão. Fase a fase com OK do dono.
```

---

## 🔤 Regras de operação

1. **PLN_1ST**: plano antes de ação para tarefas não-triviais. Aguarda OK.
2. **NO_GIT** sem autorização: `commit`, `push` exigem comando direto do usuário.
3. **DART_FIRST**: preferir soluções Flutter/Dart puras.
4. **SEMPRE português** nas respostas.
5. **MIGRATION_FIRST**: qualquer mudança de schema → incrementar `_kDbVersion` + `onUpgrade`.
6. **ENXUTO**: resposta no chat segue o caveman `full` (skill CAVE) — código,
   comentário, doc e memória continuam em português normal. Comando barulhento
   (flutter test/analyze/build) roda por `bash scripts/enxuto.sh <comando>`.
