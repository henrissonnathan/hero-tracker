# 📄 Contrato JSON do Hero Tracker — formato oficial de backup/troca

> Este é o formato que o **2º app (teste/simulação)** vai consumir.
> Regras de ouro: **versionado**, **retrocompatível** (import aceita QUALQUER
> versão anterior, para sempre) e **validação rígida** — arquivo malformado,
> adulterado ou fora dos limites é rejeitado POR INTEIRO antes de qualquer
> escrita no banco. Fonte da verdade da implementação:
> `lib/services/export_service.dart`.

## Versão atual: **3** (2026-07-25)

| Versão | Mudança |
|--------|---------|
| 1 | grupos + personagens + stats (+ templates e habilidades entraram ainda como v1) |
| 2 | + `skillNodes` por grupo (árvore com remap de ids); validação rígida; limites |
| 3 | + `unitTypeLabels` por grupo (nomes dos tipos de unidade; `typeKey` desconhecido é pulado) |

## Estrutura

```json
{
  "version": 3,
  "exportedAt": "2026-07-25T12:00:00.000",
  "groups": [
    {
      "id": 1,                  // id ORIGINAL — o import sempre gera novos
      "parentId": null,          // hierarquia; religada por remap no import
      "name": "Rise of Kingdoms",
      "description": "…",
      "iconEmoji": "⚔️",
      "iconImagePath": "…",      // exportado, mas SEMPRE descartado no import
      "createdAt": "…",
      "maxHeroesPerSquad": 2,
      "maxCommandersPerSquad": 1,
      "contentCategory": "general",
      "statTemplates": [ { "name": "Vida", "type": "number", "defaultValue": 100,
                           "category": "Status base", "sortOrder": 0 } ],
      "skillNodes":   [ { "id": 7, "parentId": null, "name": "Pesquisa I",
                           "isUnlocked": 1, "costPoints": 1, "sortOrder": 0 } ],
      // v3: como ESTE jogo chama os tipos de unidade (herda nos sub-grupos)
      "unitTypeLabels": [ { "typeKey": "heroi", "label": "Comandante",
                            "emoji": "⚔️" } ],
      "characters": [
        {
          "id": 3, "name": "Herói", "role": "Tank", "notes": "…",
          "starStars": 2, "starSubLevel": 5, "createdAt": "…",
          "characterType": "heroi", "level": 42,
          "iconImagePath": "…",   // idem: exportado, SEMPRE descartado no import
          "stats":     [ { "name": "Ataque", "type": "number", "value": 120,
                           "sortOrder": 0 } ],
          "abilities": [ { "name": "Fúria", "description": "…",
                           "triggerText": "atacando uma base",
                           "targetStatName": "Ataque", "bonusValue": 20,
                           "bonusKind": "flat", "isActive": 0, "sortOrder": 0 } ]
        }
      ]
    }
  ]
}
```

## Regras do import (segurança)

1. **Validação total antes de gravar**: o arquivo inteiro é decodificado e
   validado; qualquer violação → NADA entra no banco (tudo-ou-nada).
2. **Ids nunca são confiados**: todo id vem só como referência de remap;
   o banco de destino gera ids novos. `parentId` de grupo e de nó de árvore
   são religados pelo mapa id-antigo→id-novo; **pai ausente do backup → vira
   raiz** (nunca aponta para dado pré-existente não relacionado).
3. **Caminhos de arquivo (`iconImagePath`) são sempre descartados** — tanto o
   do grupo quanto o do personagem (v10). Fotos não viajam pelo JSON
   (device-específicas; vetor de ataque). Coberto por
   `test/character_photo_test.dart`.
4. **Versão mais nova que o app → rejeitado** com aviso para atualizar.
5. Campos desconhecidos são ignorados (compatibilidade para frente). Idem para
   `unitTypeLabels` com `typeKey` fora dos três tipos conhecidos
   (`soldadoNormal`/`heroi`/`comandante`): a entrada é PULADA e o resto do
   arquivo importa normalmente — nunca derruba o backup inteiro.

## Limites (valores atuais — rejeição acima deles)

| Limite | Valor |
|--------|-------|
| Grupos por arquivo | 1000 |
| Personagens / nós / templates por grupo | 2000 |
| Stats / habilidades por personagem | 500 |
| Tamanho de nome | 200 caracteres |
| Tamanho de textos (descrição/notas/gatilho/fórmula) | 5000 caracteres |

## Por que é impossível "colocar vírus" por aqui

- O arquivo é **só dados** (JSON): nunca é executado, só decodificado.
- Strings passam por limite de tamanho e vão para campos de TEXTO do SQLite
  via parâmetros (`?` + whereArgs) — sem interpolação de SQL.
- Caminhos de arquivo são descartados; nenhuma referência externa é seguida.
- Arquivo que não decodifica/valida é rejeitado inteiro, sem efeito colateral.

## Pacote de UM jogo (modelo + personagens) — 2026-09-29

Segundo "envelope" do MESMO formato de grupo acima, para **preencher um jogo
que já existe** (tela Estatísticas → ícone ⇅ → *Receber pacote*). *Enviar
pacote deste jogo* gera o arquivo de exemplo. Não é versão nova: o grupo
dentro dele passa pela mesma validação do backup (limites, textos, tipos).

```json
{
  "version": 3,                              // opcional no pacote (= atual)
  "kind": "hero-tracker/pacote-de-grupo",    // opcional
  "group": {
    "statTemplates": [
      { "name": "Bônus de ataque", "type": "percent", "defaultValue": 0,
        "category": "Bônus" }
    ],
    "characters": [
      { "name": "Cao Cao", "characterType": "heroi", "level": 60,
        "stats": [ { "name": "Bônus de ataque", "value": 10 } ],
        "abilities": [ { "name": "Carga", "targetStatName": "Bônus de ataque",
                         "bonusValue": 5, "bonusKind": "flat" } ] },
      { "name": "Boudica" }
    ]
  }
}
```

Regras do *Receber pacote* (`ExportService.importGroupPack`):

1. Aceita `{"group": {...}}` (com ou sem `kind`/`version`) **ou** um backup
   com exatamente 1 grupo. Qualquer outra coisa é recusada sem gravar nada.
2. Só `statTemplates` e `characters` entram. `parentId`, `skillNodes`,
   `unitTypeLabels`, nome/ícone do grupo e caminhos de foto são ignorados.
3. **Nada que já existe é sobrescrito**: status do modelo ou personagem com o
   mesmo nome (sem ligar para maiúscula) fica como estava; a mensagem conta
   quantos foram mantidos.
4. Personagem novo **nasce com o modelo do jogo** (igual à tela). Os `stats`
   dele no arquivo **mesclam por nome**: mesmo nome troca o valor, nome novo
   entra no fim. Stat **sem `type`** herda o tipo do status do modelo — um
   JSON feito à mão só precisa de `name` + `value`.
5. Tudo numa transação: ou entra o pacote inteiro, ou nada.

## Evolução (obrigatório para toda fase futura)

- Nova tabela/campo no export ⇒ **bump da versão** + linha na tabela de
  histórico acima + validação correspondente no import.
- O import de TODAS as versões anteriores continua funcionando (testado).
