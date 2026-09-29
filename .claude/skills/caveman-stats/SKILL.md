---
name: caveman-stats
description: Mostra quantos tokens as sessões do Claude Code gastaram neste projeto (saída, entrada, cache), lidos dos registros locais. Use em /caveman-stats, "quanto token gastei", "consumo da sessão", "gasto de token".
---

# Caveman stats — o que foi gasto

Rode:

```bash
python .claude/skills/caveman-stats/stats.py          # as 5 sessões mais recentes
python .claude/skills/caveman-stats/stats.py --todas  # todas deste projeto
```

Mostre o resultado dentro de um bloco de código, como veio. Não recalcule nem
arredonde de novo.

## O que o número É e o que NÃO é

- É o que as respostas gastaram, somado dos registros `.jsonl` que o Claude Code
  guarda no próprio PC (`~/.claude/projects/<projeto>/`). Nada sai do computador.
- NÃO é economia. Sem uma medição da mesma tarefa sem caveman, economia é
  desconhecida — não invente porcentagem nem valor em dinheiro.
- "cache lido" é a parte da conversa reaproveitada de uma volta para a outra;
  pesa bem menos que entrada nova.

---

Inspirada na skill **caveman-stats** (github.com/JuliusBrussee/caveman), © 2026
Julius Brussee, licença MIT — texto em `LICENSE`, nesta pasta. O `stats.py` foi
escrito para este projeto; o original lê os registros por um hook em Node.
