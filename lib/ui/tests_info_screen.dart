import 'package:flutter/material.dart';

/// Um teste automático, explicado em português: o que ele garante e do que
/// ele te protege.
class TestItem {
  final String garante;
  final String protege;
  const TestItem(this.garante, this.protege);
}

/// Um arquivo de testes = um bloco na tela.
class TestGroup {
  final String emoji;
  final String title;
  final String file;
  final List<TestItem> items;
  const TestGroup(this.emoji, this.title, this.file, this.items);
}

/// Uma sugestão de teste que ainda NÃO existe (o dono escolhe quais quer).
class TestIdea {
  final String letra;
  final String oQue;
  final String porque;
  const TestIdea(this.letra, this.oQue, this.porque);
}

/// Catálogo dos testes automáticos, em linguagem do dono.
///
/// É um RESUMO curado (não roda os testes — quem roda é o `TESTAR.bat`), mas
/// não pode mentir: `test/tests_info_test.dart` conta os testes de verdade na
/// pasta `test/` e compara com [totalTests]. Criou teste e esqueceu de listar
/// aqui? O portão fica vermelho. Doc equivalente: `docs/TESTES.md`.
class TestsInfo {
  const TestsInfo._();

  static const List<TestGroup> groups = [
    TestGroup('💾', 'Backup', 'export_import_test.dart', [
      TestItem('Exportar → apagar tudo → importar traz tudo de volta, '
          'inclusive a árvore religada',
          'Backup que restaura pela metade'),
      TestItem('Grupo cujo "pai" não existe no arquivo vira raiz (não some)',
          'Dados invisíveis depois de importar'),
      TestItem('Ciclo de pais (A é pai de B, B é pai de A) vira raiz',
          'Grupos sumindo da tela sem explicação'),
      TestItem('Arquivo bagunçado é recusado sem tocar no banco',
          'Backup ruim estragar seus dados bons'),
      TestItem('Backup de versão mais nova é recusado com aviso',
          'App velho lendo arquivo novo errado'),
      TestItem('Nome gigante (500 letras) é recusado antes de gravar',
          'Entrada de dado adulterado'),
      TestItem('Texto gigante (6000 letras) é recusado antes de gravar',
          'Import pela metade — é tudo ou nada'),
    ]),
    TestGroup('🗄️', 'Banco de dados', 'migration_parity_test.dart', [
      TestItem('Banco novo e banco antigo atualizado ficam idênticos (v1 → v11)',
          'Crash ao abrir o app depois de atualizar'),
      TestItem('O mesmo, começando da versão 5',
          'Bug só em quem já tinha dados antigos'),
    ]),
    TestGroup('📦', 'Seus dados (nada some ao salvar)',
        'model_roundtrip_test.dart', [
      TestItem('Grupo: salva e lê de volta igual, campo por campo',
          'Categoria/foto/limite do grupo sumindo calado'),
      TestItem('Personagem: nome, papel, notas, estrelas, tipo e nível',
          'Nível ou estrelas voltando ao zero'),
      TestItem('Status: tipo, valor, gatilho, fórmula e ordem',
          'Fórmula ou % virando outra coisa'),
      TestItem('Modelo de status: inclusive a categoria',
          'Status perdendo a categoria'),
      TestItem('Nó da árvore: pai, custo, desbloqueado',
          'Árvore embaralhada'),
      TestItem('Habilidade: gatilho, stat alvo, bônus e toggle',
          'Habilidade perdendo o efeito configurado'),
      TestItem('Estrelas: estrela cheia + sub-nível',
          'Rank de estrelas errado'),
    ]),
    TestGroup('⚙️', 'Regras do app', 'group_stat_template_test.dart', [
      TestItem('Personagem novo nasce com os status do modelo do grupo',
          'Ter que digitar tudo à mão sempre'),
      TestItem('Personagem criado ANTES do modelo continua intacto',
          'Dados antigos mexidos sem você mandar'),
      TestItem('Grupo sem modelo: personagem nasce vazio (normal)',
          'Status fantasma aparecendo'),
      TestItem('Sub-grupo herda o modelo do pai mais próximo',
          'Repetir o modelo em cada sub-grupo'),
      TestItem('As caixinhas funcionam: só o marcado é copiado',
          'Herói recebendo status que não é dele'),
      TestItem('Pais em ciclo não travam o app (corta o laço)',
          'App congelado pra sempre'),
      TestItem('Apagar nó pai deixa o filho solto, não quebrado',
          'Árvore corrompida'),
      TestItem('Habilidade: criar, ligar o toggle e apagar — tudo persiste',
          'Toggle que "esquece" ao fechar'),
      TestItem('Editar/apagar o modelo NÃO mexe em quem já foi criado',
          'Seus heróis mudando sozinhos'),
    ]),
    TestGroup('🎮', 'Exemplo Rise of Kingdoms', 'seed_service_test.dart', [
      TestItem('O mapa monta os 4 sub-grupos (Comandantes, Tropas, Pesquisa, '
          'Construção), com modelo próprio, 6 comandantes, árvore, e toda '
          'habilidade apontando pra um status que existe',
          'Exemplo chegando pela metade ou com toggle sem efeito'),
      TestItem('"Refazer o exemplo" apaga o antigo inteiro (com sub-grupos) '
          'em vez de empilhar cópias',
          'Exemplos duplicados e lixo no banco'),
    ]),
    TestGroup('🏷️', 'Nomes dos tipos de unidade', 'unit_type_label_test.dart', [
      TestItem('Renomear no jogo ("Herói" → "Comandante") vale nos sub-grupos, '
          'e um sub-grupo pode trocar só um tipo',
          'Ter que renomear em cada sub-grupo'),
      TestItem('Regravar o mesmo tipo troca o nome (não empilha) e '
          '"Restaurar padrão" volta ao nome do app',
          'Lista de nomes repetidos e nome que não volta'),
      TestItem('O backup leva os nomes que você deu',
          'Perder seus nomes ao restaurar um backup'),
      TestItem('O card do personagem mostra o nome que VOCÊ deu ao tipo',
          'Card dizendo "Herói" depois de você renomear'),
    ]),
    TestGroup('🧱', 'Status por linha', 'stats_layout_test.dart', [
      TestItem('Padrão: 2 status por linha (mede a posição real na tela)',
          'Tela esticada, com um status por vez'),
      TestItem('Escolhendo 1 por linha, cada status ocupa a sua',
          'A escolha de colunas não valer'),
    ]),
    TestGroup('📸', 'Foto de herói/tropa', 'character_photo_test.dart', [
      TestItem('A foto do herói é salva — e "remover foto" apaga de verdade',
          'Foto que volta sozinha depois de você tirar'),
      TestItem('A limpeza de sobras NÃO apaga a foto de um herói (só a sobra)',
          'Suas fotos sumindo na próxima vez que abrir o app'),
      TestItem('O backup NÃO leva o caminho da foto pra fora',
          'Caminho do seu PC vazando no arquivo de backup'),
      TestItem('Card com foto mostra a imagem; card sem foto mostra o emoji',
          'Quadrado vazio no lugar do herói'),
    ]),
    TestGroup('🖥️', 'Telas', 'widget_test.dart', [
      TestItem('O app de verdade abre até a tela inicial',
          'Tela branca / app que não abre'),
      TestItem('Grupo sem foto mostra o emoji', 'Ícone quebrado'),
      TestItem('Grupo com foto apagada volta pro emoji',
          'Quadrado preto no lugar do ícone'),
      TestItem('A tela de status agrupa por categoria',
          'Bagunça na tela de status'),
    ]),
    TestGroup('📦', 'Pacote de um jogo (JSON)', 'group_pack_test.dart', [
      TestItem('Enviar pacote → receber em outro jogo traz modelo, heróis e '
          'habilidades (sem o caminho da foto)',
          'Pacote que chega pela metade'),
      TestItem('JSON escrito à mão com só nome + valor funciona: o tipo vem '
          'do modelo do jogo',
          'Arquivo simples recusado ou com tipo errado'),
      TestItem('Receber pacote NÃO troca status nem herói que você já tem',
          'Seus dados sobrescritos por um arquivo de fora'),
      TestItem('Arquivo que não é pacote é recusado sem gravar nada',
          'Jogo bagunçado por arquivo errado'),
    ]),
    TestGroup('📝', 'Formulário de status', 'stat_form_dialog_test.dart', [
      TestItem('Nome com "Bônus" já escolhe Porcentagem; atalho 10% preenche',
          'Ter que escolher o tipo toda vez'),
      TestItem('A conta (fórmula) se monta só tocando, sem digitar × ÷',
          'Fórmula impossível de escrever no teclado'),
      TestItem('Gatilho já usado no jogo entra com um toque',
          'Redigitar o mesmo gatilho (e errar a grafia)'),
      TestItem('Sem nome não salva e o aviso aparece no próprio campo',
          'Status sem nome na lista'),
    ]),
    TestGroup('➕', 'Criar herói pela tela', 'character_create_test.dart', [
      TestItem('Enter cria com o tipo já sugerido e abre a tela do herói, '
          'com os status do modelo',
          'Ter que tocar no tipo e no card toda vez'),
      TestItem('Nome vazio ou repetido: aviso no próprio campo e nada gravado',
          'Herói sem nome ou dois com o mesmo nome'),
      TestItem('"Criar outro" grava, avisa, mantém o tipo e volta o foco '
          'no nome', 'Abrir e fechar o dialog para cada herói'),
      TestItem('Editar herói com nome repetido ANTIGO salva sem trocar o nome',
          'Herói antigo que não dá mais para editar'),
      TestItem('"Nenhum" no modelo: o herói nasce sem status',
          'Caixinhas que não valem na hora de criar'),
    ]),
    TestGroup('🎯', 'Tipo sugerido', 'character_type_suggestion_test.dart', [
      TestItem('Grupo vazio: Heróis sugere herói, o resto sugere soldado',
          'Tipo errado já marcado no primeiro herói'),
      TestItem('O tipo mais comum no grupo vence', 'Sugestão que ignora o jogo'),
      TestItem('Empate: vale o da categoria', 'Sugestão que muda sozinha'),
    ]),
    TestGroup('🧩', 'Padrões de tela', 'option_card_test.dart', [
      TestItem('Cartão de escolha: toque (dedo e leitor de tela) escolhe, '
          'fala "selecionado", 48×48',
          'Opção que o leitor de tela anuncia mas não escolhe'),
      TestItem('Cartão de escolha pelo teclado: Tab chega e Enter escolhe',
          'Opção que o teclado do PC não alcança'),
      TestItem('Ícone de emoji é um quadrado de 48×48', 'Emoji difícil de acertar'),
      TestItem('⋮ mostra Editar/Apagar e Apagar sempre pede confirmação',
          'Apagar sem querer com um toque'),
    ]),
    TestGroup('👆', 'Tamanho dos botões', 'tap_target_test.dart', [
      TestItem('Tela do jogo e dialog de criação: todo botão >= 48×48 '
          '(tema real, no Android e no Windows)',
          'Botão pequeno demais para o dedo — ou só no PC'),
      TestItem('Tela do herói (status, habilidade, estrelas): >= 48×48',
          'Errar o toque e editar a coisa errada'),
      TestItem('Árvore, inclusive a bolinha de desbloquear: >= 48×48',
          'Desbloquear o nó errado'),
      TestItem('Tela de estatísticas: >= 48×48', 'Menu ⋮ difícil de acertar'),
    ]),
    TestGroup('🧪', 'Esta própria tela', 'tests_info_test.dart', [
      TestItem('A tela de testes abre e mostra os blocos',
          'Esta tela quebrar sem ninguém ver'),
      TestItem('A conta bate: teste novo não listado aqui deixa o TESTAR '
          'vermelho', 'Esta tela virar mentira com o tempo'),
    ]),
  ];

