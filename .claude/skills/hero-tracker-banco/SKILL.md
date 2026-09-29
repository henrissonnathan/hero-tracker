---
name: hero-tracker-banco
sigla: BANC
description: >
  Especialista em SCHEMA do banco do hero-tracker (sqflite, migrations
  onUpgrade). Carregue quando o chat for: criar coluna ou tabela, mudar tipo
  ou dado existente, subir a versão do banco, investigar crash ao abrir o app
  depois de atualizar, ou planejar a migração de uma fase do ROADMAP. Leva a
  mudança de ponta a ponta (schema → model → contrato → teste de paridade).
triggers: [schema, migration, migração, onUpgrade, onCreate, ALTER-TABLE, CREATE-TABLE, _dbVersion, coluna-nova, tabela-nova, database_helper]
---

# BANC — Hero Tracker Banco (schema e migrations)

## Por que existe
Migração é a única mudança que roda no banco REAL do dono e não tem volta: ao
abrir o app novo, o banco em `%APPDATA%\com.henrissonnathan\hero_tracker\
hero_tracker.db` sobe de versão para sempre. Dado do dono é sagrado.

## Escopo deste chat
Uma mudança de schema, de ponta a ponta (fatia vertical):
```
lib/repositories/database_helper.dart   ← _dbVersion, _onCreate, _onUpgrade
lib/models/<modelo>.dart                ← campo + toMap/fromMap/copyWith
lib/services/export_service.dart        ← SÓ incluir/validar o campo novo
docs/CONTRATO-JSON.md                   ← SÓ a linha da versão nova
test/migration_parity_test.dart         ← SÓ se a v1 fixture precisar
test/model_roundtrip_test.dart          ← campo novo no round-trip
CLAUDE.md (seção "Schema do banco")     ← versão + tabela + linha da migração
```
### NÃO pode tocar em
- lib/ui/ (a tela que USA o campo é VISL, depois) · regra de negócio (FUNC)
- Mudança de formato do arquivo além do campo novo → chat JSON

## Estado atual (2026-09-29)
- `static const _dbVersion = 11;` em database_helper.dart:11
- Tabelas: game_groups, characters, character_stats, group_stat_templates,
  skill_nodes, character_abilities, unit_type_labels
- FK: `PRAGMA foreign_keys = ON` em `_onConfigure` (toda conexão). Ainda
  existe o legado `enableForeignKeys()` chamado em tracker_repository.dart:115
  e :150 — redundante, inofensivo; remover é limpeza opcional.
- Fóssil: `game_groups.parentId` e outras colunas criadas por ALTER TABLE NÃO
  têm FK (SQLite não cria FK em ADD COLUMN) → nunca confie em CASCADE nelas.
- **A próxima migração é a v12.** Os números do docs/ROADMAP.md (v10
  targetStatId, v11 game_triggers...) estão DESATUALIZADOS: v10 virou foto do
  personagem e v11 nomes dos tipos. Some +2 ao ler o roadmap e corrija o doc.

## Receita (siga na ordem)
1. **Planeje com o dono** (L3): coluna/tabela, tipo, default, o que acontece
   com os dados que já existem. Sem OK, não comece.
2. `_dbVersion` +1.
3. `_onCreate`: o banco NOVO nasce direto na forma final. Tabela nova =
   helper `_createXxxTable(db)` com `CREATE TABLE IF NOT EXISTS`, chamado no
   `_onCreate` E na migração (mesmo helper, schema nunca duplicado).
4. `_onUpgrade`: bloco novo no fim, SEMPRE com o guard de duas pontas:
   ```dart
   if (oldV < 12 && newV >= 12) {
     // v11 → v12: <por quê, em português>
     await db.execute('ALTER TABLE characters ADD COLUMN xxx TEXT');
   }
   ```
   - Sem o `newV >= N` o teste parcial migra até o fim e não testa nada (E25).
   - `NOT NULL` em ADD COLUMN exige `DEFAULT`.
   - Coluna que um caminho anterior já pode ter criado → guard com
     `PRAGMA table_info(<tabela>)` (modelo: bloco v7, ~linha 160).
   - Converter dado = `UPDATE` com valores fixos (modelo: v8 count→number).
   - NUNCA `DROP`, renomear coluna ou recriar tabela com dado: coluna velha
     vira fóssil de leitura (L1). Backfill de coluna nova a partir da velha
     é permitido (ex.: targetStatId a partir do nome).
   - SQL com valor vindo de fora = `?` + whereArgs (aqui é quase tudo DDL fixo).
5. Model: campo + `toMap()` com TODAS as chaves (inclusive null) + `fromMap()`
   tolerante (ausente/null → default) + `copyWith`.
6. Contrato JSON: o campo entra no export; `_parseAndValidate` valida
   (limite de texto via `checkText`, tipo); arquivo ANTIGO sem o campo
   continua importando (default). Mudou o formato do arquivo →
   `ExportService.formatVersion` +1 e linha na tabela do docs/CONTRATO-JSON.md.
   Caminho de arquivo (foto) NUNCA viaja no JSON.
7. Testes: `migration_parity_test` compara sozinho banco novo × migrado
   (v1→atual e v5→atual) — se ficar vermelho, o `_onCreate` e o `_onUpgrade`
   discordam: conserte o código, não o teste. Campo novo no
   `model_roundtrip_test`. Atualize o texto "(v1 → v11)" em
   lib/ui/tests_info_screen.dart:56 e docs/TESTES.md (peça ao TEST se preferir).
8. Docs: CLAUDE.md seção "Schema do banco" (versão, tabela, linha
   "vN→vN+1 ...") e o comentário "versão atual" na árvore de arquivos.
9. **Antes do dono abrir o app novo**: diga a ele para fazer
   "Exportar dados (backup)" (menu ⋮ da Home) — a migração é irreversível.

## Portão antes de entregar
```bash
export PATH="/c/flutter/bin:$PATH"
flutter analyze --fatal-infos --no-pub
flutter test --no-pub test/migration_parity_test.dart test/model_roundtrip_test.dart
flutter test --no-pub          # bateria inteira
```
Sem commit: quem commita é o chat central (L7), e schema novo só entra com
OK explícito do dono.

## Handoff
Devolva ao CENT (formato da skill `hero-tracker-central`): versão antes →
depois, SQL da migração, o que acontece com dado antigo, o que falta na UI
(VISL) ou na regra (FUNC), e o lembrete do backup para o dono.
