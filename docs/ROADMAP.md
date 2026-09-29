# 🗺️ ROADMAP v2 — Hero Tracker: do estado atual à visão PROD

> Substitui o roadmap v1 (feito antes da visão completa). Replanejado em 2026-07-24
> à luz da skill PROD (`hero-tracker-produto`). Cada fase = 1 sprint aprovável (L4).

## 🎯 Norte

O hero-tracker é um **mapeador de jogos**: qualquer pessoa, sem programar, mapeia números, bônus, gatilhos, habilidades e árvores de um jogo — e usa esse mapa para **comparar builds de heróis** (o "para quê" de tudo).
O JSON exportado é o **contrato oficial** que vai alimentar o 2º app (teste/simulação): documentado, versionado, com validação rígida.

## Regras permanentes (valem em TODAS as fases)

- **1 migração por fase** (v10 → v17), sempre aditiva com fallback (L1/RAUX). Coluna antiga vira fóssil não lido — nunca DROP, nunca reescrever tabela.
- **Dados v9 intactos**: toda fase de schema tem teste de migração com banco v9 real.
- **Contrato JSON**: toda fase que muda o export atualiza `docs/CONTRATO-JSON.md` e o número de versão. O import aceita backup de **qualquer versão anterior**, para sempre.
- **TESTAR.bat verde antes de qualquer commit** (L7). Coisa nova grande nasce em **branch**.

## Tabela-resumo

| Nº | Fase | Tamanho | Branch | Migração |
|----|------|---------|--------|----------|
| 1 | Rede de segurança *(aprovada)* | P | não | — |
| 2 | Backup de verdade + contrato JSON *(aprovada)* | M | não | — (JSON v2) |
| 3 | Comparador de heróis v1 — o coração | M | sim | v10 |
| 4 | Gatilhos por jogo — comparador situacional | M | sim | v11 |
| 5 | Poucos cliques onde dói | M | não | — |
| 6 | Tags de tropa | P | sim | v12 |
| 7 | Árvores com DONO (jogo ou herói via tag) | G | sim | v13 |
| 8 | Níveis, pré-requisitos e custos na árvore | M | sim | v14 |
| 9 | Tipos de unidade por jogo (enxutos) | M | sim | v15 |
| 10 | Presets por duplicação | P | não | — |
| 11 | Facções | P | sim | v16 |
| 12 | Foto em tudo | M | não | v17 |
| 13 | Temas | M | não | — |
| 14 | Formulários e consistência | M | não | — |

---

### Fase 1 — Rede de segurança *(aprovada — mantida como está)*

**Objetivo:** nenhuma mudança futura quebra o app sem um teste gritar antes.

**Mudanças:**
- `TESTAR.bat` + `testes.ps1`: `flutter analyze --fatal-infos` + `flutter test`; falhou = exit ≠ 0. `COMMIT_PUSH_HERO.bat` chama TESTAR antes e aborta se falhar.
- Teste de **paridade de migração**: banco criado do zero na v9 == banco migrado v1→v9 (mesmas tabelas/colunas), incluindo o caminho v5→v7.
- `PRAGMA foreign_keys = ON` movido para `onConfigure` do `openDatabase`.
- Round-trip `toMap/fromMap` de todos os modelos + teste do ciclo de parentId em `getEffectiveTemplates`.
- Trocar `Future.delayed` fixos dos testes por polling curto (helper `pumpUntilFound`).
- Smoke de boot do widget raiz REAL do `main.dart`.
- Atualizar o CLAUDE.md (descreve schema antigo; o real é v9).

**Migração:** nenhuma.

**Aceitação:**
- `TESTAR.bat` roda em <60s e bloqueia commit quebrado.
- Teste de paridade v1→v9 passa.
- Apagar nó pai no início da sessão deixa filhos com `parentId` NULL (FK sempre ligada).

---

### Fase 2 — Backup de verdade + JSON como contrato oficial *(aprovada — mantida como está)*

**Objetivo:** backup pela tela sem perder nada, e o JSON vira o contrato documentado e versionado que o 2º app vai consumir.

