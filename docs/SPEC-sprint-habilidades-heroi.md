# SPEC — Sprint "Habilidades de Herói"

> Gerada em 2026-07-24 (SDDV). Aguarda OK do dono para implementar (L3/PLN_1ST).
> Visão do dono: habilidade tem DUAS partes — a **descrição** (texto) e a parte
> que **realmente faz** (configuração do efeito). Ex.: descrição "quando em
> campo ele dá mais 20 de ataque"; configuração = gatilho ("atacando uma base")
> → efeito (+20 no status Ataque).

## Objetivo

Herói (personagem) ganha uma seção **Habilidades**: cada habilidade tem nome,
descrição livre, **gatilho** (a condição, ex.: "atacando uma base", "em campo")
e **efeito configurado** (qual status recebe o bônus + valor + tipo).

## Mudanças

| # | Mudança | Detalhe |
|---|---------|---------|
| 1 | Migration **v8 → v9** | tabela `character_abilities`: id, characterId FK→characters CASCADE, name, description, triggerText, targetStatName, bonusValue REAL, bonusKind ('flat'\|'percent'), isActive INTEGER DEFAULT 0, sortOrder |
| 2 | Modelo novo `character_ability.dart` | espelho da tabela; `bonusLabel` ("+20" / "+20%") |
| 3 | Repositório | CRUD de habilidades por characterId |
| 4 | UI `character_screen` | seção "⚡ Habilidades" com CRUD; dialog: Nome, Descrição, Gatilho (texto), Efeito = dropdown dos **stats do personagem** + valor + flat/% |
| 5 | Card da habilidade | mostra descrição + linha do efeito: "⚡ atacando uma base → +20 Ataque" + toggle **ativa** |
| 6 | Toggle "ativa" (escopo a confirmar) | com a habilidade ativa, o stat alvo exibe o valor com bônus (ex.: Ataque 100 → **120**) — simulação visual, sem alterar o valor salvo |
| 7 | Teste (L5) | habilidade criada aparece; efeito aplicado na exibição quando ativa |

## Critérios de aceitação

1. Criar no herói a habilidade "Fúria" com descrição, gatilho "atacando uma
   base" e efeito +20 em Ataque → card mostra as duas partes.
2. Ligar o toggle → stat Ataque exibe valor com bônus destacado; desligar →
   volta ao normal. Valor salvo do stat NUNCA muda (é simulação).
3. Efeito percentual (+10%) calcula sobre o valor atual do stat.
4. Deletar personagem apaga habilidades (CASCADE).
5. Android intocado; migration incremental (L2); nada muda para quem não usa.

## Edge cases obrigatórios

- Stat alvo renomeado/apagado depois → card mostra aviso "status não existe
  mais" e o efeito fica inerte (sem crash).
- Habilidade sem efeito (só descrição) → permitido (efeito é opcional).
- Valor negativo (-20) → permitido (debuff).
- Personagem sem nenhum stat → dialog permite criar habilidade só com
  descrição/gatilho; dropdown de efeito mostra "sem status disponíveis".
- Duas habilidades ativas no mesmo stat → bônus somam na exibição.

## Fora do escopo (fica para o motor de fórmulas)

- Gatilhos como entidades nomeadas reutilizáveis ("atacando", "defendendo",
  "raid") compartilhadas entre heróis — nesta sprint gatilho é texto livre.
- Fórmulas de cálculo entre stats (Sprint 4) e papel semântico vida/recurso.
- Habilidades no nível do MODELO do grupo (template de habilidades).