  /// O que robô nenhum julga — só os olhos do dono.
  static const List<String> manual = [
    'Está fácil de usar? Quantos cliques até fazer o que você queria?',
    'Está bonito? Cores, tamanho de letra, coisa apertada demais.',
    'Faz sentido pro jogo? O modelo de status do RoK está do jeito certo?',
    'Foto de grupo e de herói: escolher uma imagem de verdade no Windows e '
        'ver se aparece (único item de função aqui — abre a janela do '
        'Windows, que robô nenhum abre).',
  ];

  /// Buracos que hoje ninguém testa sozinho — o dono escolhe quais virar teste.
  static const List<TestIdea> ideas = [
    TestIdea('A', 'Foto (grupo e herói): recusar arquivo falso e imagem '
        'gigante ("bomba de pixels"), virar PNG interno',
        'É a parte de segurança; hoje só é testada por você abrindo o app'),
    TestIdea('B', 'Toggle de habilidade NA TELA: ligar e ver o número mudar',
        'É o efeito que você mais olha (hoje testo só o dado)'),
    TestIdea('D', 'Exportar para arquivo de verdade',
        'Fecha o último buraco do backup (hoje testo o conteúdo)'),
    TestIdea('E', 'Tela da árvore de habilidades: desbloquear e criar '
        'sub-habilidade pela tela',
        'Hoje só o tamanho dos botões dela é testado'),
  ];

