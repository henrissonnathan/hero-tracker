---
name: caveman-review
description: Revisão de código enxuta — uma linha por achado, com arquivo:linha, problema e correção. Use em /caveman-review, "revisa o diff", "revisa este arquivo", "procura bug nesta mudança".
---

# Caveman review — um achado por linha

## Formato

`<arquivo>:L<linha>: <gravidade>: <problema>. <correção>.`

| Gravidade | Quando |
|---|---|
| 🔴 bug | quebra, travamento, falha de segurança, perda de dado |
| 🟡 risco | funciona mas é frágil: corrida, `!` sem guarda, erro engolido |
| 🔵 detalhe | nome, estilo — só se pedirem revisão completa |
| ❓ pergunta | precisa da intenção do autor antes de julgar |

Última linha: `total: N🔴 N🟡 N🔵 N❓`. Nada achado: `Sem problemas.`

## Corta

"Notei que...", "parece que...", "talvez valha...", elogio por achado, repetir o
que a linha faz.

## Mantém

Número de linha exato, nome exato entre crases, correção concreta ("guarde com
`if (mounted)`", não "considere refatorar"), e o porquê quando a correção não é
óbvia.

## Neste projeto, olhe primeiro

As leis do CLAUDE.md: L1 (novo AO LADO, nunca apagar coluna nem refazer
tabela), L2 (migração incremental — `migration_parity_test.dart` tem que
passar), L5 (widget novo tem teste). Depois o cofre de erros E01–E27 da memória
do projeto (`hero-tracker-error-vault.md`): foto (bomba de pixels, órfãos na
pasta compartilhada `group_icons/`), import JSON (tudo-ou-nada, caminho de foto
nunca entra), `toMap()` omitindo campo null num UPDATE.

## Sai do modo quando

Achado de segurança ou desacordo de arquitetura: parágrafo normal explicando o
risco, depois volta ao formato curto.

---

Baseado na skill **caveman-review** (github.com/JuliusBrussee/caveman), © 2026
Julius Brussee, licença MIT — texto em `LICENSE`, nesta pasta.
