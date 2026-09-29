# 📋 Relatório Final — Hero Tracker: do estado atual à visão

---

## 📊 Como o app está hoje

O app funciona e a fundação é boa: grupos hierárquicos com foto segura, modelo de status por grupo (com herança), personagens com caixinhas de status, habilidades de herói e uma árvore de skills simples — tudo offline, schema v9 com migrations corretas e 11 testes passando.

Mas há três verdades desconfortáveis: **(1)** o backup perde dados hoje — o export/import não inclui as árvores de skills e, pior, não existe NENHUM botão de export/import na interface (o recurso é invisível para o usuário); **(2)** a ação mais frequente do app (ajustar um valor de status) custa 3 toques + digitação, sendo que os botões +/- já existem prontos no widget e nunca foram ligados; **(3)** da visão, só foto-em-grupos está pronta — árvore com níveis, tipos flexíveis, governante, facções e temas não existem em nenhuma forma. A árvore atual é um liga/desliga binário, os tipos de unidade são um enum fixo de jogo de estratégia, e o tema é um dark único com cores hardcoded em dezenas de lugares.

---

## 🎯 O que falta para a visão

| Gap | Tamanho | Dependências |
|---|---|---|
| Bateria de testes automática + gate (TESTAR.bat) | P | nenhuma |
| Backup completo (skill_nodes no export) + botões na UI | P | nenhuma |
| Poucos cliques: +/- inline, ações no card, sub-grupo editável, undo | M | nenhuma |
| Árvore de pesquisa com NÍVEIS e requisitos por nível (visão 1) | **G** | teste de migração pronto |
| Habilidade apontar para status por ID (não por nome) | P | entra em qualquer migração |
| Tipos de unidade flexíveis por jogo (visão 3) | **G** | teste de migração pronto |
| Governante com árvore própria (visão 2) | M | árvore c/ níveis + tipos flexíveis |
| Facções amigo/inimigo (visão 4) | P/M | nenhuma |
| Foto em personagens/facções (visão 5) | P/M | estender varredura de órfãos NO MESMO commit |
| Temas: padrão + editável (visão 6) | M | trocar cores literais por tokens do tema |
| Formulários modernos + padrão único de editar/deletar (visão 7) | M | melhor depois dos tipos flexíveis |

**P** = pequeno (1-2 dias) · **M** = médio (1 sprint) · **G** = grande (1 sprint cheio, em branch)

---

## 🗺️ Roadmap por FASES

> Cada fase = 1 sprint aprovável (L4). Fases 4, 5 e 6 nascem em **branch** (coisa nova grande).
> Ordem: primeiro o que protege os dados e os testes, depois os ganhos rápidos de UI, depois a visão.

---

### Fase 1 — Rede de segurança 🛡️
**Objetivo:** nenhuma mudança futura quebra o app sem um teste gritar antes.
**Mudanças:**
- `TESTAR.bat` + `testes.ps1`: roda `flutter analyze --fatal-infos` + `flutter test`; falhou = exit ≠ 0. `COMMIT_PUSH_HERO.bat` chama TESTAR antes e aborta se falhar.
- Teste de **paridade de migração**: banco criado do zero na v9 == banco migrado v1→v9 (mesmas tabelas/colunas), incluindo o caminho v5→v7 (guard do PRAGMA).
- `PRAGMA foreign_keys = ON` movido para `onConfigure` do `openDatabase` (hoje só liga dentro de 2 deletes — comportamento muda conforme o histórico da sessão).
- Teste round-trip `toMap/fromMap` de todos os modelos + teste do ciclo de parentId em `getEffectiveTemplates`.
- Trocar os `Future.delayed` fixos dos testes por polling curto (helper `pumpUntilFound`).
- Atualizar o CLAUDE.md (descreve schema v2; o real é v9).
**Migração:** nenhuma.
**Aceitação:** `TESTAR.bat` roda em <60s e bloqueia commit quebrado; teste de paridade passa; apagar nó pai no início da sessão deixa filhos com `parentId` NULL (FK funcionando sempre).

---

### Fase 2 — Backup de verdade 💾
**Objetivo:** o usuário consegue fazer backup pela tela, e o backup não perde nada.
**Mudanças:**
- Incluir `skill_nodes` no export/import com remapeamento id-antigo→id-novo (mesmo padrão já usado para parentId de grupos). **Isso é um bug de perda de dados hoje.**
- Extrair `buildExportJson()` de `exportAll()` (separar montagem do JSON do plugin de share — vira testável).
- Menu ⋮ na Home com "Exportar dados" e "Importar dados" (2 toques para backup).
- Testes: round-trip completo (grupos+personagens+stats+habilidades+templates+nós), pai ausente vira raiz, JSON lixo não estoura, iconImagePath não entra no import.
**Migração:** nenhuma (bump do `version` do JSON de export para 2).
**Aceitação:** exportar → importar em banco limpo reproduz contagens e hierarquia, incluindo a árvore; botões visíveis e funcionando no aparelho.

