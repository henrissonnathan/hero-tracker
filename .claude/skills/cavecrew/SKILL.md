---
name: cavecrew
description: Quando delegar aos agents cavecrew-investigador (achar código), cavecrew-construtor (edição de 1 ou 2 arquivos) e cavecrew-revisor (revisar diff) — eles devolvem relatório curto e a conversa principal dura mais. Use ao pensar em delegar busca, edição pequena ou revisão.
---

# Cavecrew — agents que devolvem pouco texto

O relatório de um subagent entra INTEIRO na conversa principal. Um que devolve 2
mil tokens de prosa custa 2 mil tokens toda vez; o mesmo achado em formato curto
fica perto de 700.

## Neste ambiente, antes de tudo

Agent só quando o usuário pedir ou a tarefa for grande de verdade: cada um começa
do zero e custa caro no plano do dono. Busca pequena é mais barata feita direto,
com Grep e Read.

## Qual usar

| Tarefa | Use |
|---|---|
| "onde está X", "quem chama Y" | `cavecrew-investigador` |
| mapear arquitetura, com comentário | `Explore` (agent nativo) |
| edição cirúrgica, 1 ou 2 arquivos, local já sabido | `cavecrew-construtor` |
| recurso novo, 3+ arquivos, refactor | conversa principal |
| revisar diff ou arquivo | `cavecrew-revisor` |
| planejar fase grande | `Plan` (agent nativo) |

Este projeto não tem agents próprios além dos `cavecrew-*`.

## O que cada um devolve

- **investigador:** uma linha por achado, `caminho:linha — símbolo — nota curta`,
  e `total:` no fim. Ou `Nada encontrado.`
- **construtor:** `caminho:linhas — mudança em até 10 palavras.` e
  `conferido: releitura OK`. Ou uma palavra final: `grande-demais.`,
  `precisa-confirmar.`, `ambíguo.`, `quebrou.`
- **revisor:** `caminho:linha: 🔴/🟡/🔵/❓ gravidade: problema. correção.` e
  `total:`. Ou `Sem problemas.`

## Não faça

- Construtor sem saber o arquivo: ele gasta turno procurando.
- Construtor para refactor de 5 arquivos: ele responde `grande-demais.`
- Mostrar o relatório cru ao usuário: ele é para a conversa principal. Para o
  usuário, reescreva em frases.

---

Baseado na skill **cavecrew** (github.com/JuliusBrussee/caveman), © 2026 Julius
Brussee, licença MIT — texto em `LICENSE`, nesta pasta.