**Mudanças:**
- Incluir `skill_nodes` no export/import com remapeamento id-antigo→id-novo (**bug de perda de dados hoje**).
- Extrair `buildExportJson()` de `exportAll()` — montagem do JSON separada do plugin de share, testável.
- Menu na Home com "Exportar dados" / "Importar dados" (backup em 2 toques).
- Contrato oficial: `docs/CONTRATO-JSON.md` com formato, campo de versão (= 2), limites explícitos e validação rígida no import (JSON lixo nunca estoura nem entra no banco; `iconImagePath` descartado).
- Instaura a regra permanente: import aceita backup de QUALQUER versão anterior do JSON.
- Testes: round-trip completo (grupos+personagens+stats+habilidades+templates+nós), pai ausente vira raiz, JSON malformado rejeitado com mensagem genérica.

**Migração:** nenhuma (versão do JSON de export vai para 2).

**Aceitação:**
- Exportar → importar em banco limpo reproduz contagens e hierarquia, incluindo a árvore.
- Botões visíveis e funcionando no aparelho.
- Arquivo adulterado/malformado é rejeitado sem crash e sem sujar o banco; a doc bate com o export real.

---

### Fase 3 — Comparador de heróis v1 — o coração *(branch)*

**Objetivo:** selecionar 2+ heróis e ver os **boosts somados** que dão juntos — o "para quê" do mapeamento, entregue 1 sprint depois do backup com os dados que o app já tem (`character_abilities` v9 já carrega valor, tipo flat/% e ativo/inativo).

**Mudanças:**
- Migração v10: `character_abilities.targetStatId` (nullable) com backfill por nome; leitura prefere o ID com fallback por nome (L1) — renomear um status não quebra mais o efeito. Entra JÁ nesta fase para o comparador nunca depender de casamento por nome (evita reescrita futura).
- Nova `ComparadorScreen`: seleção de heróis do jogo (chips/checkbox) → boosts somados agrupados por status-alvo — percentuais somam com percentuais (+10% +15% = +25%), valores fixos com fixos, com o valor base atual como contexto.
- Motor de soma em função Dart **pura** (testável sem UI), reusando a lógica de bônus já existente na tela do personagem.
- Toggle "só habilidades ativas" vs "todas" (`isActive` já existe).
- Entrada: botão "Comparar heróis" na GameScreen.
- Export/import inclui `targetStatId` com remap; bump do contrato documentado.

**Migração:** v10 — `ADD COLUMN targetStatId` em `character_abilities` + backfill por nome.

**Aceitação:**
- Escolher 2 heróis e ver a soma correta por status (teste unitário do motor: flat vs percent, habilidade sem alvo ignorada).
- Renomear um status mantém o efeito da habilidade apontando certo.
- Banco v9 real migra sem perda (paridade continua verde); herói sem habilidades soma zero sem erro.

---

### Fase 4 — Gatilhos por jogo — o comparador fica situacional *(branch)*

**Objetivo:** a lista de gatilhos pertence ao JOGO e a habilidade usa de 0 a N deles; o comparador passa a responder "quanto boost temos **nesta situação**" — a segunda metade do coração.

**Mudanças:**
- Tabelas `game_triggers` (jogo raiz, name, sortOrder) e `ability_triggers` (N:N habilidade↔gatilho).
- Backfill: `triggerText` preenchido vira gatilho do jogo (deduplicado por nome), já ligado à habilidade; a coluna antiga vira fóssil de leitura (fallback L1).
- UI da habilidade: chips de gatilhos do jogo, reutilizáveis, com criar novo inline; a habilidade mantém as duas partes da visão — texto livre + efeito configurado; 0 gatilhos é válido.
- Comparador ganha seletor de situação: habilidade com gatilhos só entra na soma se todos os seus gatilhos estiverem ligados; sem gatilho, conta sempre.
- Export/import inclui gatilhos e vínculos com remap; bump do contrato.

**Migração:** v11 — `CREATE TABLE game_triggers` + `ability_triggers` + backfill a partir de `triggerText`.

