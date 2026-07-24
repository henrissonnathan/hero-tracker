import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/character.dart';
import '../models/character_stat.dart';
import '../models/game_group.dart';
import '../models/group_stat_template.dart';
import '../repositories/tracker_repository.dart';

/// Serviço de exportação e importação de dados via JSON.
///
/// Todos os dados ficam locais — o desenvolvedor não armazena nada.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Exporta todos os grupos, personagens e status para um arquivo JSON.
  Future<void> exportAll() async {
    final repo = TrackerRepository.instance;
    final groups = await repo.getAllGroups();
    final data = <Map<String, dynamic>>[];

    for (final g in groups) {
      final chars = await repo.getCharactersByGroup(g.id!);
      final charData = <Map<String, dynamic>>[];
      for (final c in chars) {
        final stats = await repo.getStatsByCharacter(c.id!);
        charData.add({
          ...c.toMap(),
          'stats': stats.map((s) => s.toMap()).toList(),
        });
      }
      final templates = await repo.getTemplatesByGroup(g.id!);
      data.add({
        ...g.toMap(),
        'characters': charData,
        'statTemplates': templates.map((t) => t.toMap()).toList(),
      });
    }

    final json = const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': data,
    });

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/hero_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Hero Tracker — Backup',
    );
  }

  /// Importa dados de um arquivo JSON (mescla com os dados existentes).
  Future<ImportResult> importFromFile(String filePath) async {
    try {
      final content = await File(filePath).readAsString(encoding: utf8);
      final raw = jsonDecode(content) as Map<String, dynamic>;
      final groups =
          (raw['groups'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final repo = TrackerRepository.instance;
      int groupCount = 0;
      int charCount = 0;

      // O import gera um id novo (auto-increment) para cada grupo, então o
      // parentId original do JSON aponta para o id ERRADO no banco de
      // destino (o grupo pré-existente que hoje ocupa aquele id, não o
      // grupo recém-importado). Mapeia id-antigo→id-novo durante a primeira
      // passada e remapeia parentId numa segunda passada, depois que todos
      // os grupos do backup já existem com seus ids novos.
      final oldIdToNewId = <int, int>{};
      final pendingParent = <int, int?>{}; // id novo → parentId antigo (do JSON)

      for (final gMap in groups) {
        final oldId = gMap['id'] as int?;
        final oldParentId = gMap['parentId'] as int?;
        // Remove id para forçar auto-increment novo
        gMap.remove('id');
        // parentId original não é válido no banco de destino — remapeado
        // na segunda passada abaixo.
        gMap.remove('parentId');
        // Caminho de foto não sobrevive ao ciclo export→import: importar
        // manteria dois grupos apontando para o MESMO PNG (apagar um
        // quebraria o outro) e, vindo de fora, seria caminho morto/inseguro.
        gMap.remove('iconImagePath');
        final chars = (gMap.remove('characters') as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final templates =
            (gMap.remove('statTemplates') as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();

        final group = await repo.insertGroup(_parseGroup(gMap));
        groupCount++;
        if (oldId != null) oldIdToNewId[oldId] = group.id!;
        pendingParent[group.id!] = oldParentId;

        for (final tMap in templates) {
          tMap.remove('id');
          await repo.insertTemplate(_parseTemplate(tMap, group.id!));
        }

        for (final cMap in chars) {
          cMap.remove('id');
          final stats = (cMap.remove('stats') as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          final character = await repo
              .insertCharacter(_parseChar(cMap, group.id!));
          charCount++;

          for (final sMap in stats) {
            sMap.remove('id');
            sMap['characterId'] = character.id;
            await repo.insertStat(_parseStat(sMap, character.id!));
          }
        }
      }

      for (final entry in pendingParent.entries) {
        final oldParentId = entry.value;
        if (oldParentId == null) continue;
        final newParentId = oldIdToNewId[oldParentId];
        // Pai não fazia parte deste backup — grupo fica raiz (mais seguro
        // do que apontar para um grupo pré-existente não relacionado).
        if (newParentId == null) continue;
        final imported = await repo.getGroupById(entry.key);
        if (imported != null) {
          await repo.updateGroup(imported.copyWith(parentId: newParentId));
        }
      }

      return ImportResult(
          success: true,
          message:
              '$groupCount grupo(s) e $charCount personagem(s) importados.');
    } catch (e) {
      return ImportResult(
          success: false, message: 'Erro ao importar: $e');
    }
  }

  // Helpers de parsing sem usar fromMap diretamente (evita conflito de id)
  GameGroup _parseGroup(Map<String, dynamic> m) {
    m['createdAt'] ??= DateTime.now().toIso8601String();
    return GameGroup.fromMap(m);
  }

  Character _parseChar(Map<String, dynamic> m, int groupId) {
    m['groupId'] = groupId;
    m['createdAt'] ??= DateTime.now().toIso8601String();
    return Character.fromMap(m);
  }

  CharacterStat _parseStat(Map<String, dynamic> m, int characterId) {
    m['characterId'] = characterId;
    return CharacterStat.fromMap(m);
  }

  GroupStatTemplate _parseTemplate(Map<String, dynamic> m, int groupId) {
    m['groupId'] = groupId;
    return GroupStatTemplate.fromMap(m);
  }
}

class ImportResult {
  final bool success;
  final String message;
  const ImportResult({required this.success, required this.message});
}
