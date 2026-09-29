---
name: caveman-compress
description: Encolhe um arquivo de memória (CLAUDE.md, anotações, listas) no estilo caveman para gastar menos token de entrada em toda sessão, sem perder regra nenhuma. Use em /caveman-compress <arquivo>, "comprimir o CLAUDE.md", "encolher memória", "CLAUDE.md muito grande".
---

# Caveman compress — memória menor, mesmas regras

O CLAUDE.md entra INTEIRO em toda sessão e de novo depois de cada compactação.
Cada palavra à toa ali é paga em todas as voltas da conversa.

## Diferente do original, de propósito

O caveman original roda scripts Python dele, que chamam a API da Anthropic (ou o
`claude` por baixo) para comprimir. Aqui **quem comprime é o próprio modelo desta
sessão** e quem confere é o `validar.py` desta pasta — escrito para este projeto,
sem rede. Nada de programa de terceiros rodando.

## Processo

1. **Só texto.** `.md`, `.txt` ou sem extensão. NUNCA `.dart`, `.kt`, `.json`,
   `.yaml`, `.gradle`, `.py`, `.sh`, `.bat`, `.ps1`.
2. **Cópia de segurança FORA do projeto**, para nenhum carregador de skill ler
   como arquivo vivo:
   `%LOCALAPPDATA%\caveman-compress\backups\<pasta-do-projeto>\<nome>.original.md`.
   O git também guarda o original — confira que o arquivo está commitado antes.
3. **Comprima** seguindo as regras abaixo. Escreva num arquivo temporário, não por
   cima do original.
4. **Confira:** `python .claude/skills/caveman-compress/validar.py <original> <temporário>`.
   Ele reprova se sumir título, cerca de código, código entre crases, endereço,
   `@import`, número de lei (L1…), nome de arquivo, número, ou se diminuir
   "não"/"nunca"/"nenhum"/"proibido".
5. **Reprovou?** Conserte SÓ o trecho apontado — não recomprima tudo. Até 2
   tentativas. Na 3ª falha, desista e deixe o original como estava.
6. **Aprovou:** troque o original pelo comprimido e informe o tamanho antes/depois.

## O que sai

- Artigos e enrolação ("basicamente", "na verdade", "é importante notar que").
- Rodeio ("pode valer a pena", "seria bom").
- Frase redundante: "com o objetivo de" → "para"; "certifique-se de" → corte.
- Item repetido que diz a mesma coisa de outro jeito: junte.
- Vários exemplos do mesmo padrão: fique com um.

## O que fica EXATO

- Bloco de código de verdade, código entre crases, comando, caminho, nome de
  arquivo, função, variável, URL.
- Número, versão, data, medição ("263 recusas em 7 min") — é a prova da regra.
- Toda negação e todo "só", "sempre", "exceto".
- Títulos (`#`), a hierarquia das listas, a numeração, a estrutura das tabelas.
- O PORQUÊ de cada regra, em uma frase curta. Regra sem porquê é a primeira que
  alguém "otimiza" e quebra.

## Neste projeto: as cercas ``` do CLAUDE.md são TEXTO

No CLAUDE.md do Hero Tracker as cercas ``` SEM linguagem guardam o registro de
skills, o mapa de arquivos, o schema, as leis e as fases — texto em fonte fixa,
não código. Ali o texto é comprimido como prosa, mas continua exato tudo que está
entre crases, todo nome de arquivo e todo número. As cercas COM linguagem
(```sql, ```powershell) são código e não se tocam — nem nos outros arquivos.

## Depois de comprimido

O arquivo comprimido passa a ser o arquivo de trabalho. Regra nova entra direto no
estilo comprimido — não existe "versão bonita" para manter em paralelo. Quem
quiser o texto longo de uma regra antiga olha o git.

---

Baseado na skill **caveman-compress** (github.com/JuliusBrussee/caveman), ©
2026 Julius Brussee, licença MIT — texto em `LICENSE`, nesta pasta. Adaptada para
português; os scripts originais (compress.py, que chama a API) não vieram.