**Aceitação:**
- Criar gatilho no jogo ("defendendo a base") e reusar em habilidades de 2 heróis diferentes.
- Mudar a situação muda a soma; habilidade sem gatilho conta em qualquer situação.
- Habilidades antigas com `triggerText` migram sem perda (teste com banco real).

---

### Fase 5 — Poucos cliques onde dói

**Objetivo:** mapear fica rápido — as ações do dia a dia caem de 3-4 toques para 1-2 (velocidade de mapeamento É valor do mapeador).

**Mudanças:**
- Ligar `onIncrement/onDecrement` do StatTile (já prontos e desconectados) para stats number/count — ajustar valor vira 1 toque.
- Botão "+" de nível direto no card do personagem na lista; botão "−1 sub" nas estrelas (erro passa a ter volta).
- Deletar status/habilidade: apagar direto + SnackBar "Desfazer".
- Sub-grupo deixa de ser beco sem saída: mesmo PopupMenu Editar/Deletar da Home, com `_GroupDialog` extraído para `widgets/` — caminho único de CRUD de grupo.
- Smokes de widget da GameScreen e CharacterScreen (abrem e listam dados semeados) — rede de proteção para as fases estruturais 6-9.

**Migração:** nenhuma.

**Aceitação:**
- Subir "Ataque" de 120→121 = 1 toque.
- Renomear sub-grupo funciona; delete acidental recuperável em 1 toque.
- Smokes das 2 telas grandes passando.

---

### Fase 6 — Tags de tropa *(branch)*

**Objetivo:** vocabulário de tags por jogo ("defesa", "tropa mista") marcável em qualquer personagem — a chave que dá árvores aos heróis na Fase 7 e vira filtro no comparador.

**Mudanças:**
- Tabelas `troop_tags` (jogo, name, emoji, sortOrder) + `character_troop_tags` (N:N) — personagem tem 0..N tags; sem backfill (ninguém tem tag até o usuário marcar).
- Chips de tag no formulário/tela do personagem; deletar tag remove só os vínculos.
- Filtro por tag na GameScreen e no seletor do comparador.
- Export/import inclui tags e vínculos com remap; bump do contrato.

**Migração:** v12 — `CREATE TABLE troop_tags` + `character_troop_tags`.

**Aceitação:**
- Criar "Defesa" e "Tropa mista", marcar um herói com as 2 e filtrar por elas.
- Deletar tag não apaga personagens; personagem sem tag continua normal.
- Round-trip do backup inclui as tags.

---

### Fase 7 — Árvores com DONO — várias por jogo E por herói via tag *(branch)*

**Objetivo:** a árvore vira entidade com dono — o JOGO (várias árvores por jogo) ou um HERÓI via tag de tropa (1 árvore por tag, como os talentos de comandante do RoK); **governante deixa de ser fase própria** — é só um herói com uma tag que tem árvore, mesmo motor, mesma tela.

**Mudanças:**
- Tabela `skill_trees` (groupId, name, iconEmoji, ownerCharacterId NULL, troopTagId NULL, sortOrder): NULLs = árvore do jogo; preenchidos = árvore pessoal do herói naquela tag.
- `skill_nodes.treeId` + backfill: os nós atuais de cada grupo viram a árvore padrão "Pesquisa" — dados v9 intactos (L1).
- Mesma SkillTreeScreen para todos os donos; GameScreen lista as árvores do jogo (criar/renomear/deletar); CharacterScreen mostra 1 botão de árvore por tag do herói, criada sob demanda no primeiro acesso.
- **CRÍTICO no mesmo commit:** consultas de nós filtram por `treeId` — árvore de herói jamais vaza na tela do jogo e vice-versa.
- Export/import remapeia `treeId`/`ownerCharacterId`/`troopTagId` id-antigo→id-novo (padrão do parentId); bump do contrato.

**Migração:** v13 — `CREATE TABLE skill_trees` + `ADD COLUMN treeId` em `skill_nodes` + seed de 1 árvore "Pesquisa" por grupo com nós + backfill.

**Aceitação:**
- Árvore existente idêntica antes/depois da migração (teste com banco v9 real).
- Criar 2ª árvore no mesmo jogo e alternar; herói com tag "Defesa" ganha árvore própria — caso governante coberto sem nenhuma entidade nova.
- Nós da árvore do herói não aparecem na do jogo e vice-versa; backup preserva árvores e donos.

