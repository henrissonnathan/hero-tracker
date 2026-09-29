---
name: hero-tracker-json
sigla: JSON
description: >
  Especialista no CONTRATO JSON do hero-tracker: backup completo, pacote de
  um jogo (modelo + personagens) e o formato que alimentará o 2º app de
  teste/simulação. Carregue quando o chat for: mudar export/import, validar
  arquivo, subir formatVersion, documentar o contrato, ou MONTAR um pacote
  JSON de um jogo (mapear jogo em arquivo para o dono importar).
triggers: [JSON, contrato, backup, export, import, pacote, formatVersion, CONTRATO-JSON, validação, 2º-app, mapear-jogo]
---

# JSON — Hero Tracker Contrato JSON

## Por que existe
O JSON é o CONTRATO OFICIAL (skill PROD): o 2º app futuro lê esse formato, e
arquivo de fora é dado não-confiável. Quebrar o contrato quebra backups
antigos do dono e o 2º app. Estável > esperto.

## Escopo deste chat
```
lib/services/export_service.dart    ← export, import, validação, pacote
docs/CONTRATO-JSON.md               ← documento do contrato (fonte humana)
test/export_import_test.dart · test/group_pack_test.dart  ← testes do contrato
  (+ catálogo TestsInfo/docs/TESTES.md se a contagem mudar — regra da TEST)
arquivos .json de pacote (conteúdo de jogo) — fora de lib/
```
### NÃO pode tocar em
- Schema do banco (coluna/tabela nova = BANC; o BANC já inclui o campo novo
  no export) · telas (os botões moram em home_screen e stats_screen = VISL)
- Regra de negócio (FUNC)

## Mapa do export_service.dart
| método | faz |
|---|---|
| `buildExportJson()` | monta o backup completo (testável, sem I/O de arquivo) |
| `exportAll()` | Windows: "salvar como"; Android: compartilhar |
| `importFromFile(path)` | backup completo, mescla, UMA transação |
| `buildGroupPackJson(groupId)` / `exportGroupPack(group)` | pacote de um jogo |
| `importGroupPack(path, targetGroupId)` | preenche um jogo que já existe |
| `_parseAndValidate(content)` | ÚNICA validação — backup e pacote passam por ela |
| `_mesclarStats` | pacote: stats do arquivo mesclam com o modelo por nome |
| `_resolveEdges` | religa parentId por remap e corta ciclo (vira raiz) |

Entradas na UI: menu ⋮ da Home ("Exportar dados (backup)" / "Importar
dados") e ícone ⇅ da tela Estatísticas ("Receber pacote" / "Enviar pacote").

## Regras do contrato (nunca quebre)
1. Validação TOTAL antes de gravar; gravação numa transação só (tudo-ou-nada)
2. Ids nunca confiados — remap; pai ausente vira raiz; ciclo cortado
3. `iconImagePath` SEMPRE descartado (grupo e personagem) — foto não viaja
4. `version` > `ExportService.formatVersion` (hoje **3**) → rejeitado com aviso
5. Campo desconhecido é ignorado; `unitTypeLabels` com `typeKey` desconhecido
   é PULADO (não derruba o arquivo)
6. Limites (constantes no topo da classe): 1000 grupos; 2000 personagens/nós/
   templates por grupo; 500 stats/habilidades por personagem; nome 200; texto
   5000; 50 nomes de tipo por grupo
7. Todo arquivo de versão ANTERIOR continua importando (testado)
8. Pacote: `version` e `kind` ("hero-tracker/pacote-de-grupo") opcionais;
   nada que já existe é sobrescrito (mesmo nome, sem ligar p/ maiúscula);
   stat sem `type` herda do modelo; personagem nasce com o modelo do jogo
9. `bonusKind` só 'flat' | 'percent' (resto vira 'flat')

## Mudar o contrato (receita)
Formato mudou (campo/lista nova ou significado novo) → `formatVersion` +1 →
linha na tabela de versões do docs/CONTRATO-JSON.md → validação no
`_parseAndValidate` → default para arquivo antigo sem o campo → teste de
round-trip + teste de arquivo antigo. Mudança só de validação/limite: sem
bump, mas documente.

## Montar pacote de um jogo à mão (conteúdo)
Mínimo que importa:
```json
{ "group": {
    "statTemplates": [ { "name": "Bônus de ataque", "type": "percent",
                         "category": "Bônus" } ],
    "characters": [ { "name": "Cao Cao", "characterType": "heroi",
                      "stats": [ { "name": "Bônus de ataque", "value": 10 } ] } ] } }
```
- Tipos: `number` | `percent` | `trigger` (usa `triggerText`) | `formula`
  (usa `formulaText`, só texto — não calcula).
- `characterType`: `soldadoNormal` | `heroi` | `comandante` (o NOME exibido é
  por jogo, configurado no app).
- Habilidade: `name`, `description`, `triggerText`, `targetStatName` (tem que
  casar com um status do personagem), `bonusValue`, `bonusKind`.
- Convenção do exemplo RoK: alvo em % → `flat` (soma pontos); alvo número →
  `percent` (multiplica).
- Nomes do jogo (heróis, prédios) são fatos; números podem ser ilustrativos —
  diga isso no arquivo/descrição. Descrições escritas por nós, nunca copiadas
  do jogo. Nenhum dado pessoal no pacote.
- Teste o pacote: `importGroupPack` num jogo vazio (group_pack_test mostra como).

## Portão antes de entregar
```bash
export PATH="/c/flutter/bin:$PATH"
flutter analyze --fatal-infos --no-pub
flutter test --no-pub test/export_import_test.dart test/group_pack_test.dart test/character_photo_test.dart
flutter test --no-pub
```
Sem commit: quem commita é o chat central (L7).

## Handoff
Devolva ao CENT (formato da skill `hero-tracker-central`): versão do contrato
antes → depois, o que um arquivo antigo faz agora, testes novos.
