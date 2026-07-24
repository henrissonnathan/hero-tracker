# SPEC — Sprint "Stats-base do grupo" (template dinâmico de estatísticas)

> Gerada em 2026-07-23 conforme SDDV. Implementar em chat novo/limpo (L4).
> Aprovação do dono: pedido em 2026-07-23 ("a parte de estatística é feita
> antes, uma base, antes de criar o herói/tropas").

## Objetivo

Na tela do grupo/jogo, o dono define o conjunto **dinâmico** de estatísticas
do jogo (nomes livres: Vida, Defesa, Ataque, ...), cada uma com tipo
(`count` / `number` / `percent` / `trigger` / `formula`). Todo personagem
criado no grupo **nasce com esses stats prontos** para preencher.

## Mudanças

| # | Mudança | Detalhe |
|---|---------|---------|
| 1 | Migration **v5 → v6** | tabela nova `group_stat_templates` (id, groupId FK→game_groups ON DELETE CASCADE, name, type, defaultValue REAL, maxValue REAL, triggerText, formulaText, sortOrder) |
| 2 | Modelo novo `group_stat_template.dart` | espelha CharacterStat sem characterId |
| 3 | Repositório | CRUD de templates + cópia template→character_stats na criação de personagem |
| 4 | UI tela do grupo | seção/botão "📊 Estatísticas do jogo" com CRUD; **reusar o dialog de stat do character_screen extraindo-o para widget compartilhado AO LADO** (L1 — não reescrever o existente) |
| 5 | Criação de personagem | após insert, copiar templates do grupo (e do pai, se sub-grupo sem templates próprios) para character_stats |
| 6 | Teste (L5) | template criado → personagem novo nasce com os stats |

## Critérios de aceitação

1. Criar no grupo os stats "Vida" (inteiro), "Defesa" (inteiro), "Crítico" (%)
   → criar herói → ele já tem os 3 stats com valor default.
2. Personagens criados ANTES dos templates continuam intactos (sem stats novos
   automáticos; avaliar botão "aplicar aos existentes" como opcional).
3. Editar/apagar template NÃO altera stats de personagens já criados
   (é cópia, não referência).
4. Grupo sem templates → comportamento atual 100% intocado (L1).
5. Android intocado; migration incremental (L2).

## Edge cases obrigatórios

- Nome de template duplicado no mesmo grupo → bloquear com aviso.
- Template tipo `formula` → por enquanto só guarda o texto (motor de cálculo é
  a sprint seguinte); não pode quebrar nada ao ser copiado.
- Sub-grupo: herda templates do pai quando não tem os seus? (decidir com o dono
  no início da sprint; sugestão: herdar do pai mais próximo que tiver).
- Deletar grupo → CASCADE apaga templates (verificar PRAGMA foreign_keys).
- Export/import: templates devem entrar no JSON de backup.

## Fora do escopo (sprints seguintes)

- Motor de avaliação de fórmulas (Sprint "Fórmulas" — StatType.formula calcular
  de verdade usando outros stats do personagem).
- Drag-and-drop de foto (pende autorização do pacote `desktop_drop`).
- Foto no dialog de sub-grupos; backup levar fotos (base64).