---

### Fase 8 — Níveis, pré-requisitos e custos na árvore *(branch)*

**Objetivo:** a árvore representa pesquisa real — "nível 3/10; o nível 4 exige X e custa Y recursos" — no formato-árvore da visão (obrigatório-antes + recursos por nível). O app registra, não impõe: tracker, não simulador.

**Mudanças:**
- `skill_nodes` ganha `currentLevel`/`maxLevel`; `isUnlocked` vira derivado (`currentLevel > 0`); migração faz `UPDATE currentLevel = isUnlocked`.
- Tabela `skill_node_levels` (nodeId, level, requirementText) — pré-requisito por nível como TEXTO livre; o "obrigatório antes" estrutural já é o **pai do nó** na árvore (sem grafo tipado, sem coluna isDone).
- Tabela `skill_node_costs` (nodeId, level, resourceName, amount) — custos de recursos por item/nível em linhas simples (o 2º app consegue consumir).
- UI: card mostra "3/10" com +/− de 1 toque; toque longo abre requisitos e custos do próximo nível; nó ganha edição (dialog aceita `initial` — fim do deletar-e-recriar).
- Export/import inclui níveis e custos; bump do contrato.

**Migração:** v14 — `ADD COLUMN currentLevel/maxLevel` + `UPDATE currentLevel = isUnlocked` + `CREATE TABLE skill_node_levels` + `skill_node_costs`.

**Aceitação:**
- Nó desbloqueado da v9 vira 1/1 (teste de migração com banco real).
- Nó maxLevel=1 comporta-se exatamente como o liga/desliga de hoje.
- Requisitos e custos do próximo nível visíveis em 1 toque longo; export inclui níveis e custos.

---

### Fase 9 — Tipos de unidade por jogo (enxutos) *(branch)*

**Objetivo:** cada jogo cria seus próprios tipos ("Arqueiro", "Dragão") — fim do enum fixo de estratégia; sai MAIS simples que no v1 porque habilidades e árvores já são de qualquer personagem (fases 3 e 7).

**Mudanças:**
- Tabela `unit_types` (jogo, name, emoji, maxPerSquad, sortOrder) + `characters.unitTypeId` nullable (NULL cai no enum legado — fallback L1). **Sem flags** entersBattle/hasAbilities/hasOwnTree: tipo é rótulo + limite de esquadrão.
- Seed de tipos padrão na migração E na criação de grupo novo (senão grupo novo nasce sem tipos); backfill dos personagens a partir do enum; `maxHeroesPerSquad`/`maxCommandersPerSquad` copiados para `maxPerSquad` (colunas antigas viram fósseis, nunca mais lidas).
- UI lê tipos do banco: seletor no dialog de personagem, contadores de esquadrão por tipo; textos de estratégia chumbados saem da UI genérica.
- Ao mexer na game_screen (1247 linhas), extrair dialog de personagem e card para `widgets/` (L1 — só porque a fase já mexe nela).
- Export/import inclui `unit_types` com remap; bump do contrato.

**Migração:** v15 — `CREATE TABLE unit_types` + seed + `ADD COLUMN unitTypeId` + backfill.

**Aceitação:**
- Personagens existentes mantêm o tipo após migrar (teste com banco real).
- Criar "Mago" num jogo novo e usar; grupo novo nasce com tipos padrão.
- Contadores de esquadrão funcionam por tipo; export inclui tipos.

---

### Fase 10 — Presets por duplicação

**Objetivo:** conjuntos prontos reutilizáveis (visão PROD) **sem entidade nova**: preset = duplicar ou exportar um pedaço, reusando o remapeador de IDs do backup da Fase 2.

**Mudanças:**
- "Duplicar herói" (stats + habilidades + vínculos de gatilho + tags + árvores pessoais) e "Duplicar grupo" — reuso direto do remapeador id-antigo→id-novo.
- "Salvar herói como arquivo" / "Importar herói": sub-formato "herói avulso" do contrato JSON, com a MESMA validação rígida do backup; ao importar em outro jogo, gatilhos/tags/status que faltarem são criados com IDs remapeados.
- O padrão "comandante que evolui por passos" vira um herói-preset duplicável (cada passo = habilidades que entram no comparador).
- O comparador compara qualquer herói — inclusive os aplicados de preset.

