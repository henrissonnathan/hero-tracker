---
name: caveman-commit
description: Mensagem de commit curta e exata, no padrão deste repositório (Conventional Commits em português, sem acento), com o PORQUÊ e sem enrolação. Use ao escrever commit, "mensagem de commit", /caveman-commit, ou antes de qualquer git commit deste projeto.
---

# Caveman commit — curto, com o porquê

O diff já diz O QUÊ mudou. A mensagem existe para o PORQUÊ.

## Assunto (a primeira linha)

- `<tipo>: <resumo no imperativo>` — é o padrão do `git log` daqui:
  `feat: tipos de unidade (soldado/heroi/comandante) + config de esquadrao`.
- Tipos: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `chore`, `build`.
- Português **sem acento** (convenção do repo) e sem ponto final.
- Até 72 caracteres. Mudou o schema? Diga a versão do banco (`v11`) no corpo.

## Corpo (só quando precisa)

- Pule o corpo quando o assunto já explica.
- Com corpo: bullets `- `, linha de até 72 caracteres, cada bullet é um porquê ou
  um efeito para o usuário — não a lista de arquivos.
- Mudança que quebra algo, migração de banco, correção de segurança ou reversão:
  corpo SEMPRE, completo. Quem investigar depois precisa do contexto.

## Nunca

- "Este commit faz...", "agora", "atualmente" — o diff já diz.
- Emoji. Nome de arquivo repetido no assunto.

## Trailer obrigatório

A linha `Co-Authored-By:` que o sistema pede fica no fim, sempre. É regra do
ambiente, não enrolação.

## Limite

Esta skill só ESCREVE a mensagem. Commit, add e push continuam exigindo a
autorização do dono (lei L7 e regra NO_GIT do CLAUDE.md). O portão
`testes.ps1` (analyze + test) roda antes de qualquer commit.

---

Baseado na skill **caveman-commit** (github.com/JuliusBrussee/caveman), © 2026
Julius Brussee, licença MIT — texto em `LICENSE`, nesta pasta. Adaptada ao padrão
de commit deste repositório.
