# 🧪 TESTES — o que o robô já testa por você

> Última atualização: 2026-09-29 · **51 testes automáticos, todos verdes**
> Como rodar: dois cliques no **`TESTAR.bat`**. Ele mesmo diz no final:
> `=== TUDO VERDE - pode commitar. ===` (ou aponta exatamente o que quebrou).
>
> **📱 Isto também está DENTRO do app:** menu **⋮** → **"Testes do app"**.
> A tela (`lib/ui/tests_info_screen.dart`) é a versão navegável desta lista, e
> `test/tests_info_test.dart` compara a conta dela com os testes reais da pasta
> `test/` — se um teste novo não for descrito lá, o portão fica **vermelho**.

**A ideia deste arquivo:** você não gosta de testar na mão — e não deveria mesmo.
Aqui está, em português claro, **tudo o que já é testado sozinho** (você não
precisa conferir), **o que ainda depende dos seus olhos** (lista curta), e
**o que eu sugiro automatizar depois** pra essa lista curta ficar menor ainda.

---

## 1. O que já é testado sozinho (não precisa conferir na mão)

### 💾 Backup — 7 testes (`export_import_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Exportar → apagar tudo → importar traz tudo de volta, inclusive a **árvore** religada | Backup que restaura pela metade |
| Grupo cujo "pai" não existe no arquivo **vira raiz** (não some) | Dados invisíveis depois de importar |
| Ciclo de pais (A é pai de B, B é pai de A) **vira raiz** | Grupos sumindo da tela sem explicação |
| Arquivo bagunçado é **recusado sem tocar no banco** | Backup ruim estragar seus dados bons |
| Backup de **versão mais nova** é recusado com aviso | App velho lendo arquivo novo errado |
| Nome gigante (500 letras) é recusado **antes de gravar** | Entrada de dado malicioso/quebrado |
| Texto gigante (6000 letras) é recusado **antes de gravar** | Idem — é tudo-ou-nada, nunca meio-a-meio |

### 🗄️ Banco de dados — 2 testes (`migration_parity_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Banco **novo** e banco **antigo atualizado** ficam **idênticos** (v1 → v11) | Crash ao abrir o app depois de atualizar |
| O mesmo, começando da versão 5 | Bug só em quem já tinha dados antigos |

> Tradução: quando eu adicionar campo novo, se eu esquecer de cuidar de quem já
> tem dados salvos, **o teste grita antes de chegar em você**.

### 📦 Modelos de dados — 7 testes (`model_roundtrip_test.dart`)

Cada tipo de dado (Grupo, Personagem, Status, Modelo de status, Nó da árvore,
Habilidade, Estrelas) é salvo e lido de volta: **o que entra tem que sair igual,
campo por campo**. Protege banco **e** backup ao mesmo tempo. Se quebrasse, um
campo (ex.: nível, categoria, foto) sumiria calado ao salvar.

### ⚙️ Regras do app — 9 testes (`group_stat_template_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Personagem novo **nasce com os status do modelo** do grupo | Ter que digitar tudo à mão sempre |
| Personagem criado **antes** do modelo continua intacto | Dados antigos mexidos sem você mandar |
| Grupo sem modelo → personagem nasce vazio (normal) | Status fantasma aparecendo |
| Sub-grupo **herda** o modelo do pai mais próximo | Ter que repetir o modelo em cada sub-grupo |
| As **caixinhas** funcionam (só os marcados são copiados) | Herói recebendo status que não é dele |
| Pais em ciclo **não travam o app** (corta o laço) | App congelado pra sempre |
| Apagar nó pai deixa o filho **solto**, não quebrado | Árvore corrompida |
| Habilidade: criar, ligar o **toggle**, apagar — tudo persiste | Toggle que "esquece" ao fechar |
| Editar/apagar o **modelo NÃO mexe** em quem já foi criado | Seus heróis mudando sozinhos |

### 🎮 Exemplo Rise of Kingdoms — 2 testes (`seed_service_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| O mapa monta os **4 sub-grupos** (Comandantes, Tropas, Pesquisa, Construção), cada um com **modelo próprio**, **6 comandantes** já **com foto**, a **árvore**, e **toda habilidade apontando pra um status que existe** | Exemplo chegando pela metade ou com toggle sem efeito |
| O comandante **NÃO tem Ataque/Defesa/Vida** (isso é das tropas) e o jogo mostra "Herói" como **Comandante** | O mapa mentir sobre como o RoK funciona |
| **"Refazer o exemplo"** apaga o antigo inteiro (com sub-grupos e fotos) em vez de empilhar cópias | Exemplos duplicados e lixo no banco |

### 🏷️ Nomes dos tipos de unidade — 4 testes (`unit_type_label_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Renomear no jogo ("Herói" → "Comandante") **vale nos sub-grupos**, e um sub-grupo pode trocar **só um** tipo | Ter que renomear em cada sub-grupo |
| Regravar o mesmo tipo **troca** o nome (não empilha) e **"Restaurar padrão"** volta ao nome do app | Lista de nomes repetidos e nome que não volta |
| O **backup leva** os nomes que você deu | Perder seus nomes ao restaurar um backup |
| O card do personagem mostra **o nome que VOCÊ deu** | Card dizendo "Herói" depois de você renomear |