**Migração:** nenhuma (contrato ganha o sub-formato "herói avulso", documentado).

**Aceitação:**
- Duplicar um herói completo em 2 toques; edições no clone não afetam o original.
- Exportar herói de um jogo e importar em outro, com tudo remapeado.
- Import de herói avulso passa pela mesma validação rígida do backup.

---

### Fase 11 — Facções *(branch)*

**Objetivo:** RPG consegue marcar amigo/inimigo/facção em qualquer personagem; jogos de estratégia ignoram sem custo.

**Mudanças:**
- Tabela `factions` (groupId, name, disposition amigo|inimigo|neutro, emoji, sortOrder) + `characters.factionId` nullable — SEM iconImagePath nesta fase (foto de facção só na Fase 12, junto da varredura de órfãos).
- Chip de filtro por facção na GameScreen + cor/emoji da facção no card.
- Deletar facção zera `factionId` dos personagens (no repositório).
- Export/import inclui facções com remap; bump do contrato.

**Migração:** v16 — `CREATE TABLE factions` + `ADD COLUMN factionId` (zero backfill).

**Aceitação:**
- Criar facção "Inimigos", atribuir a um personagem e filtrar por ela.
- Personagem sem facção continua normal.
- Round-trip do backup inclui facções.

---

### Fase 12 — Foto em tudo

**Objetivo:** personagem e facção com foto, pelo mesmo pipeline seguro (armazenamento interno) dos grupos.

**Mudanças:**
- `characters.iconImagePath` + `factions.iconImagePath` e reuso do `GroupIcon` no lugar do emoji.
- **NO MESMO commit:** `getAllIconImagePaths` vira UNION de game_groups + characters + factions — senão a varredura de órfãos do boot apaga as fotos novas.
- Deletar personagem/facção chama `deleteIcon`; import continua descartando paths.
- Testes de segurança do IconImageStore que faltam: deleteIcon recusa caminho fora da pasta (path traversal), arquivo falso não importa, cleanupOrphans preserva foto referenciada de personagem.

**Migração:** v17 — `ADD COLUMN iconImagePath` em characters e factions.

**Aceitação:**
- Foto no card do personagem e da facção; reiniciar o app N vezes não apaga a foto (teste do cleanup).
- Testes de segurança do store passando.

---

### Fase 13 — Temas

**Objetivo:** usuário escolhe a aparência; padrão continua o dark dourado; app 100% offline de verdade (fonte embutida).

**Mudanças:**
- Passo mecânico: trocar cores literais (`Colors.grey`, `white12`) pelos tokens de `Theme.of(context).colorScheme`.
- `ThemeController` (ValueNotifier) lendo de shared_preferences: seedColor + claro/escuro; tela mínima com 6-8 presets + toggle; "Restaurar padrão" = remover as chaves.
- Embutir a fonte Nunito como asset (remove a dependência de rede do google_fonts).
- Temas ficam FORA do banco (shared_preferences é a fonte única de config).

**Migração:** nenhuma.

**Aceitação:**
- Trocar tema, fechar e reabrir o app → tema persiste.
- Modo claro legível em todas as telas; app boota sem rede.

---

### Fase 14 — Formulários e consistência

**Objetivo:** uma gramática só de interação em todo o app; formulários que cabem na tela; criar jogo novo em poucos toques.

**Mudanças:**
- Formulários grandes (personagem, status) migram de AlertDialog para bottom sheet full-width.
- Padrão único de editar/deletar (fim dos 3 padrões atuais); alvos de toque ≥ 48dp; nenhum "X" significando deletar.
- GameScreen enxuta: FAB + 1 menu; árvores viram cards visíveis no corpo; chips de categoria SAEM da GameScreen (decisão fechada).
- Wizard "Novo jogo" em tela única com chips GENÉRICOS apenas (sem conteúdo curado por jogo).

