import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/character.dart';
import '../models/character_ability.dart';
import '../models/character_stat.dart';
import '../models/game_group.dart';
import '../models/group_stat_template.dart';
import '../models/character_type.dart';
import '../models/skill_node.dart';
import '../models/unit_type_label.dart';
import '../repositories/database_helper.dart';
import '../repositories/tracker_repository.dart';

/// Serviço de exportação e importação de dados via JSON.
///
/// O formato é o CONTRATO OFICIAL (docs/CONTRATO-JSON.md) que alimentará o
/// 2º app (teste/simulação): versionado, com limites explícitos e validação
/// rígida — um arquivo malformado/adulterado é rejeitado por inteiro ANTES de
/// qualquer escrita no banco. Import aceita backup de QUALQUER versão anterior.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Versão atual do formato de export (contrato).
  /// v3 (2026-07-25): + `unitTypeLabels` (nomes dos tipos de unidade por jogo).
  static const int formatVersion = 3;

  // Limites do contrato — proteção contra arquivos gigantes/adulterados.
  static const int maxGroups = 1000;
  static const int maxPerList = 2000; // personagens/nós/templates por grupo
  static const int maxPerCharacter = 500; // stats/habilidades por personagem
  static const int maxNameLength = 200;
  static const int maxTextLength = 5000;

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Monta o JSON do backup (separado do compartilhamento — testável).
  Future<String> buildExportJson() async {
    final repo = TrackerRepository.instance;
    final groups = await repo.getAllGroups();
    final data = <Map<String, dynamic>>[];

    for (final g in groups) {
      final chars = await repo.getCharactersByGroup(g.id!);
      final charData = <Map<String, dynamic>>[];
      for (final c in chars) {
        final stats = await repo.getStatsByCharacter(c.id!);
        final abilities = await repo.getAbilitiesByCharacter(c.id!);
        charData.add({
          ...c.toMap(),
          'stats': stats.map((s) => s.toMap()).toList(),
          'abilities': abilities.map((a) => a.toMap()).toList(),
        });
      }
      final templates = await repo.getTemplatesByGroup(g.id!);
      final nodes = await repo.getSkillNodes(g.id!);
      final typeLabels = await repo.getTypeLabelsByGroup(g.id!);
      data.add({
        ...g.toMap(),
        'characters': charData,
        'statTemplates': templates.map((t) => t.toMap()).toList(),
        // ids/parentIds originais entram de propósito: o import remapeia.
        'skillNodes': nodes.map((n) => n.toMap()).toList(),
        'unitTypeLabels': typeLabels.map((l) => l.toMap()).toList(),
      });
    }

    return const JsonEncoder.withIndent('  ').convert({
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': data,
    });
  }

  /// Exporta tudo. No Windows abre "salvar como"; no Android abre o share.
  /// Retorna uma mensagem amigável para a UI.
  Future<String> exportAll() async {
    final json = await buildExportJson();
    final fileName =
        'hero_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (Platform.isWindows || Platform.isLinux) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar backup do Hero Tracker',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return 'Exportação cancelada.';
      final target = path.toLowerCase().endsWith('.json') ? path : '$path.json';
      await File(target).writeAsString(json, encoding: utf8);
      return 'Backup salvo em $target';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, encoding: utf8);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Hero Tracker — Backup',
    );
    return 'Backup pronto para compartilhar.';
  }

  // ─── Pacote de UM jogo: modelo + personagens ──────────────────────────────
  //
  // Serve para RECEBER um mapa pronto (de outra pessoa ou, no futuro, do 2º
  // app) e preencher um jogo que já existe. É o mesmo formato de grupo do
  // backup — só que sozinho — e passa pela MESMA validação (_parseAndValidate).

  /// Marca do arquivo de pacote — distingue de um backup completo.
  static const String packKind = 'hero-tracker/pacote-de-grupo';

  /// Monta o pacote de [groupId]: modelo de status + personagens (com status e
  /// habilidades). Foto nunca vai junto.
  Future<String> buildGroupPackJson(int groupId) async {
    final repo = TrackerRepository.instance;
    final g = await repo.getGroupById(groupId);
    if (g == null) throw StateError('grupo $groupId não existe');
    final chars = <Map<String, dynamic>>[];
    for (final c in await repo.getCharactersByGroup(groupId)) {
      final stats = await repo.getStatsByCharacter(c.id!);
      final abilities = await repo.getAbilitiesByCharacter(c.id!);
      chars.add({
        ...(c.toMap()..remove('iconImagePath')),
        'stats': stats.map((s) => s.toMap()).toList(),
        'abilities': abilities.map((a) => a.toMap()).toList(),
      });
    }
    final templates = await repo.getTemplatesByGroup(groupId);
    return const JsonEncoder.withIndent('  ').convert({
      'version': formatVersion,
      'kind': packKind,
      'exportedAt': DateTime.now().toIso8601String(),
      'group': {
        'name': g.name,
        'iconEmoji': g.iconEmoji,
        'contentCategory': g.contentCategory.dbValue,
        'statTemplates': templates.map((t) => t.toMap()).toList(),
        'characters': chars,
      },
    });
  }

  /// Salva o pacote de [group]. Windows: "salvar como"; Android: compartilhar.
  Future<String> exportGroupPack(GameGroup group) async {
    final json = await buildGroupPackJson(group.id!);
    final seguro = group.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final fileName =
        'pacote_${seguro}_${DateTime.now().millisecondsSinceEpoch}.json';

    if (Platform.isWindows || Platform.isLinux) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar pacote de "${group.name}"',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return 'Exportação cancelada.';
      final target = path.toLowerCase().endsWith('.json') ? path : '$path.json';
      await File(target).writeAsString(json, encoding: utf8);
      return 'Pacote salvo em $target';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, encoding: utf8);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Hero Tracker — pacote de ${group.name}',
    );
    return 'Pacote pronto para compartilhar.';
  }

  /// Importa um pacote DENTRO de [targetGroupId]: acrescenta os status do
  /// modelo e os personagens que ainda não existem lá.
  ///
  /// Nada que já existe é sobrescrito: status ou personagem com o mesmo nome
  /// (sem ligar para maiúscula) fica como estava — dado do dono é sagrado.
  ///
  /// Personagem novo nasce com o modelo do jogo (igual à criação pela tela) e
  /// os `stats` do arquivo MESCLAM por nome: mesmo nome troca o valor, nome
  /// novo acrescenta. Stat sem `type` herda o tipo do status do modelo — assim
  /// um JSON escrito à mão só precisa de `{"name": ..., "value": ...}`.
  ///
  /// Aceita o pacote (`group`, com ou sem `kind` = [packKind]) ou um backup de
  /// UM grupo. Pacote sem `version` é lido como a versão atual.
  Future<ImportResult> importGroupPack(
      String filePath, int targetGroupId) async {
    // Passada 1 — validação completa (nenhuma escrita).
    final _StagedGroup sg;
    // Por personagem (mesma ordem de sg.chars): nomes de stat sem `type`.
    final semTipo = <Set<String>>[];
    try {
      final raw =
          jsonDecode(await File(filePath).readAsString(encoding: utf8));
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('estrutura raiz inválida.');
      }
      Map<String, dynamic>? group;
      final grupos = raw['groups'];
      if (raw['group'] is Map<String, dynamic> &&
          (raw['kind'] == null || raw['kind'] == packKind)) {
        group = Map<String, dynamic>.of(raw['group'] as Map<String, dynamic>);
      } else if (grupos is List &&
          grupos.length == 1 &&
          grupos.first is Map<String, dynamic>) {
        group = Map<String, dynamic>.of(grupos.first as Map<String, dynamic>);
      }
      if (group == null) {
        throw const FormatException(
            'não é um pacote de jogo (modelo + personagens).');
      }
      // Pacote escrito à mão pode vir sem nome; o nome não é usado aqui.
      final nome = group['name'];
      if (nome is! String || nome.trim().isEmpty) group['name'] = 'pacote';
      // Só o modelo e os personagens entram — o resto do grupo é ignorado.
      group
        ..remove('parentId')
        ..remove('skillNodes')
        ..remove('unitTypeLabels');
      final chars = group['characters'];
      if (chars is List) {
        for (final c in chars) {
          final stats = c is Map ? c['stats'] : null;
          semTipo.add({
            if (stats is List)
              for (final s in stats)
                if (s is Map && s['type'] == null && s['name'] is String)
                  (s['name'] as String).trim().toLowerCase(),
          });
        }
      }
      sg = _parseAndValidate(jsonEncode({
        'version': raw['version'] ?? formatVersion,
        'groups': [group],
      })).single;
    } on FormatException catch (e) {
      return ImportResult(
          success: false, message: 'Pacote recusado: ${e.message}');
    } catch (_) {
      return const ImportResult(
          success: false,
          message: 'Arquivo de pacote inválido — nada foi importado.');
    }

    // Passada 2 — uma transação só (tudo-ou-nada). Lê o grupo ANTES: dentro
    // da transação só vale o txn (o repositório travaria a conexão).
    try {
      final repo = TrackerRepository.instance;
      final proprios = await repo.getTemplatesByGroup(targetGroupId);
      final herdados = proprios.isEmpty
          ? await repo.getEffectiveTemplates(targetGroupId)
          : <GroupStatTemplate>[];
      final nomesModelo = proprios.map((t) => t.name.toLowerCase()).toSet();
      final nomesPersonagens = (await repo.getCharactersByGroup(targetGroupId))
          .map((c) => c.name.toLowerCase())
          .toSet();
      var ordem = proprios.fold<int>(
              -1, (m, t) => t.sortOrder > m ? t.sortOrder : m) +
          1;

      var novosStatus = 0, novosPersonagens = 0, mantidos = 0;
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final modeloNovo = <GroupStatTemplate>[];
        for (final t in sg.templates) {
          if (!nomesModelo.add(t.name.toLowerCase())) {
            mantidos++;
            continue;
          }
          final novo = t.copyWith(groupId: targetGroupId, sortOrder: ordem++);
          final id =
              await txn.insert('group_stat_templates', _stripId(novo.toMap()));
          modeloNovo.add(novo.copyWith(id: id));
          novosStatus++;
        }
        // Personagem sem status recebe o modelo do jogo (antigo + novo) ou,
        // se o jogo não tem nenhum, o herdado do pai — igual à tela.
        final modelo = [...proprios, ...modeloNovo];
        final modeloEfetivo = modelo.isNotEmpty ? modelo : herdados;

        for (var i = 0; i < sg.chars.length; i++) {
          final sc = sg.chars[i];
          if (!nomesPersonagens.add(sc.character.name.toLowerCase())) {
            mantidos++;
            continue;
          }
          final cid = await txn.insert('characters',
              _stripId(sc.character.copyWith(groupId: targetGroupId).toMap()));
          novosPersonagens++;
          final stats = _mesclarStats(
            modeloEfetivo.map((t) => t.toCharacterStat(cid)).toList(),
            sc.stats.map((s) => s.copyWith(characterId: cid)).toList(),
            i < semTipo.length ? semTipo[i] : const {},
          );
          for (final s in stats) {
            await txn.insert('character_stats', _stripId(s.toMap()));
          }
          for (final a in sc.abilities) {
            await txn.insert('character_abilities',
                _stripId(a.copyWith(characterId: cid).toMap()));
          }
        }
      });

      var msg = 'Pacote importado: $novosStatus status no modelo e '
          '$novosPersonagens personagem(ns).';
      if (mantidos > 0) {
        msg += ' $mantidos item(ns) com o mesmo nome já existia(m) — '
            'ficou(aram) como estava(m).';
      }
      return ImportResult(success: true, message: msg);
    } catch (_) {
      return const ImportResult(
          success: false,
          message: 'Falha ao gravar o pacote — nada foi importado.');
    }
  }

  /// Junta os status do [modelo] com os do [arquivo], por nome (sem ligar
  /// para maiúscula). Mesmo nome: o do arquivo vence — mas, se o nome está em
  /// [semTipo], só o VALOR (e gatilho/fórmula, se vieram) muda e o tipo do
  /// modelo fica. Nome novo entra no fim. Ordem do modelo é preservada.
  static List<CharacterStat> _mesclarStats(List<CharacterStat> modelo,
      List<CharacterStat> arquivo, Set<String> semTipo) {
    final out = [...modelo];
    final pos = <String, int>{
      for (var i = 0; i < out.length; i++) out[i].name.trim().toLowerCase(): i,
    };
    var ordem =
        out.fold<int>(-1, (m, s) => s.sortOrder > m ? s.sortOrder : m) + 1;
    for (final s in arquivo) {
      final chave = s.name.trim().toLowerCase();
      final i = pos[chave];
      if (i == null) {
        pos[chave] = out.length;
        out.add(s.copyWith(sortOrder: ordem++));
      } else if (semTipo.contains(chave)) {
        out[i] = out[i].copyWith(
            value: s.value,
            triggerText: s.triggerText,
            formulaText: s.formulaText);
      } else {
        out[i] = s.copyWith(sortOrder: out[i].sortOrder);
      }
    }
    return out;
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  /// Importa um backup (mescla com os dados existentes).
  ///
  /// Segurança do contrato: o arquivo inteiro é DECODIFICADO E VALIDADO antes
  /// de qualquer insert — JSON lixo, campos fora do limite ou versão mais nova
  /// que o app são rejeitados sem tocar no banco.
  Future<ImportResult> importFromFile(String filePath) async {
    // Passada 1 — parse e validação completa (nenhuma escrita).
    final List<_StagedGroup> staged;
    try {
      final content = await File(filePath).readAsString(encoding: utf8);
      staged = _parseAndValidate(content);
    } on FormatException catch (e) {
      return ImportResult(
          success: false, message: 'Backup recusado: ${e.message}');
    } catch (_) {
      return const ImportResult(
          success: false,
          message: 'Arquivo de backup inválido — nada foi importado.');
    }

    // Passada 2 — inserts numa ÚNICA transação: se qualquer escrita falhar no
    // meio, tudo é revertido (o "tudo-ou-nada" do contrato vale de ponta a
    // ponta, não só para a validação). Usa txn direto — nunca o repositório
    // (chamar a conexão singleton dentro da transação travaria).
    try {
      final db = await DatabaseHelper.instance.database;
      int groupCount = 0, charCount = 0, nodeCount = 0;

      await db.transaction((txn) async {
        final oldGroupToNew = <int, int>{};
        final groupParentOld = <int, int?>{}; // idNovo grupo → parentId antigo

        for (final sg in staged) {
          final gid = await txn.insert('game_groups', _stripId(sg.group.toMap()));
          groupCount++;
          if (sg.oldId != null) oldGroupToNew[sg.oldId!] = gid;
          groupParentOld[gid] = sg.oldParentId;

          for (final t in sg.templates) {
            await txn.insert('group_stat_templates',
                _stripId(t.copyWith(groupId: gid).toMap()));
          }

          for (final l in sg.typeLabels) {
            await txn.insert('unit_type_labels',
                _stripId(l.copyWith(groupId: gid).toMap()));
          }

          for (final sc in sg.chars) {
            final cid = await txn.insert(
                'characters', _stripId(sc.character.copyWith(groupId: gid).toMap()));
            charCount++;
            for (final s in sc.stats) {
              await txn.insert('character_stats',
                  _stripId(s.copyWith(characterId: cid).toMap()));
            }
            for (final a in sc.abilities) {
              await txn.insert('character_abilities',
                  _stripId(a.copyWith(characterId: cid).toMap()));
            }
          }

          // Nós: insere sem pai (parentId já ausente do toMap staged),
          // guarda o mapa velho→novo e religa os pais SEM formar ciclo.
          final oldNodeToNew = <int, int>{};
          final nodeParentOld = <int, int?>{}; // idNovo nó → parentId antigo
          for (final sn in sg.nodes) {
            final nid = await txn.insert(
                'skill_nodes', _stripId(sn.node.copyWith(groupId: gid).toMap()));
            nodeCount++;
            if (sn.oldId != null) oldNodeToNew[sn.oldId!] = nid;
            nodeParentOld[nid] = sn.oldParentId;
          }
          final nodeEdges = _resolveEdges(nodeParentOld, oldNodeToNew);
          for (final e in nodeEdges.entries) {
            await txn.update('skill_nodes', {'parentId': e.value},
                where: 'id = ?', whereArgs: [e.key]);
          }
        }

        // Hierarquia de grupos: pai ausente do backup → raiz; ciclo → raiz.
        final groupEdges = _resolveEdges(groupParentOld, oldGroupToNew);
        for (final e in groupEdges.entries) {
          await txn.update('game_groups', {'parentId': e.value},
              where: 'id = ?', whereArgs: [e.key]);
        }
      });

      return ImportResult(
          success: true,
          message: '$groupCount grupo(s), $charCount personagem(s) e '
              '$nodeCount nó(s) de árvore importados.');
    } catch (_) {
      return const ImportResult(
          success: false,
          message: 'Falha ao gravar o backup — nada foi importado.');
    }
  }

  static Map<String, dynamic> _stripId(Map<String, dynamic> m) =>
      Map<String, dynamic>.of(m)..remove('id');

  /// Converte referências de pai (idNovo → idAntigoDoPai) em arestas
  /// idNovo→idNovoDoPai, DESCARTANDO auto-referência, pai ausente e qualquer
  /// aresta que formaria ciclo (esse item vira raiz — nunca some da UI).
  static Map<int, int> _resolveEdges(
      Map<int, int?> childToOldParent, Map<int, int> oldToNew) {
    final intended = <int, int>{};
    childToOldParent.forEach((child, oldParent) {
      if (oldParent == null) return;
      final np = oldToNew[oldParent];
      if (np != null && np != child) intended[child] = np;
    });
    final safe = <int, int>{};
    for (final entry in intended.entries) {
      final visited = <int>{entry.key};
      int? cursor = entry.value;
      var cycle = false;
      while (cursor != null) {
        if (!visited.add(cursor)) {
          cycle = true;
          break;
        }
        cursor = intended[cursor];
      }
      if (!cycle) safe[entry.key] = entry.value;
    }
    return safe;
  }

  // ─── Validação (contrato) ──────────────────────────────────────────────────

  List<_StagedGroup> _parseAndValidate(String content) {
    final raw = jsonDecode(content);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('estrutura raiz inválida.');
    }
    final version = raw['version'];
    if (version is! int || version < 1) {
      throw const FormatException('versão do backup ausente/inválida.');
    }
    if (version > formatVersion) {
      throw const FormatException(
          'backup de versão mais nova — atualize o app antes de importar.');
    }
    final groupsRaw = raw['groups'];
    if (groupsRaw is! List) {
      throw const FormatException('lista de grupos ausente.');
    }
    if (groupsRaw.length > maxGroups) {
      throw const FormatException('quantidade de grupos acima do limite.');
    }

    String cleanName(dynamic v, String campo) {
      if (v is! String || v.trim().isEmpty || v.length > maxNameLength) {
        throw FormatException('$campo inválido.');
      }
      return v;
    }

    void checkText(dynamic v, String campo) {
      if (v != null && (v is! String || v.length > maxTextLength)) {
        throw FormatException('$campo fora do limite.');
      }
    }

    List<Map<String, dynamic>> listOf(dynamic v, String campo, int max) {
      if (v == null) return const [];
      if (v is! List || v.length > max) {
        throw FormatException('$campo fora do limite.');
      }
      return v.map((e) {
        if (e is! Map<String, dynamic>) {
          throw FormatException('$campo com item inválido.');
        }
        return e;
      }).toList();
    }

    final staged = <_StagedGroup>[];
    for (final gAny in groupsRaw) {
      if (gAny is! Map<String, dynamic>) {
        throw const FormatException('grupo inválido.');
      }
      final gMap = Map<String, dynamic>.of(gAny);
      final oldId = gMap.remove('id') as int?;
      final oldParentId = gMap.remove('parentId') as int?;
      // Caminho de foto NUNCA entra pelo import (device-específico/inseguro).
      gMap.remove('iconImagePath');
      cleanName(gMap['name'], 'nome de grupo');
      checkText(gMap['description'], 'descrição de grupo');
      checkText(gMap['iconEmoji'], 'ícone de grupo');

      final charsRaw =
          listOf(gMap.remove('characters'), 'personagens', maxPerList);
      final templatesRaw =
          listOf(gMap.remove('statTemplates'), 'templates', maxPerList);
      final nodesRaw =
          listOf(gMap.remove('skillNodes'), 'nós de árvore', maxPerList);
      final typeLabelsRaw = listOf(
          gMap.remove('unitTypeLabels'), 'nomes de tipo de unidade', 50);

      gMap['createdAt'] ??= DateTime.now().toIso8601String();
      final group = GameGroup.fromMap(gMap);

      final templates = templatesRaw.map((tAny) {
        final t = Map<String, dynamic>.of(tAny)..remove('id');
        cleanName(t['name'], 'nome de status do modelo');
        checkText(t['triggerText'], 'gatilho do template');
        checkText(t['formulaText'], 'fórmula do template');
        checkText(t['category'], 'categoria do template');
        t['groupId'] = 0; // religado no insert
        return GroupStatTemplate.fromMap(t);
      }).toList();

      final chars = charsRaw.map((cAny) {
        final c = Map<String, dynamic>.of(cAny)..remove('id');
        c.remove('iconImagePath');
        cleanName(c['name'], 'nome de personagem');
        checkText(c['notes'], 'notas de personagem');
        checkText(c['role'], 'função de personagem');
        final statsRaw = listOf(c.remove('stats'), 'status', maxPerCharacter);
        final abilitiesRaw =
            listOf(c.remove('abilities'), 'habilidades', maxPerCharacter);
        c['groupId'] = 0;
        c['createdAt'] ??= DateTime.now().toIso8601String();
        final character = Character.fromMap(c);
        final stats = statsRaw.map((sAny) {
          final s = Map<String, dynamic>.of(sAny)..remove('id');
          cleanName(s['name'], 'nome de status');
          checkText(s['triggerText'], 'gatilho');
          checkText(s['formulaText'], 'fórmula');
          s['characterId'] = 0;
          return CharacterStat.fromMap(s);
        }).toList();
        final abilities = abilitiesRaw.map((aAny) {
          final a = Map<String, dynamic>.of(aAny)..remove('id');
          cleanName(a['name'], 'nome de habilidade');
          checkText(a['description'], 'descrição de habilidade');
          checkText(a['triggerText'], 'gatilho de habilidade');
          checkText(a['targetStatName'], 'status alvo da habilidade');
          // bonusKind só tem dois valores válidos — o resto vira 'flat'.
          final bk = a['bonusKind'];
          if (bk != 'flat' && bk != 'percent') a['bonusKind'] = 'flat';
          a['characterId'] = 0;
          return CharacterAbility.fromMap(a);
        }).toList();
        return _StagedChar(character, stats, abilities);
      }).toList();

      final nodes = nodesRaw.map((nAny) {
        final n = Map<String, dynamic>.of(nAny);
        final oldNodeId = n.remove('id') as int?;
        final oldNodeParent = n.remove('parentId') as int?;
        cleanName(n['name'], 'nome de nó da árvore');
        checkText(n['description'], 'descrição de nó');
        checkText(n['iconEmoji'], 'ícone de nó');
        n['groupId'] = 0;
        return _StagedNode(SkillNode.fromMap(n), oldNodeId, oldNodeParent);
      }).toList();

      // Nome de tipo com chave desconhecida é PULADO, não rejeita o arquivo:
      // um backup de versão futura com um 4º tipo ainda importa o resto
      // (regra 5 do contrato — campo desconhecido é ignorado).
      final validKeys =
          CharacterType.values.map((t) => t.dbValue).toSet();
      final typeLabels = <UnitTypeLabel>[];
      for (final lAny in typeLabelsRaw) {
        final l = Map<String, dynamic>.of(lAny)..remove('id');
        if (!validKeys.contains(l['typeKey'])) continue;
        cleanName(l['label'], 'nome de tipo de unidade');
        checkText(l['emoji'], 'ícone de tipo de unidade');
        l['groupId'] = 0; // religado no insert
        typeLabels.add(UnitTypeLabel.fromMap(l));
      }

      staged.add(_StagedGroup(
          group, oldId, oldParentId, templates, chars, nodes, typeLabels));
    }
    return staged;
  }
}

class _StagedGroup {
  final GameGroup group;
  final int? oldId;
  final int? oldParentId;
  final List<GroupStatTemplate> templates;
  final List<_StagedChar> chars;
  final List<_StagedNode> nodes;
  final List<UnitTypeLabel> typeLabels;
  _StagedGroup(this.group, this.oldId, this.oldParentId, this.templates,
      this.chars, this.nodes, this.typeLabels);
}

class _StagedChar {
  final Character character;
  final List<CharacterStat> stats;
  final List<CharacterAbility> abilities;
  _StagedChar(this.character, this.stats, this.abilities);
}

class _StagedNode {
  final SkillNode node;
  final int? oldId;
  final int? oldParentId;
  _StagedNode(this.node, this.oldId, this.oldParentId);
}

class ImportResult {
  final bool success;
  final String message;
  const ImportResult({required this.success, required this.message});
}
