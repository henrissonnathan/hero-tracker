import '../models/character.dart';
import '../models/character_ability.dart';
import '../models/character_stat.dart';
import '../models/character_type.dart';
import '../models/content_category.dart';
import '../models/game_group.dart';
import '../models/group_stat_template.dart';
import '../models/skill_node.dart';
import '../models/star_rank.dart';
import '../models/stat_type.dart';
import '../models/unit_type_label.dart';
import '../repositories/tracker_repository.dart';
import 'icon_image_store.dart';

/// Serviço de EXEMPLO — monta, dentro do app, um MAPA COMPLETO de um jogo real
/// (Rise of Kingdoms) para o dono analisar sem digitar nada.
///
/// O mapa usa TODAS as peças do app de uma vez, para servir de referência:
/// jogo raiz → 4 sub-grupos por categoria (Comandantes, Tropas, Pesquisa,
/// Construção), cada um com seu PRÓPRIO modelo de status em categorias, com
/// os 4 tipos de status (número, %, gatilho e fórmula), heróis com habilidades
/// (gatilho + efeito) e duas árvores.
///
/// Honestidade sobre os dados: os NOMES (comandantes, habilidades, tropas,
/// pesquisas, construções) e as regras conhecidas do jogo — como o triângulo
/// infantaria › cavalaria › arqueiro › infantaria — são do jogo. Já os NÚMEROS
/// são ILUSTRATIVOS: variam por nível, estrela, talento e versão, então servem
/// de ponto de partida para o dono ajustar com os valores da conta dele.
///
/// É puramente ADITIVO (L1): cria UM grupo raiz novo e independente; apagar
/// esse grupo desfaz tudo. Usa o mesmo repositório da UI, sem nada por fora.
class SeedService {
  SeedService._();
  static final SeedService instance = SeedService._();

  /// Nome do grupo de exemplo — também usado para achar/substituir.
  static const String exampleGroupName = 'Rise of Kingdoms (exemplo)';

  // ─── Modelos de status de cada sub-grupo ──────────────────────────────────