**Migração:** nenhuma.

**Aceitação:**
- Criar jogo completo em ≤ 8 toques.
- Formulário de status legível em tela estreita; uma única gramática de editar/deletar no app inteiro.

---

## ✂️ O que NÃO fazer

1. **Comparador somando por nome de status** como solução definitiva — o `targetStatId` entra já na Fase 3 exatamente para não reescrever o coração depois.
2. **Grafo tipado de pré-requisitos** (nó X exige nó Y nível Z com validação automática, coluna minParentLevel) — o pai do nó na árvore + texto por nível resolve; o app mapeia, não simula.
3. **Segundo motor de árvore para o governante** — governante é um herói com tag que tem árvore (Fase 7); mesma tabela, mesma tela.
4. **Flags nos tipos de unidade** (entersBattle/hasAbilities/hasOwnTree) — habilidades e árvores são de qualquer personagem; tipo é rótulo + maxPerSquad.
5. **Entidade/tabela própria de preset** — preset é duplicação + herói avulso no contrato (Fase 10); zero migração.
6. **DROP COLUMN / reescrever tabelas** para limpar colunas antigas (`characterType`, `maxHeroesPerSquad`, `triggerText`) — fóssil não lido é inofensivo; reescrever tabela no SQLite é onde se perde dado (L1).
7. **Sync automático template→stats existentes** — cópia unidirecional; "reaplicar" só como ação explícita do usuário.
8. **Conteúdo curado por jogo dentro do app** — genérico > específico; conteúdo específico vem por presets criados pelo usuário.
9. **Foto em tipos de unidade e nós de árvore** — só grupos, personagens e facções.
10. **Tema no banco / editor de tema completo** — shared_preferences + presets de cor entregam 90% do valor.
11. **Todas as migrações numa versão só** — 1 versão de schema por fase (v10…v17), blocos `if (oldV < N)` independentes; é o que permite aprovar/pausar fase a fase.
12. **Congelar o contrato JSON antes do 2º app existir** — versionar + documentar a cada fase basta; congelar agora é especulação.
13. **Pacotes novos de terceiros** — tudo acima é Dart puro + o que já está no pubspec.
14. **Perseguir cobertura de linha** — smokes de fluxo crítico + paridade de migração + round-trip de backup protegem o que importa.

---

## 🔧 Ajustes do crítico (incorporados — valem sobre o texto acima)

**Cortes (menos complexidade):**
1. **Fase 10**: cortado o "salvar/importar herói avulso como arquivo" — presets ficam só por DUPLICAÇÃO dentro do app (a metade pesada não é exigida pela visão).
2. **Fase 3**: o fallback por NOME do `targetStatId` é só transitório (migração + linhas órfãs) — a leitura normal usa ID; nunca dois caminhos permanentes.
3. **Fase 4**: após o backfill, `triggerText` vira fóssil NÃO LIDO (uma fonte de verdade só: as tabelas de gatilho).

**Faltas (adicionadas ao plano):**
4. **FASE EXTRA — Motor de fórmulas (o tipo "Cálculo" de verdade)**: avaliador
   simples de fórmulas entre stats (HP = vitalidade × outra stat). É 1 dos 4
   tipos da visão PROD e tinha ficado de fora. Posição sugerida: entre as
   fases 8 e 9 (após árvores, antes de tipos) — confirmar com o dono na hora.
5. **Fase 10 declara**: "conjuntos de itens" da visão são cobertos mapeando
   item como habilidade/status do herói (sem entidade nova de item por ora).
6. **Ponte comparador × árvores (a validar com o dono)**: para os talentos das
   árvores entrarem na soma do comparador, nós de árvore poderão ganhar efeito
   configurado (o MESMO mecanismo das habilidades) numa fase futura pós-8.
7. **"Árvores interligadas" — interpretação adotada (a validar com o dono)**:
   interligação = hierarquia pai→filho DENTRO de cada árvore; vínculos ENTRE
   árvores diferentes ficam fora do escopo por ora.
8. **Correção**: Fase 12 (migração v17) também nasce em BRANCH, como as demais
   fases com schema.