---

### Fase 3 — Poucos cliques onde dói 👆
**Objetivo:** as ações do dia a dia caem de 3-4 toques para 1-2.
**Mudanças:**
- Ligar `onIncrement/onDecrement` do StatTile (já existem prontos e não conectados) para stats number/count — ajustar valor vira 1 toque, sem dialog.
- Botão "+" de nível direto no card do personagem na lista (subir nível: de 4 toques para 2).
- Botão "−1 sub" nas estrelas (hoje só existe +1 sub, erro não tem volta).
- Deletar status/habilidade: apagar direto + SnackBar "Desfazer" (hoje apaga sem confirmação num ícone de 16px).
- Sub-grupo deixa de ser beco sem saída: mesmo PopupMenu Editar/Deletar da Home, reusando o `_GroupDialog` (com foto) extraído para `widgets/` — um único caminho de CRUD de grupo.
- Smoke de widget das 2 telas grandes (GameScreen e CharacterScreen abrem e listam dados semeados) — rede de proteção para as fases 4-6.
**Migração:** nenhuma.
**Aceitação:** subir "Ataque" de 120→121 = 1 toque; renomear sub-grupo funciona; delete acidental de status recuperável em 1 toque; smokes passando.

---

### Fase 4 — Árvore com níveis e requisitos 🌳 *(branch)*
**Objetivo:** a árvore representa pesquisa real: "nível 3/10, e o nível 4 exige X".
**Mudanças:**
- SkillNode ganha `currentLevel`/`maxLevel`; `isUnlocked` vira derivado (`currentLevel > 0`).
- Nova tabela `skill_node_levels` (nodeId, level, requirementText livre, isDone) — requisito por nível como TEXTO, sem grafo tipado.
- UI: card mostra "3/10" com +/- de 1 toque; toque longo abre os requisitos do próximo nível; nó ganha edição (dialog aceita `initial` — hoje typo = deletar e recriar o ramo).
- Aproveitar a migração: `character_abilities.targetStatId` com backfill por nome (habilidade passa a apontar por ID; renomear status não quebra mais o bônus).
**Migração:** v10 — `ADD COLUMN currentLevel/maxLevel` + `UPDATE currentLevel = isUnlocked` + `CREATE TABLE skill_node_levels` + `targetStatId` com backfill.
**Aceitação:** nó desbloqueado da v9 vira 1/1 (teste de migração com banco v9 real); nó maxLevel=1 se comporta exatamente como hoje; renomear status mantém o efeito da habilidade; export/import inclui os níveis.

---

### Fase 5 — Tipos de unidade por jogo 🎭 *(branch)*
**Objetivo:** cada jogo cria seus próprios tipos ("Arqueiro", "Dragão"), sem enum fixo.
**Mudanças:**
- Tabela `unit_types` por grupo (name, emoji, entersBattle, hasAbilities, maxPerSquad, sortOrder) + `characters.unitTypeId` (nullable).
- Seed na migração: 3 tipos padrão por grupo raiz existente + backfill de todos os personagens; `maxHeroesPerSquad/maxCommandersPerSquad` copiados para `maxPerSquad` dos tipos (fim do dado em dois lugares — colunas antigas viram fósseis, nunca mais lidas).
- UI lê tipos do banco: seletor no dialog de personagem, contadores de esquadrão por tipo, seção de habilidades liberada pela flag `hasAbilities`. Textos hardcoded de estratégia ("👑 Não entra em batalha") saem da UI genérica.
- Ao mexer na game_screen (1247 linhas), extrair dialog de personagem e card para `widgets/` (L1).
**Migração:** v11 — `CREATE TABLE unit_types` + seed + `ADD COLUMN unitTypeId` + backfill. `unitTypeId` NULL cai no enum legado (fallback L1).
**Aceitação:** personagens existentes mantêm o tipo após migrar (teste); criar "Mago" num jogo novo e usar; contadores de esquadrão funcionam por tipo; export/import inclui unit_types.

---

### Fase 6 — Governante com árvore própria 👑 *(branch)*
**Objetivo:** o governante tem sua árvore de habilidades pessoal, separada da pesquisa do grupo.
**Mudanças:**
- `skill_nodes.ownerCharacterId` (nullable): NULL = árvore do grupo (dados atuais intactos), preenchido = árvore pessoal. **Mesmo motor, mesma tela** — SkillTreeScreen ganha filtro opcional.
- Governante = Character com unit_type marcado `hasOwnTree` (criado na fase 5 — nenhuma entidade nova).
- CRÍTICO no mesmo commit: `getSkillNodes(groupId)` filtra `ownerCharacterId IS NULL` (senão a árvore do governante vaza na tela do grupo).
- CharacterScreen: tipo com árvore própria mostra botão "Árvore de habilidades".
**Migração:** v12 — `ADD COLUMN ownerCharacterId` (sem backfill).
**Aceitação:** árvore do grupo idêntica antes/depois (teste); criar governante, abrir árvore dele, nós não aparecem na árvore do grupo e vice-versa.