  /// Comandantes.
  ///
  /// ⚠️ Correção do dono (2026-07-25): no Rise of Kingdoms o comandante NÃO
  /// tem Ataque/Defesa/Vida próprios — quem tem esses atributos são as TROPAS
  /// que ele leva (ver [_modelTroops]). O comandante entra na conta por outro
  /// caminho: a QUANTIDADE de tropa que ele consegue levar e os BÔNUS que as
  /// habilidades dele dão para essas tropas. Por isso este modelo é quase todo
  /// de porcentagem.
  static const List<_StatSpec> _modelCommanders = [
    _StatSpec('Capacidade de tropas', StatType.number, 0,
        'Tropas que ele leva'),
    _StatSpec('Tropa favorita', StatType.trigger, 0, 'Tropas que ele leva'),
    _StatSpec('Bônus de ataque das tropas', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de defesa das tropas', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de vida das tropas', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Redução de dano recebido', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de dano de habilidade', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de dano normal', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de velocidade de marcha', StatType.percent, 0,
        'Bônus (%)'),
    _StatSpec('Bônus contra bárbaros', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Bônus de cura', StatType.percent, 0, 'Bônus (%)'),
    _StatSpec('Custo de fúria', StatType.number, 1000, 'Habilidade ativa'),
    _StatSpec('Dano da habilidade ativa', StatType.number, 0,
        'Habilidade ativa'),
    _StatSpec('Poder da marcha', StatType.formula, 0, 'Cálculos',
        formula: 'Capacidade de tropas × (1 + Bônus de ataque das tropas ÷ 100)'),
  ];

  /// Tropas: atributos, custo de treino e a regra do triângulo (gatilho).
  static const List<_StatSpec> _modelTroops = [
    _StatSpec('Ataque', StatType.number, 100, 'Atributos'),
    _StatSpec('Defesa', StatType.number, 100, 'Atributos'),
    _StatSpec('Vida', StatType.number, 100, 'Atributos'),
    _StatSpec('Velocidade', StatType.number, 100, 'Atributos'),
    _StatSpec('Carga', StatType.number, 1000, 'Atributos'),
    _StatSpec('Comida', StatType.number, 0, 'Custo de treino'),
    _StatSpec('Madeira', StatType.number, 0, 'Custo de treino'),
    _StatSpec('Tempo de treino (s)', StatType.number, 0, 'Custo de treino'),
    _StatSpec('Vantagem contra', StatType.trigger, 0, 'Regra do jogo'),
  ];

  /// Pesquisa: só o custo por nível (o conteúdo em si é a árvore).
  static const List<_StatSpec> _modelResearch = [
    _StatSpec('Comida', StatType.number, 0, 'Custo por nível'),
    _StatSpec('Madeira', StatType.number, 0, 'Custo por nível'),
    _StatSpec('Pedra', StatType.number, 0, 'Custo por nível'),
    _StatSpec('Ouro', StatType.number, 0, 'Custo por nível'),
    _StatSpec('Tempo (h)', StatType.number, 0, 'Custo por nível'),
  ];

  /// Construção: nível atual, custo do próximo nível e o pré-requisito.
  static const List<_StatSpec> _modelBuildings = [
    _StatSpec('Nível atual', StatType.number, 1, 'Progresso'),
    _StatSpec('Comida', StatType.number, 0, 'Custo do próximo nível'),
    _StatSpec('Madeira', StatType.number, 0, 'Custo do próximo nível'),
    _StatSpec('Pedra', StatType.number, 0, 'Custo do próximo nível'),
    _StatSpec('Tempo (h)', StatType.number, 0, 'Custo do próximo nível'),
    _StatSpec('Pré-requisito', StatType.trigger, 0, 'Regra'),
  ];

  // ─── Consultar / remover ──────────────────────────────────────────────────

  /// O grupo raiz do exemplo, ou null se não existir.
  Future<GameGroup?> findExample() async {
    final roots = await TrackerRepository.instance.getRootGroups();
    for (final g in roots) {
      if (g.name == exampleGroupName) return g;
    }
    return null;
  }

  Future<bool> exampleExists() async => (await findExample()) != null;

  /// Apaga o exemplo inteiro. Apaga os sub-grupos EXPLICITAMENTE em vez de
  /// confiar no CASCADE: bancos muito antigos ganharam `parentId` por ALTER
  /// TABLE, que no SQLite não cria a chave estrangeira (fóssil documentado em
  /// migration_parity_test.dart). Assim funciona em qualquer banco.
  Future<void> removeExample() async {
    final root = await findExample();
    if (root == null) return;
    await _deleteTree(root.id!);
  }

  Future<void> _deleteTree(int groupId) async {
    final repo = TrackerRepository.instance;
    for (final sub in await repo.getSubGroups(groupId)) {
      await _deleteTree(sub.id!);
    }
    // As fotos geradas saem junto — senão viram PNG órfão até o próximo boot.
    for (final c in await repo.getCharactersByGroup(groupId)) {
      await IconImageStore.deleteIcon(c.iconImagePath);
    }
    await repo.deleteGroup(groupId);
  }

  // ─── Montagem do mapa ─────────────────────────────────────────────────────

  /// Cria o mapa de exemplo completo e devolve o grupo raiz.
  Future<GameGroup> createExample() async {
    final repo = TrackerRepository.instance;
    final now = DateTime.now();
    var clock = 0;
    DateTime tick() => now.add(Duration(seconds: clock++));

    final root = await repo.insertGroup(GameGroup(
      name: exampleGroupName,
      description: 'Mapa de exemplo do Rise of Kingdoms, para você analisar e '
          'ajustar. Entre nos 4 sub-grupos: cada um tem o próprio modelo de '
          'status. Os nomes são do jogo; os NÚMEROS são ilustrativos '
          '(mudam por nível/estrela) — troque pelos da sua conta. Os '
          'comandantes já vêm com uma foto de exemplo: no lápis do card você '
          'troca por um print do jogo.',
      iconEmoji: '🏰',
      contentCategory: ContentCategory.general,
      createdAt: tick(),
    ));

    await _typeNames(repo, root.id!);
    await _commanders(repo, root.id!, tick);
    await _troops(repo, root.id!, tick);
    await _research(repo, root.id!, tick);
    await _buildings(repo, root.id!, tick);

    return root;
  }

  /// Nomes que o RoK usa para os tipos de unidade — o jogo não fala "Herói",
  /// fala **Comandante**; e quem não entra em batalha é o **Governador**.
  /// Gravado no grupo RAIZ: os 4 sub-grupos herdam.
  Future<void> _typeNames(TrackerRepository repo, int rootId) async {
    const nomes = <CharacterType, (String, String)>{
      CharacterType.soldadoNormal: ('Tropa', '🪖'),
      CharacterType.heroi: ('Comandante', '⚔️'),
      CharacterType.comandante: ('Governador', '👑'),
    };
    for (final e in nomes.entries) {
      await repo.upsertTypeLabel(UnitTypeLabel(
        groupId: rootId,
        typeKey: e.key.dbValue,
        label: e.value.$1,
        emoji: e.value.$2,
      ));
    }
  }

  // ─── 1. Comandantes ───────────────────────────────────────────────────────

  Future<void> _commanders(
      TrackerRepository repo, int rootId, DateTime Function() tick) async {
    final group = await repo.insertGroup(GameGroup(
      parentId: rootId,
      name: 'Comandantes',
      description: 'O comandante NÃO tem Ataque/Defesa/Vida próprios — isso é '
          'das TROPAS que ele leva (veja o sub-grupo Tropas). Aqui o que conta '
          'é a CAPACIDADE de tropa que ele carrega e os BÔNUS que as '
          'habilidades dele dão. Cada um já tem foto; as tropas ficaram sem, '
          'de propósito, para você comparar os dois jeitos de card.',
      iconEmoji: '⚔️',
      contentCategory: ContentCategory.heroes,
      maxHeroesPerSquad: 2,
      createdAt: tick(),
    ));
    final gid = group.id!;
    await _applyModel(repo, gid, _modelCommanders);

    // bonusKind: 'flat' quando o alvo já é um status em % (soma pontos
    // percentuais); 'percent' quando o alvo é número cru (multiplica).
    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Cao Cao',
        role: 'Lendário · Cavalaria',
        type: CharacterType.heroi,
        level: 60,
        stars: 5,
        avatarInitials: 'CC',
        avatarColor: 0xFF1E5FA8, // cavalaria
        values: {
          'Capacidade de tropas': 32000,
          'Bônus de ataque das tropas': 25,
          'Bônus de velocidade de marcha': 30,
          'Bônus de dano de habilidade': 30,
          'Redução de dano recebido': 5,
          'Dano da habilidade ativa': 1000,
        },
        triggers: {'Tropa favorita': 'liderando Cavalaria'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Perseverança',
            description: 'Habilidade ativa: causa dano direto ao alvo e '
                'recupera parte da vida das próprias tropas.',
            triggerText: 'ao gastar 1000 de fúria',
            targetStatName: 'Dano da habilidade ativa',
            bonusValue: 1000,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Herói do Caos',
            description: 'Passiva: reforça o ataque das tropas de cavalaria '
                'que ele lidera.',
            triggerText: 'liderando cavalaria',
            targetStatName: 'Bônus de ataque das tropas',
            bonusValue: 15,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Emboscada',
            description: 'Passiva: as tropas batem mais forte no ataque '
                'normal contra exércitos em campo aberto.',
            triggerText: 'atacando um exército em campo',
            targetStatName: 'Bônus de dano normal',
            bonusValue: 10,
            bonusKind: 'flat',
          ),
        ]);

    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Cipião Africano',
        role: 'Lendário · Infantaria',
        type: CharacterType.heroi,
        level: 60,
        stars: 5,
        avatarInitials: 'CA',
        avatarColor: 0xFFA83232, // infantaria
        values: {
          'Capacidade de tropas': 33000,
          'Bônus de ataque das tropas': 20,
          'Bônus de defesa das tropas': 15,
          'Bônus de vida das tropas': 10,
          'Redução de dano recebido': 12,
          'Bônus de dano de habilidade': 10,
          'Dano da habilidade ativa': 800,
        },
        triggers: {'Tropa favorita': 'liderando Infantaria'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Invencível',
            description: 'Habilidade ativa: cria um escudo que absorve dano '
                'no começo do combate.',
            triggerText: 'início da batalha',
            targetStatName: 'Redução de dano recebido',
            bonusValue: 10,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Legião Romana',
            description: 'Passiva: fortalece o ataque da infantaria sob seu '
                'comando.',
            triggerText: 'liderando infantaria',
            targetStatName: 'Bônus de ataque das tropas',
            bonusValue: 10,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Ataque Contínuo',
            description: 'Passiva: ataques normais seguidos aumentam o dano.',
            triggerText: 'a cada 2 ataques normais',
            targetStatName: 'Bônus de dano normal',
            bonusValue: 5,
            bonusKind: 'flat',
          ),
        ]);

    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Yi Seong-Gye',
        role: 'Lendário · Arqueiro',
        type: CharacterType.heroi,
        level: 60,
        stars: 5,
        avatarInitials: 'YS',
        avatarColor: 0xFF2E7D4F, // arqueiro
        values: {
          'Capacidade de tropas': 31000,
          'Bônus de ataque das tropas': 25,
          'Bônus de dano de habilidade': 35,
          'Dano da habilidade ativa': 1200,
        },
        triggers: {'Tropa favorita': 'liderando Arqueiros'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Mestre do Arco',
            description: 'Passiva: aumenta o ataque das tropas de arqueiros.',
            triggerText: 'liderando arqueiros',
            targetStatName: 'Bônus de ataque das tropas',
            bonusValue: 15,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Flechas Envenenadas',
            description: 'Passiva: a habilidade ativa causa dano adicional ao '
                'longo do tempo.',
            triggerText: 'ao acertar a habilidade',
            targetStatName: 'Dano da habilidade ativa',
            bonusValue: 200,
            bonusKind: 'flat',
          ),
        ]);

    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Ricardo I',
        role: 'Lendário · Infantaria / Suporte',
        type: CharacterType.heroi,
        level: 50,
        stars: 4,
        avatarInitials: 'RI',
        avatarColor: 0xFF6A4C93, // suporte
        values: {
          'Capacidade de tropas': 30000,
          'Bônus de defesa das tropas': 20,
          'Bônus de vida das tropas': 15,
          'Redução de dano recebido': 15,
          'Bônus de cura': 10,
          'Dano da habilidade ativa': 600,
        },
        triggers: {'Tropa favorita': 'liderando Infantaria'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Baluarte',
            description: 'Passiva: reduz o dano recebido ao defender a '
                'cidade ou uma estrutura.',
            triggerText: 'defendendo a cidade',
            targetStatName: 'Redução de dano recebido',
            bonusValue: 8,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'Proteção Divina',
            description: 'Habilidade ativa: cura as tropas quando a vida '
                'está baixa.',
            triggerText: 'tropas com vida baixa',
            targetStatName: 'Bônus de cura',
            bonusValue: 5,
            bonusKind: 'flat',
          ),
        ]);

    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Sun Tzu',
        role: 'Épico · Cerco',
        type: CharacterType.heroi,
        level: 37,
        stars: 4,
        avatarInitials: 'ST',
        avatarColor: 0xFF9A6324, // cerco
        values: {
          'Capacidade de tropas': 25000,
          'Bônus de dano de habilidade': 40,
          'Dano da habilidade ativa': 900,
        },
        triggers: {'Tropa favorita': 'liderando Máquinas de Cerco'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Ataque de Fogo',
            description: 'Habilidade ativa: causa dano em área aos inimigos '
                'próximos.',
            triggerText: 'ao atacar',
            targetStatName: 'Dano da habilidade ativa',
            bonusValue: 300,
            bonusKind: 'flat',
          ),
          CharacterAbility(
            characterId: 0,
            name: 'A Arte da Guerra',
            description: 'Passiva: aumenta o dano de todas as habilidades.',
            triggerText: 'sempre ativo',
            targetStatName: 'Bônus de dano de habilidade',
            bonusValue: 10,
            bonusKind: 'flat',
          ),
        ]);

    await _unit(repo, gid, _modelCommanders, tick,
        name: 'Boudica',
        role: 'Épico · Pacificação',
        type: CharacterType.heroi,
        level: 37,
        stars: 3,
        avatarInitials: 'BO',
        avatarColor: 0xFF00796B, // pacificação
        values: {
          'Capacidade de tropas': 24000,
          'Bônus de ataque das tropas': 10,
          'Bônus contra bárbaros': 30,
          'Bônus de velocidade de marcha': 20,
          'Bônus de dano de habilidade': 15,
          'Dano da habilidade ativa': 700,
        },
        triggers: {'Tropa favorita': 'liderando Infantaria'},
        abilities: const [
          CharacterAbility(
            characterId: 0,
            name: 'Fúria dos Icenos',
            description: 'Passiva: as tropas batem mais forte ao caçar '
                'bárbaros — bom para subir de nível cedo.',
            triggerText: 'lutando contra bárbaros',
            targetStatName: 'Bônus contra bárbaros',
            bonusValue: 15,
            bonusKind: 'flat',
          ),
        ]);

    // Árvore de talentos: 3 ramos, como no jogo.
    await _tree(repo, gid, const [
      _Node('Cavalaria', '🐎', [
        _Node('Marcha Veloz', '💨', []),
        _Node('Investida Pesada', '⚔️', []),
      ]),
      _Node('Habilidade', '✨', [
        _Node('Fúria Crescente', '🔥', []),
        _Node('Golpe Devastador', '💥', []),
      ]),
      _Node('Pacificação', '🕊️', [
        _Node('Ação Rápida', '⏱️', []),
      ]),
    ]);
  }

  // ─── 2. Tropas ────────────────────────────────────────────────────────────

  Future<void> _troops(
      TrackerRepository repo, int rootId, DateTime Function() tick) async {
    final group = await repo.insertGroup(GameGroup(
      parentId: rootId,
      name: 'Tropas',
      description: 'Triângulo do jogo: infantaria › cavalaria › arqueiro › '
          'infantaria. O status "Vantagem contra" é do tipo Gatilho.',
      iconEmoji: '🪖',
      contentCategory: ContentCategory.troops,
      createdAt: tick(),
    ));
    final gid = group.id!;
    await _applyModel(repo, gid, _modelTroops);

    await _unit(repo, gid, _modelTroops, tick,
        name: 'Infantaria T4',
        role: 'Linha de frente',
        type: CharacterType.soldadoNormal,
        level: 4,
        stars: 0,
        values: {
          'Ataque': 130,
          'Defesa': 150,
          'Vida': 150,
          'Velocidade': 100,
          'Carga': 1000,
          'Comida': 200,
          'Madeira': 200,
          'Tempo de treino (s)': 30,
        },
        triggers: {'Vantagem contra': 'forte contra Cavalaria'});

    await _unit(repo, gid, _modelTroops, tick,
        name: 'Cavalaria T4',
        role: 'Velocidade e coleta',
        type: CharacterType.soldadoNormal,
        level: 4,
        stars: 0,
        values: {
          'Ataque': 150,
          'Defesa': 120,
          'Vida': 130,
          'Velocidade': 160,
          'Carga': 1600,
          'Comida': 250,
          'Madeira': 150,
          'Tempo de treino (s)': 30,
        },
        triggers: {'Vantagem contra': 'forte contra Arqueiros'});

    await _unit(repo, gid, _modelTroops, tick,
        name: 'Arqueiros T4',
        role: 'Dano à distância',
        type: CharacterType.soldadoNormal,
        level: 4,
        stars: 0,
        values: {
          'Ataque': 160,
          'Defesa': 110,
          'Vida': 110,
          'Velocidade': 110,
          'Carga': 1200,
          'Comida': 150,
          'Madeira': 250,
          'Tempo de treino (s)': 30,
        },
        triggers: {'Vantagem contra': 'forte contra Infantaria'});

    await _unit(repo, gid, _modelTroops, tick,
        name: 'Máquinas de Cerco T4',
        role: 'Estruturas e coleta de pedra',
        type: CharacterType.soldadoNormal,
        level: 4,
        stars: 0,
        values: {
          'Ataque': 180,
          'Defesa': 80,
          'Vida': 100,
          'Velocidade': 80,
          'Carga': 2000,
          'Comida': 300,
          'Madeira': 300,
          'Tempo de treino (s)': 45,
        },
        triggers: {'Vantagem contra': 'forte contra estruturas e muralhas'});
  }

  // ─── 3. Pesquisa ──────────────────────────────────────────────────────────

  Future<void> _research(
      TrackerRepository repo, int rootId, DateTime Function() tick) async {
    final group = await repo.insertGroup(GameGroup(
      parentId: rootId,
      name: 'Pesquisa',
      description: 'Academia: dois ramos (Economia e Militar). Cada nó é um '
          'conteúdo que tem níveis e custo.',
      iconEmoji: '🔬',
      contentCategory: ContentCategory.research,
      createdAt: tick(),
    ));
    final gid = group.id!;
    await _applyModel(repo, gid, _modelResearch);

    await _tree(repo, gid, const [
      _Node('Economia', '🌾', [
        _Node('Agricultura', '🌱', []),
        _Node('Serraria', '🪵', []),
        _Node('Cantaria', '🪨', []),
        _Node('Mineração de Ouro', '💰', []),
      ]),
      _Node('Militar', '⚔️', [
        _Node('Infantaria I', '🛡️', []),
        _Node('Cavalaria I', '🐎', []),
        _Node('Arqueiros I', '🏹', []),
        _Node('Máquinas de Cerco I', '🪃', []),
      ]),
    ]);
  }

  // ─── 4. Construção ────────────────────────────────────────────────────────

  Future<void> _buildings(
      TrackerRepository repo, int rootId, DateTime Function() tick) async {
    final group = await repo.insertGroup(GameGroup(
      parentId: rootId,
      name: 'Construção',
      description: 'Prédios da cidade com nível atual, custo do próximo nível '
          'e pré-requisito (status do tipo Gatilho).',
      iconEmoji: '🏗️',
      contentCategory: ContentCategory.building,
      createdAt: tick(),
    ));
    final gid = group.id!;
    await _applyModel(repo, gid, _modelBuildings);

    Future<void> build(String name, String role, int nivel,
        Map<String, double> custo, String prereq) {
      return _unit(repo, gid, _modelBuildings, tick,
          name: name,
          role: role,
          type: CharacterType.soldadoNormal,
          level: nivel,
          stars: 0,
          values: {'Nível atual': nivel.toDouble(), ...custo},
          triggers: {'Pré-requisito': prereq});
    }

    await build('Câmara Municipal', 'Libera o nível dos outros prédios', 25,
        {'Comida': 4200000, 'Madeira': 4200000, 'Pedra': 1500000, 'Tempo (h)': 96},
        'nível máximo do jogo — libera tudo');
    await build('Quartel', 'Treina infantaria', 25,
        {'Comida': 900000, 'Madeira': 900000, 'Tempo (h)': 24},
        'Câmara Municipal no mesmo nível');
    await build('Estábulo', 'Treina cavalaria', 25,
        {'Comida': 900000, 'Madeira': 900000, 'Tempo (h)': 24},
        'Câmara Municipal no mesmo nível');
    await build('Campo de Arqueiros', 'Treina arqueiros', 25,
        {'Comida': 900000, 'Madeira': 900000, 'Tempo (h)': 24},
        'Câmara Municipal no mesmo nível');
    await build('Oficina de Cerco', 'Treina máquinas de cerco', 24,
        {'Comida': 800000, 'Madeira': 800000, 'Tempo (h)': 20},
        'Câmara Municipal no mesmo nível');
    await build('Hospital', 'Guarda tropas feridas', 25,
        {'Madeira': 700000, 'Pedra': 700000, 'Tempo (h)': 18},
        'Câmara Municipal no mesmo nível');
  }

  // ─── Peças reutilizáveis ──────────────────────────────────────────────────

  /// Grava o modelo de status ([specs]) como templates de [gid].
  Future<void> _applyModel(
      TrackerRepository repo, int gid, List<_StatSpec> specs) async {
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      await repo.insertTemplate(GroupStatTemplate(
        groupId: gid,
        name: s.name,
        type: s.type,
        defaultValue: s.def,
        formulaText: s.formula,
        category: s.category,
        sortOrder: i,
      ));
    }
  }

  /// Cria uma unidade (comandante, tropa ou construção) com os status do
  /// modelo do grupo preenchidos, mais as habilidades ligadas ao id real.
  Future<Character> _unit(
    TrackerRepository repo,
    int gid,
    List<_StatSpec> model,
    DateTime Function() tick, {
    required String name,
    required String role,
    required CharacterType type,
    required int level,
    required int stars,
    required Map<String, double> values,
    Map<String, String> triggers = const {},
    List<CharacterAbility> abilities = const [],
    String? avatarInitials,
    int avatarColor = 0xFF455A64,
  }) async {
    // Foto: avatar desenhado pelo app (o dono troca por um print do jogo).
    // Best-effort — se falhar, a unidade só fica com o emoji do tipo.
    final photo = avatarInitials == null
        ? null
        : await IconImageStore.generatePlaceholder(avatarInitials, avatarColor);

    final unit = await repo.insertCharacter(Character(
      groupId: gid,
      name: name,
      role: role,
      level: level,
      starRank: StarRank(stars: stars),
      characterType: type,
      iconImagePath: photo,
      createdAt: tick(),
    ));

    for (var i = 0; i < model.length; i++) {
      final s = model[i];
      await repo.insertStat(CharacterStat(
        characterId: unit.id!,
        name: s.name,
        type: s.type,
        value: values[s.name] ?? s.def,
        triggerText: triggers[s.name],
        formulaText: s.formula,
        sortOrder: i,
      ));
    }

    for (var i = 0; i < abilities.length; i++) {
      await repo.insertAbility(
          abilities[i].copyWith(characterId: unit.id, sortOrder: i));
    }
    return unit;
  }

  /// Grava uma árvore (raízes com filhos) em [gid], religando os pais.
  Future<void> _tree(
      TrackerRepository repo, int gid, List<_Node> roots) async {
    var order = 0;
    for (final root in roots) {
      final saved = await repo.insertSkillNode(SkillNode(
        groupId: gid,
        name: root.name,
        iconEmoji: root.emoji,
        sortOrder: order++,
      ));
      for (final child in root.children) {
        await repo.insertSkillNode(SkillNode(
          groupId: gid,
          parentId: saved.id,
          name: child.name,
          iconEmoji: child.emoji,
          sortOrder: order++,
        ));
      }
    }
  }
}

/// Especificação de um status do modelo (nome, tipo, valor padrão, categoria).
class _StatSpec {
  final String name;
  final StatType type;
  final double def;
  final String category;
  final String? formula;
  const _StatSpec(this.name, this.type, this.def, this.category, {this.formula});
}

/// Nó de árvore declarado no exemplo (1 nível de filhos basta aqui).
class _Node {
  final String name;
  final String emoji;
  final List<_Node> children;
  const _Node(this.name, this.emoji, this.children);
}
