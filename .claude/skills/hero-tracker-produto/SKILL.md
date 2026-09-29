---
name: hero-tracker-produto
description: Visão do produto hero-tracker (mapeador de jogos) e fonte da verdade do objetivo do app. Use no projeto hero-tracker sempre que for planejar ou decidir algo — nova feature, SPEC, roadmap, fase, priorizar, dúvida de escopo ("isso cabe no app?") — ou ao mexer em tipos de status (gatilho, número, porcentagem, cálculo), heróis e habilidades, comparador de heróis / boosts somados / builds, árvores de pesquisa, construção e talentos, presets, e no formato JSON (contrato com o app de teste/simulação futuro). Jogos tipo Rise of Kingdoms (RoK), estratégia e RPG.
---

# SKILL: hero-tracker-produto (PROD)

> Visão do produto ditada pelo dono em 2026-07-24 (sessão hero-tracker).
> É a **fonte da verdade do objetivo** — toda feature, SPEC e fase do roadmap
> deve apontar para isto. ALWAYS_ON nas sessões do projeto hero-tracker.
> Skill DE PROJETO: vive em `hero-tracker/.claude/skills/` (movida do hub em 2026-09-13).

## O objetivo em uma frase

O hero-tracker é um **mapeador de jogos**: um app onde qualquer pessoa, **sem
saber programar**, consegue mapear como um jogo funciona por dentro — números,
bônus, fórmulas, gatilhos, habilidades — e usar esse mapa para montar e
**comparar builds**. Começa por jogos de estratégia (Rise of Kingdoms é o caso
mais fácil), mas serve para **qualquer jogo**, inclusive RPG.

## Por que cada tipo de status existe (explicação do dono)

| Tipo | Mapeia | Exemplo |
|------|--------|---------|
| **Gatilho** | O QUE deve acontecer para ter um efeito | "defendendo a base" |
| **Número** | Valores inteiros/reais do jogo: recursos, produção, recursos atuais, custos de pesquisa/construção, tempo | comida: 1.500.000 |
| **Porcentagem** | Bônus em % | +10% de ataque |
| **Cálculo** | Fórmulas combinando status | HP = vitalidade × outra stat |

## Regras confirmadas pelo dono (2026-07-24)

1. **Gatilhos são reutilizáveis e por jogo**: a lista de gatilhos pertence ao
   jogo; qualquer herói usa os mesmos gatilhos, e uma habilidade usa **de 0 a
   muitos** gatilhos (nenhum também é válido). A habilidade tem sempre duas
   partes: o **texto livre** (descrição) e, embaixo, **o que ela faz com os
   bônus** (efeito configurado).
2. **Custos de pesquisa/construção**: parte separada, em **forma de árvore** —
   mostra o que é **obrigatório antes** (pré-requisitos) e **quais recursos**
   cada item/nível usa.
3. **Comparador de heróis JÁ NESTE app**: selecionar heróis e ver os **boosts
   somados** que eles dão juntos naquele momento (jogos usam duplas ou times
   maiores) — é para isso que o mapeamento de heróis existe.
4. **Árvores**: interligadas; **várias por jogo** (cada jogo tem as suas,
   diferentes). **Heróis também têm árvores**: dependendo das **tags de tropa**
   do herói (ex.: defesa, tropa mista), **cada tag = uma árvore** dele — como
   os talentos de comandante do RoK (uma árvore por especialização).
5. **App futuro (2º projeto)**: um app de **teste/simulação** vai consumir os
   dados deste (testar integração de heróis, cálculo de dano, builds rápido).
   O canal é o **JSON documentado**, com **limites explícitos e validação
   rígida** — impossível passar vírus/hack. O formato é **contrato oficial**
   e estável; integração direta entre os apps é possível no futuro.
6. **Presets**: conjuntos prontos reutilizáveis — herói+habilidades, conjuntos
   de itens que um herói usa dependendo do jogo, padrões tipo "comandante"
   (evolui por passos e dá boosts).

## Leis de decisão

- **Simplicidade acima de tudo** — o usuário nunca precisa programar.
- Toda feature deve servir ao **mapeamento** ou à **comparação**; se não serve
  a nenhum dos dois, questionar.
- **Dados do usuário são sagrados**: offline, local, formato seguro.
- **Genérico > específico**: nada chumbado de um jogo só; conteúdo específico
  de jogo vem por presets criados pelo usuário.

## Decisões do dono (2026-07-25 → 2026-09-27)

1. **Cada atributo mora em quem o tem no jogo.** Ex. RoK: Ataque/Defesa/Vida
   são das TROPAS; o comandante entra pela capacidade de tropa e pelos bônus %
   das habilidades. Mapa que põe atributo no dono errado mente sobre o jogo.
2. **O nome das coisas é do jogo, não do app.** Os tipos de unidade são
   renomeados por jogo, dentro do app, sem código ("Herói" → "Comandante",
   "Governador", "Tropa"). Por dentro o tipo não muda.
3. **Foto em tudo**: grupo e também herói/tropa — sempre pelo cofre seguro
   (PNG re-codificado, nunca viaja no JSON).
4. **Tocar > digitar.** O dono tem dificuldade para digitar: escolher o tipo
   com explicação na hora, montar fórmula tocando nos nomes dos status, reusar
   gatilhos já usados no jogo com um toque. Formulário "o mais dinâmico
   possível" = se adapta ao que foi escolhido e pede o mínimo.
5. **Receber mapa pronto por JSON**: um "pacote" (modelo de status +
   personagens) importa DENTRO de um jogo que já existe, com a mesma validação
   do contrato. É o canal para receber mapas de outras pessoas e, no futuro, do
   2º app. Nada que já existe é sobrescrito.

## Anti-padrões

- Virar simulador NESTE app (simulação é o app futuro).
- Conteúdo curado por jogo mantido dentro do app (manutenção eterna).
- Mudar o formato do JSON sem versionar/documentar (quebra o contrato com o
  app futuro).