---

### Fase 7 — Facções 🚩
**Objetivo:** RPG consegue marcar amigo/inimigo/facção em qualquer personagem.
**Mudanças:**
- Tabela `factions` (groupId, name, disposition amigo|inimigo|neutro, emoji, iconImagePath, sortOrder) + `characters.factionId` (nullable — jogos de estratégia ignoram sem custo).
- Chip de filtro por facção na GameScreen + cor/emoji da facção no card. Deletar facção zera `factionId` dos personagens (no repositório).
**Migração:** v13 — `CREATE TABLE factions` + `ADD COLUMN factionId`. Zero backfill.
**Aceitação:** criar facção "Inimigos", atribuir a um personagem, filtrar por ela; personagem sem facção continua normal; export/import inclui facções.

---

### Fase 8 — Foto em tudo 📸
**Objetivo:** personagem (e facção) com foto, pelo mesmo pipeline seguro dos grupos.
**Mudanças:**
- `characters.iconImagePath` + reusar `GroupIcon` no lugar do emoji do tipo.
- **NO MESMO commit** (senão perde dados): `getAllIconImagePaths` vira UNION de game_groups + characters + factions — hoje a varredura de órfãos do boot apagaria toda foto de personagem.
- Deletar personagem chama `deleteIcon` (como a Home já faz para grupos); import continua descartando paths.
- Testes do IconImageStore que faltam: deleteIcon recusa caminho fora da pasta (path traversal), arquivo falso não importa, cleanupOrphans preserva foto referenciada de personagem.
**Migração:** v14 — `ADD COLUMN iconImagePath` em characters.
**Aceitação:** foto no card do personagem; reiniciar o app N vezes não apaga a foto (teste do cleanup); testes de segurança do store passando.

---

### Fase 9 — Temas 🎨
**Objetivo:** usuário escolhe a aparência; padrão continua o dark dourado.
**Mudanças:**
- Passo 1 (mecânico): trocar `Colors.grey.shadeX`/`white12` literais pelos tokens de `Theme.of(context).colorScheme` — sem isso, qualquer tema claro quebra contraste em todo lugar.
- `ThemeController` (ValueNotifier) lendo de shared_preferences (declarado no pubspec e nunca usado): seedColor + claro/escuro. Tela de configurações mínima: 6-8 presets de cor + toggle. "Restaurar padrão" = remover as chaves.
- Embutir a fonte Nunito como asset (remove dependência de rede — 100% offline de verdade) e trocar o smoke para bootar o widget raiz REAL do main.dart.
**Migração:** nenhuma (temas ficam FORA do banco).
**Aceitação:** trocar tema, fechar e reabrir o app → tema persiste; modo claro legível em todas as telas; smoke boota o app real.

---

### Fase 10 — Formulários e consistência ✨
**Objetivo:** uma gramática só de interação em todo o app, formulários que cabem na tela.
**Mudanças:**
- Formulários grandes (personagem, status) migram de AlertDialog rolável para bottom sheet full-width (teclado convive, SegmentedButton respira).
- Um padrão único de editar/deletar (hoje são 3: popup-menu, lápis+lixeira 32px, "X"); alvos de toque ≥48dp.
- AppBar da GameScreen: só FAB + 1 menu ⋮ (esquadrão, template, sub-grupo); Árvore vira card visível no corpo. Chips de categoria passam a filtrar tudo ou saem.
- Wizard "Novo jogo" em tela única: nome/foto → estrutura padrão → status iniciais em chips prontos (de ~20 toques para ~6).
**Migração:** nenhuma.
**Aceitação:** criar jogo completo ≤ 8 toques; formulário de status legível em tela estreita; nenhum "X" significando deletar.

---

## ✂️ O que NÃO fazer

