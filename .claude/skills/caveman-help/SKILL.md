---
name: caveman-help
description: Cartão de referência do caveman deste projeto — níveis, skills da família, como trocar e como desligar. Use em /caveman-help, "ajuda do caveman", "como funciona o caveman".
---

# Caveman — cartão de referência

Mostre este cartão e pare. Não troque nível, não grave nada.

## Níveis

| Nível | Como pedir | O que muda |
|---|---|---|
| lite | `caveman lite` | sem enrolação; frases completas |
| full | `caveman full` | sem artigos; frase curta, uma ideia por frase (PADRÃO) |
| ultra | `caveman ultra` | só o essencial, cada fato uma vez |
| desligado | `modo normal` | resposta normal |

O nível fica em `.claude/caveman/nivel` e vale nas próximas conversas também.
Aviso de segurança e ação irreversível saem sempre em frase completa.

## Skills

| Skill | Para quê |
|---|---|
| `caveman-compress` | encolher o CLAUDE.md sem perder regra |
| `caveman-commit` | commit curto, com o porquê |
| `caveman-review` | revisão em uma linha por achado |
| `cavecrew` | quando usar os agents de relatório curto |
| `caveman-stats` | tokens gastos por sessão |

## O que ficou de fora, e por quê

O proxy, a CLI (`caveman claude`, `shrink`, `learn`...), o `browse`, o `mem` e o
painel de status do caveman original: ou ficam no meio de toda a conversa com a
Anthropic, ou mandam dados para fora, ou precisam de Node e da nuvem deles. O
ganho que eles davam veio por outro caminho — `scripts/enxuto.sh` para saída de
comando e `caveman-compress` para a memória.

---

Baseado na skill **caveman-help** (github.com/JuliusBrussee/caveman), © 2026
Julius Brussee, licença MIT — texto em `LICENSE`, nesta pasta.
