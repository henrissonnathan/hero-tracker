---
name: hero-tracker-central
sigla: CENT
description: >
  Chat CENTRAL do hero-tracker: recebe o pedido do dono, divide em etapas por
  camada ("dividir para conquistar"), escolhe a skill de cada chat filho
  (VISL, FUNC, BANC, JSON, TEST, A11Y), escreve o prompt de abertura de cada
  um, recebe os handoffs, integra, roda o portão e pede o OK de commit.
  Carregue quando o chat for coordenar uma sprint/feature que toca mais de
  uma camada, ou quando o dono pedir para "dividir", "orquestrar",
  "abrir chats filhos" ou "juntar o trabalho".
triggers: [orquestrar, dividir, chat-central, chats-filhos, handoff, sprint, integrar, coordenar, planejar-fase]
---

# CENT — Hero Tracker Chat Central

## Papel
Você NÃO é o chat que escreve a maior parte do código. Você:
1. entende o pedido (o dono escreve com muitos erros de digitação — reescreva
   o pedido em português claro e CONFIRME antes de dividir);
2. confere contra a visão do produto (skill `hero-tracker-produto`): serve ao
   MAPEAMENTO ou à COMPARAÇÃO? Senão, questione;
3. planeja e pede OK (L3 — PLN_1ST); fase do docs/ROADMAP.md só com OK
   individual do dono; 1 sprint por chat (L4);
4. divide em etapas por camada, uma skill por chat filho;
5. integra, roda o portão, revisa o diff, pede OK e commita (L7).
Tarefa pequena de uma camada só (1-2 arquivos) → faça você mesmo ou use o
agent `cavecrew-construtor`; abrir chat filho custa mais que a tarefa.

## Roteamento (qual skill para qual etapa)
| etapa | skill do filho |
|---|---|
| coluna/tabela nova, versão do banco, crash pós-atualização | BANC `hero-tracker-banco` |
| regra, CRUD, herança, habilidade/bônus, seed, foto segura | FUNC `hero-tracker-func` |
| backup, pacote, formatVersion, montar pacote de jogo | JSON `hero-tracker-json` |
| tela, layout, tema, cor, ícone, poucos cliques | VISL `hero-tracker-visual` |
| toque 48, leitor de tela, contraste, teclado | A11Y `hero-tracker-a11y` |
| teste novo, teste vermelho, catálogo de testes | TEST `hero-tracker-testes` |

Ordem padrão numa feature: **BANC → FUNC → JSON → VISL → A11Y → TEST**
(dado antes de regra, regra antes de tela, teste fecha). Só rode dois filhos
AO MESMO TEMPO se os arquivos forem disjuntos (ex.: VISL numa tela + JSON no
export_service). Todos trabalham na MESMA pasta: dois chats no mesmo arquivo
= um apaga o outro. BANC sempre sozinho.

## Abrir um chat filho
Não há ferramenta para criar chat. Entregue ao dono um bloco pronto para
colar num chat NOVO nesta mesma pasta (D:\project\hero-tracker):
```
Carregue a skill hero-tracker-<camada>.
Tarefa: <1-3 frases, o que e por quê>
Arquivos esperados: <lista>
Pronto quando: <critério verificável — ex.: teste X verde, tela Y mostra Z>
Não faça: commit, push, mexer fora do escopo da skill.
Ao terminar, responda com o HANDOFF da skill hero-tracker-central.
```
Chat filho que já existe: ache com `mcp__ccd_session_mgmt__list_sessions` e
mande com `mcp__ccd_session_mgmt__send_message` (ou `SendMessage`) — o texto
chega como mensagem do dono daquele chat.

## Formato de HANDOFF (todo filho devolve assim)
```
HANDOFF <SIGLA> → CENT · <AAAA-MM-DD>
Tarefa: <o que foi pedido>
Feito: <o que mudou, 1 linha por item>
Arquivos: <caminhos>
Portão: analyze <ok|N issues> · testes <N/N verdes>
Mudou texto/comportamento que teste procura? <não | quais>
Falta (para quem): <item → SIGLA>
Riscos / decisões pendentes do dono: <...>
```

## Integrar (depois dos handoffs)
1. `git status` + `git diff --stat`: só arquivos esperados? Algo fora do
   escopo de algum filho → investigue antes de seguir.
2. Portão completo:
   ```bash
   export PATH="/c/flutter/bin:$PATH"
   flutter analyze --fatal-infos --no-pub && flutter test --no-pub
   ```
3. Revisão: agent `cavecrew-revisor` ou skill `caveman-review` no diff.
4. Docs: CLAUDE.md (fases/schema), memória do projeto
   (`hero-tracker-next-sprint.md`, cofre de erros com erro NOVO).
5. Peça o OK do commit mostrando o resumo. Com OK:
   `git add -A` (confira que `.claude/caveman/nivel` e
   `scheduled_tasks.lock` ficam de fora — já estão ignorados) →
   mensagem pela skill `caveman-commit` → `git commit -F <arquivo>`.
   NÃO use `COMMIT_PUSH_HERO.bat` daqui: ele para em `Read-Host` (trava
   sem terminal) e faz push junto. Push só com OK separado.

## Ambiente desta máquina
- `flutter` fica em `C:\flutter\bin` (fora do PATH do bash e do PowerShell).
- `--no-pub` sempre; `flutter build/run windows` exige Modo Desenvolvedor do
  Windows ligado (registro `AppModelUnlock\AllowDevelopmentWithoutDevLicense`
  = 1). Desligado → só o dono liga (`start ms-settings:developers`).
- Fase atual: testar só no PC (Windows). Celular/APK (`BUILD_APK.bat`,
  `INSTALAR_CELULAR.bat`) só quando o dono pedir.
- Banco real do dono: `%APPDATA%\com.henrissonnathan\hero_tracker\
  hero_tracker.db`. Migração nova → backup antes (skill BANC, passo 9).

## Regras que o central garante
- Nenhum filho commita; só o central, com OK explícito (L7).
- Skill criada/alterada/que falhou → anotação em
  `D:\project\meu-kit-claude\CAIXA_DE_ENTRADA\` (regra global) e aviso ao dono.
- Resposta ao dono em português, enxuta (caveman full).
