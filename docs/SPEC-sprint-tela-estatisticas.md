# SPEC — Sprint "Tela exclusiva de Estatísticas + categorias"

> Gerada em 2026-07-23 (SDDV). AGUARDA aprovação do dono antes de codar (L3/PLN_1ST).
> Pedido do dono: "a parte de estatísticas deve ter uma tela exclusiva; poder
> fazer sub-grupos para separar as estatísticas e mexer melhor depois."

## Objetivo

Tirar as estatísticas de "seção dentro da tela do grupo" e dar a elas uma
**tela dedicada**, onde os stats podem ser **organizados em categorias
(sub-grupos)** para ficar mais fácil de gerenciar.

## Interpretação padrão (a confirmar com o dono)

"Sub-grupos" das estatísticas = **categorias/seções** dentro da tela de stats
(cada template tem uma categoria; a tela agrupa por ela), NÃO a hierarquia de
pastas aninhadas que os game_groups já têm. Escolha justificada: resolve
"separar para mexer melhor" com mudança aditiva mínima, sem complexidade de
árvore. Se o dono quiser hierarquia real, é outra SPEC (maior).

## Mudanças

| # | Mudança | Detalhe |
|---|---------|---------|
| 1 | Migration **v6 → v7** | coluna nova `category TEXT` (opcional) em `group_stat_templates` |
| 2 | Modelo `group_stat_template.dart` | campo opcional `category`; toMap/fromMap/copyWith |
| 3 | Nova tela `lib/ui/stats_screen.dart` (`StatsScreen`) | recebe o `GameGroup`; CRUD completo dos templates; stats agrupados por `category` com cabeçalhos de seção; criar/renomear categoria |
| 4 | `game_screen.dart` | a seção "📊 Estatísticas do jogo" vira um **atalho/tile** "Gerenciar estatísticas" que abre a `StatsScreen`; mantém preview curto (contagem/lista resumida) |
| 5 | `StatFormDialog` | ganhar campo opcional de categoria (dropdown com categorias existentes + "nova categoria"); reusado pelo character_screen sem categoria (param opcional, L1) |
| 6 | Teste (L5) | StatsScreen abre e agrupa templates por categoria |

## Critérios de aceitação

1. Na tela do grupo, "Gerenciar estatísticas" abre a tela exclusiva.
2. Criar stats Vida e Defesa na categoria "Combate", e Ouro na categoria
   "Recursos" → a tela mostra duas seções com os stats certos.
3. Stat sem categoria cai numa seção "Sem categoria" (ou "Geral").
4. Criar personagem continua copiando TODOS os templates do grupo (categoria é
   só organização; não afeta a cópia template→personagem) — L1.
5. Grupo/telas antigas sem categoria: comportam-se como hoje (categoria null).
6. Android intocado; migration incremental (L2); character_screen segue usando
   o StatFormDialog sem categoria.

## Edge cases obrigatórios

- Renomear categoria atualiza todos os stats dela; apagar categoria → stats vão
  para "Sem categoria" (não some stat).
- Categoria com nome duplicado → normalizar/bloquear.
- Export/import: `category` entra no backup e volta.
- Sub-grupo que herda templates: a StatsScreen do sub-grupo mostra os herdados
  (read-only) agrupados também, coerente com o que já foi feito.

## Fora do escopo (sprints seguintes)

- Papel/categoria SEMÂNTICO do stat (vida/recurso para fórmulas) — é conceito
  diferente de categoria-organização; ver [[hero-tracker-next-sprint]].
- Motor de cálculo de fórmula (Sprint 4).
- Hierarquia real de sub-grupos de stats (se o dono quiser em vez de categorias).
