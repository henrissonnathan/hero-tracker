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
  segundo-cerebro-obsidian       | CERE   | obsidian|vault|/segundo-cerebro             | PKM pessoal (manual, nunca em sessão de código)

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

### Propósito
Tracker para entusiastas de jogos estratégicos mobile (RoK, Fate War, AoC, etc.)
que precisam planejar builds de heróis, progressão de tropas, árvores de pesquisa
e níveis de construção — tudo em um só lugar, 100% offline/local.

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
                              characterType, level (v2), groupId
    character_stat.dart     ← atributo dinâmico — tipo: count/percent/number/trigger/formula
    character_type.dart     ← enum: soldadoNormal | heroi | comandante
    content_category.dart   ← enum: heroes | troops | research | building | general (v2)
    game_group.dart         ← grupo/jogo — tem: name, iconEmoji, parentId, maxHeroesPerSquad,
                              maxCommandersPerSquad, contentCategory (v2)
    skill_node.dart         ← nó de árvore de habilidades/pesquisa
    star_rank.dart          ← rank com estrelas + sub-níveis (8 sub/estrela)
    stat_type.dart          ← enum: count | percent | number | trigger | formula
  repositories/
    database_helper.dart        ← singleton sqflite — versão atual: 4
    desktop_database_init.dart  ← ativa FFI em Windows/Linux (no-op em Android)
    tracker_repository.dart     ← CRUD completo: grupos, personagens, stats, skills
  services/
    export_service.dart     ← exportação de dados
  theme/
    app_theme.dart          ← tema Material 3 com dark mode
  ui/
    character_screen.dart   ← tela do personagem: stats dinâmicos, star rank, nível
    game_screen.dart        ← tela do grupo: lista de personagens com filtro por categoria
    home_screen.dart        ← lista de jogos/grupos raiz
    skill_tree_screen.dart  ← árvore de habilidades/pesquisa
    widgets/
      star_rank_display.dart
      stat_tile.dart
android/
  app/src/main/
    AndroidManifest.xml
    kotlin/.../MainActivity.kt
windows/                    ← runner desktop (gerado 2026-07-23; título "Hero Tracker")
test/
  widget_test.dart          ← smoke test: HomeScreen carrega do banco (FFI)
```

### Schema do banco (versão 4 — fonte da verdade: `database_helper.dart`)

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
              Pendentes desktop: fonte Nunito offline, wrapper de largura, export FilePicker
Sprint 4 🔜 — Fórmulas calculadas (StatType.formula avaliador)
Sprint 5 🔜 — Bônus de comandante propagado para o esquadrão
Sprint 6 🔜 — Tela de Build Summary (stats + skills planejados em uma tela)
Sprint 7 🔜 — Polimento + Play Store
```

---

## 🔤 Regras de operação

1. **PLN_1ST**: plano antes de ação para tarefas não-triviais. Aguarda OK.
2. **NO_GIT** sem autorização: `commit`, `push` exigem comando direto do usuário.
3. **DART_FIRST**: preferir soluções Flutter/Dart puras.
4. **SEMPRE português** nas respostas.
5. **MIGRATION_FIRST**: qualquer mudança de schema → incrementar `_kDbVersion` + `onUpgrade`.