  /// Total de testes automáticos descritos aqui.
  static int get totalTests =>
      groups.fold(0, (sum, g) => sum + g.items.length);
}

/// Tela "Testes do app": mostra, em português, tudo o que já é testado
/// sozinho, o que ainda depende dos olhos do dono e o que dá pra automatizar.
class TestsInfoScreen extends StatelessWidget {
  const TestsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Testes do app')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _Header(total: TestsInfo.totalTests),
          const SizedBox(height: 16),
          const _SectionTitle(
            emoji: '✅',
            title: 'Já testado sozinho',
            subtitle: 'Não precisa conferir na mão. Toque para abrir cada bloco.',
          ),
          ...TestsInfo.groups.map((g) => _GroupTile(group: g)),
          const SizedBox(height: 20),
          const _SectionTitle(
            emoji: '👀',
            title: 'Só você pode julgar',
            subtitle: 'Robô testa se funciona. Isto aqui é gosto e sentido.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < TestsInfo.manual.length; i++)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: cs.secondaryContainer,
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.onSecondaryContainer)),
                      ),
                      title: Text(TestsInfo.manual[i],
                          style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            emoji: '🤖',
            title: 'Posso automatizar depois',
            subtitle: 'Diga quais você quer — sugestão: A e B primeiro.',
          ),
          ...TestsInfo.ideas.map((idea) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(idea.letra,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer)),
                  ),
                  title: Text(idea.oQue,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(idea.porque,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 20),
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💬 Sua vez',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Algum teste acima é desnecessário? Falta algo que te dá '
                    'medo de quebrar? Quais das ideias (A, B, D, E) você quer? '
                    'É só me falar — o que você apontar vira teste.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('$total',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('testes automáticos',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  Text(
                    'Rodam sozinhos com dois cliques no TESTAR.bat. '
                    'Tudo o que está aqui você NÃO precisa conferir na mão.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _SectionTitle(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji  $title',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final TestGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: const Border(),
        leading: Text(group.emoji, style: const TextStyle(fontSize: 22)),
        title: Text(group.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${group.items.length} testes',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.garante,
                            style: const TextStyle(
                                fontSize: 13, height: 1.3)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text('🛡️ te protege de: ${item.protege}',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                            height: 1.3)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