### 🧱 Status por linha — 2 testes (`stats_layout_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Padrão: **2 status por linha** (mede a posição real na tela) | Tela esticada, com um status por vez |
| Escolhendo **1 por linha**, cada status ocupa a sua | A escolha de colunas não valer |

### 📸 Foto de herói/tropa — 4 testes (`character_photo_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| A foto do herói é salva — e **"remover foto" apaga de verdade** | Foto que volta sozinha depois de você tirar |
| A limpeza de sobras **NÃO apaga a foto de um herói** (só a sobra) | Suas fotos sumindo na próxima vez que abrir o app |
| O **backup NÃO leva o caminho da foto** pra fora | Caminho do seu PC vazando no arquivo de backup |
| Card **com** foto mostra a imagem; card **sem** foto mostra o emoji | Quadrado vazio no lugar do herói |

### 🖥️ Telas — 4 testes (`widget_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| O **app de verdade abre** até a tela inicial | Tela branca / app que não abre |
| Grupo sem foto mostra o **emoji** | Ícone quebrado |
| Grupo com foto **apagada** volta pro emoji (não quebra) | Quadrado preto no lugar do ícone |
| A tela de status **agrupa por categoria** | Bagunça na tela de status |

### 📦 Pacote de um jogo (JSON) — 4 testes (`group_pack_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Enviar pacote → receber em outro jogo traz **modelo, heróis e habilidades** (sem caminho de foto) | Pacote que chega pela metade |
| JSON **escrito à mão** com só nome + valor funciona: o tipo vem do modelo | Arquivo simples recusado ou com tipo errado |
| Receber pacote **NÃO troca** status nem herói que você já tem | Seus dados sobrescritos por arquivo de fora |
| Arquivo que não é pacote é **recusado sem gravar nada** | Jogo bagunçado por arquivo errado |

### 📝 Formulário de status — 4 testes (`stat_form_dialog_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| Nome com "Bônus" **já escolhe Porcentagem**; atalho 10% preenche | Ter que escolher o tipo toda vez |
| A **conta (fórmula) se monta só tocando**, sem digitar × ÷ | Fórmula impossível de escrever no teclado |
| **Gatilho já usado** no jogo entra com um toque | Redigitar o mesmo gatilho (e errar a grafia) |
| Sem nome não salva e o **aviso aparece no próprio campo** | Status sem nome na lista |

### 🧪 Esta própria lista — 2 testes (`tests_info_test.dart`)

| O teste garante que… | Se quebrasse, você perderia |
|---|---|
| A tela "Testes do app" abre e mostra os blocos | Esta tela quebrar sem ninguém ver |
| **A conta bate** com os testes reais da pasta `test/` | Esta lista virar mentira com o tempo |

---

## 2. O que ainda depende dos seus olhos (lista curta)

Robô testa se **funciona**. Só você julga se está **bonito, fácil e faz sentido
pro jogo**. Então sobrou pra você só isto:

1. **Está fácil de usar?** Quantos cliques até fazer o que você queria?
2. **Está bonito?** Cores, tamanho de letra, coisa apertada demais.
3. **Faz sentido pro jogo?** Ex.: o modelo de status do RoK está do jeito certo?
4. **Foto de grupo e de herói** — escolher uma imagem de verdade e ver se
   aparece. *(É o único item de função aqui, porque abre a janela do
   Windows, que robô nenhum abre — ver §3.)*

**Não perca tempo conferindo:** salvar, reabrir, backup, importar, criar herói
com o modelo, ligar toggle de habilidade. Tudo isso o robô já confere.

---

## 3. O que EU sugiro automatizar depois (pra sobrar menos pra você)

Estas são as partes que **hoje ninguém testa sozinho** — minha proposta, em
ordem de importância. **Diga quais você quer** (ou nenhuma, ou outra ideia sua):

| # | O que passaria a ser automático | Por que importa |
|---|---|---|
| **A** | **Foto (grupo e herói)**: testar o pipeline anti-vírus (recusa arquivo falso, imagem gigante "bomba de pixels", vira PNG interno) | É a parte de **segurança**; hoje só é testada por você abrindo o app |
| **B** | **Toggle de habilidade na tela**: ligar e ver o número mudar na tela (hoje só testo o dado, não a tela) | É o efeito que você mais olha |
| **C** | **Criar herói pela tela** com as caixinhas marcadas | O caminho que mais se usa no dia a dia |
| **D** | **Exportar pra arquivo de verdade** (hoje testo o conteúdo, não o salvar) | Fecha o último buraco do backup |
| **E** | **Tela da árvore** de habilidades | Ainda sem nenhum teste de tela |

---

## 4. Sua vez — me diga o que achou

Coisas que ajudam muito eu acertar:

- Algum teste da lista §1 que você acha **desnecessário**? (posso tirar)
- Falta algo que te **dá medo de quebrar** e não está testado? (esse vira teste)
- Da lista §3, quais você quer? (sugestão minha: **A** e **B** primeiro)
- O `TESTAR.bat` está fácil? Quer que ele rode **sozinho antes de cada
  salvamento**, sem você clicar em nada? (dá pra ligar)
