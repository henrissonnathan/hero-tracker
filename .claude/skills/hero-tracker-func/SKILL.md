---
name: hero-tracker-func
sigla: FUNC
description: >
  Especialista em funcionalidade e regras de negócio do hero-tracker.
  Carregue quando o chat for trabalhar em: comportamento de models, CRUD e
  consultas no repositório, herança de templates/nomes de tipo, habilidades e
  bônus, seed do exemplo RoK, pipeline seguro de foto, validação de regra.
  Mudança de SCHEMA vai com a skill BANC; formato do arquivo JSON com a JSON.
  NÃO toca em visual/tema.
triggers: [model, repository, CRUD, seed, habilidade, bônus, herança, template, foto-segura, regra-negócio, fórmula, cálculo]
---

# FUNC — Hero Tracker Funcionalidade

## Escopo deste chat
Trabalhe no **comportamento**: o que o app faz com os dados. Implemente
features, mantenha as invariantes do domínio. Quando a tarefa precisar de
coluna/tabela nova → é a skill BANC (receita de migration). Quando mexer no
formato do backup/pacote → skill JSON. Numa feature que precise das três,
o chat central (CENT) divide em etapas.

### Pode tocar em
```
lib/models/                  (comportamento; campo NOVO = BANC)
lib/repositories/tracker_repository.dart
lib/services/seed_service.dart · icon_image_store.dart
tool/seed_real_db.dart       (grava o exemplo no banco REAL do dono)
```

### NÃO pode tocar em
- lib/repositories/database_helper.dart — schema/migrations (BANC)
- lib/services/export_service.dart + docs/CONTRATO-JSON.md — contrato (JSON)
- lib/theme/ · lib/ui/ — visual (VISL); mas veja "lógica na UI" abaixo
- test/ — use o chat TEST (mudou comportamento testado? avise no handoff)

## Mapa rápido (onde está o quê)
- `TrackerRepository.instance` — singleton, todo CRUD: grupos, personagens,
  stats, nós de árvore, templates, habilidades, nomes de tipo.
- Herança pelo ancestral: `getEffectiveTemplates(groupId)` (sub-grupo sem
  template próprio herda do pai mais próximo) e `getEffectiveTypeNames`
  (nearest-wins por tipo). Ambos cortam ciclo de `parentId`.
- Template → personagem é CÓPIA (`toCharacterStat`), não referência: editar
  ou apagar template não mexe em personagem já criado (há teste).
- `applyGroupTemplatesToCharacter` — personagem novo nasce com o modelo.
- `SeedService`: `createExample` / `exampleExists` / `removeExample` (apaga
  sub-grupos EXPLICITAMENTE, não confia no CASCADE por causa do `parentId`
  criado por ALTER TABLE sem FK). Nomes do jogo = fatos; números =
  ilustrativos. Comandante do RoK NÃO tem Ataque/Defesa/Vida (é das tropas).
- `IconImageStore`: `importIcon` (valida dimensão, re-codifica PNG interno),
  `generatePlaceholder`, `deleteIcon`, `cleanupOrphans(referenced)`.

### Lógica que MORA na UI hoje (atenção)
- Bônus de habilidade ativa: `character_screen.dart` `_boostedValueFor`
  (~linha 87) — `bonusKind` 'flat' soma, 'percent' multiplica. É exibição;
  valor salvo nunca muda. Extrair para service = tarefa FUNC combinada com
  VISL (CENT coordena).
- **Não existe motor de fórmula**: `StatType.formula` guarda só TEXTO
  (`formulaText`), nada é calculado. O motor é a "fase extra" do ROADMAP —
  exige SPEC + OK do dono antes (L3).

## Invariantes do domínio (nunca quebre)
1. SQL seguro: sempre `?` + `whereArgs`, nunca interpolação de string
2. Transação única: operações multi-tabela dentro de `db.transaction()`;
   dentro dela use só o `txn` (chamar o repositório singleton trava — E26)
3. Tipos de stat: percent | number | trigger | formula ("count" virou number na v8)
4. Fotos de grupo E de personagem dividem a pasta `group_icons/`: varredura de
   órfãos SÓ com `getAllIconImagePathsInUse()` — uma lista só apaga as fotos
   da outra (teste: character_photo_test)
5. `toMap()` sempre com todas as chaves, inclusive null (senão UPDATE não
   limpa o campo — bug já corrigido em Character)
6. Dado do dono é sagrado: nada apaga/sobrescreve sem confirmação na UI
7. 100% offline, sem pacote novo no pubspec sem OK do dono

## Testes que cobrem esta camada (rode o arquivo certo)
group_stat_template_test (herança, cópia, FK, habilidades) ·
seed_service_test · unit_type_label_test · character_photo_test ·
model_roundtrip_test (todo campo sobrevive salvar→ler).

## Portão antes de entregar
```bash
export PATH="/c/flutter/bin:$PATH"
flutter analyze --fatal-infos --no-pub && flutter test --no-pub
```
Sem commit: quem commita é o chat central (L7).

## Handoff
Saiu do escopo (schema, JSON, tela, teste) → devolva ao CENT no formato de
handoff da skill `hero-tracker-central`.