1. **Grafo tipado de requisitos** na árvore (nó X exige nó Y nível Z com validação automática). Texto livre por nível resolve 100% do caso de uso; o app é um tracker, não um simulador do jogo.
2. **Segundo motor de árvore para o governante.** Uma coluna nullable no `skill_nodes` existente resolve — mesma tabela, mesma tela.
3. **Tabela de relações entre facções** (X odeia Y). `disposition` simples (amigo/inimigo/neutro) cobre a visão. Se um dia precisar, é outra fase.
4. **DROP COLUMN / reescrever tabelas** para limpar `characterType` e `maxHeroesPerSquad` antigos. Colunas fósseis não lidas são inofensivas; reescrever tabela no SQLite é onde se perde dado de usuário (L1).
5. **Editor de tema completo** (cor por cor, fonte por fonte). Presets + claro/escuro entrega 90% do valor com 10% do esforço. Tema no SQLite: não — shared_preferences é a fonte única de config.
6. **Sync automático template→stats existentes.** A cópia unidirecional atual está correta e documentada; "reaplicar template" só como ação explícita do usuário, nunca automática.
7. **Perseguir cobertura de linha nos testes.** Smokes de fluxo crítico + paridade de migração + round-trip de backup protegem o que importa; o resto é burocracia.
8. **Todas as migrações numa versão só.** Uma versão de schema por fase (v10…v14), cada bloco `if (oldV < N)` independente — é o que permite aprovar/pausar fase a fase.
9. **Reescrever as telas grandes de uma vez.** Extrair widgets da game_screen só quando a fase já for mexer nela (fase 5), nunca como "refatoração geral".
10. **Pacotes novos de terceiros.** Tudo acima é Dart puro + o que já está no pubspec.


---

## 🔧 Ajustes do crítico anti-complexidade (incorporados — valem sobre o texto acima)

1. **Smoke de boot do app REAL sobe para a Fase 1** (rede de segurança desde o início; na Fase 9 fica só o tema).
2. **Fase 4**: cortar a coluna `isDone` de `skill_node_levels` (nível concluído deriva de `currentLevel >= level` — caminho único); a tabela vira só (nodeId, level, requirementText).
3. **Fase 7**: NÃO criar `factions.iconImagePath` na v13 — foto de facção entra na Fase 8 junto com a varredura de órfãos (senão o boot apagaria as fotos). Fase 7 também nasce em **branch** (coisa nova).
4. **Fase 5**: definir seed de tipos padrão TAMBÉM na criação de grupo novo (não só na migração), senão grupo novo nasce sem tipos.
5. **Fase 6**: export/import remapeia `ownerCharacterId` id-antigo→id-novo (mesmo padrão do parentId), senão backup corrompe a árvore do governante.
6. **Fase 10**: sem conteúdo curado por jogo no wizard (chips genéricos apenas); decisão fechada: chips de categoria SAEM da GameScreen.
7. **Aceitação permanente (todas as fases)**: import aceita backup de QUALQUER versão anterior do JSON.
8. **Explícito no "não fazer"**: foto NÃO entra em tipos de unidade nem nós da árvore (só grupos, personagens e facções) — anti-complexidade consciente.

---

## 📌 Adendo (2026-07-24, tarde) — decisões do dono que ajustam o roadmap

O objetivo oficial virou a skill **PROD** (`hero-tracker-produto` no kit): o app
é um **MAPEADOR de jogos** que alimenta um 2º app de teste no futuro. Ajustes:

1. **Fase 4 (árvore)** ganha: pré-requisitos OBRIGATÓRIOS entre itens ("o que é
   obrigado antes") + custos de RECURSOS por item/nível — em forma de árvore.
2. **Fase nova A — Gatilhos nomeados reutilizáveis**: lista de gatilhos por
   jogo; qualquer herói reutiliza; uma habilidade pode usar VÁRIOS gatilhos.
   (Substitui o texto-livre atual; encaixar após a Fase 4 ou junto dela.)
3. **Fase nova B — Comparador de heróis**: selecionar 2+ heróis e ver os boosts
   SOMADOS que dão juntos naquele momento. É o coração do "para quê" do app —
   priorizar logo após as fases 4-6.
4. **Fase 2 (backup) ganha requisito permanente**: o JSON é CONTRATO OFICIAL
   para o app de teste futuro — documentado, versionado, com limites explícitos
   e validação rígida (impossível vírus/hack pelo arquivo).
5. **Fase nova C — Presets/conjuntos**: pacotes reutilizáveis criados pelo
   usuário (herói+habilidades; conjuntos de itens por jogo; padrão
   "comandante" que evolui por passos e dá boosts). Depois das fases 4-6.
6. **Dúvida FECHADA pelo dono (2026-07-24)**: árvores são VÁRIAS POR JOGO
   (cada jogo tem as suas) E heróis também têm árvores — 1 por TAG de tropa do
   herói (ex.: defesa, tropa mista — como talentos de comandante do RoK).
   Habilidade usa de 0 a MUITOS gatilhos; lista de gatilhos é POR JOGO.
   → Impacto: Fase 4 modela árvore com "dono" (jogo OU herói via tag); Fase 5
   (tipos de unidade) ganha o conceito de TAGs de tropa; Fase 6 (governante)
   vira caso particular desse mesmo mecanismo.
