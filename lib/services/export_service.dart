import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/character.dart';
import '../models/character_stat.dart';
import '../models/game_group.dart';
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
      data.add({...g.toMap(), 'characters': charData});
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

      for (final gMap in groups) {
        // Remove id para forçar auto-increment novo
        gMap.remove('id');
        final chars = (gMap.remove('characters') as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        final group = await repo.insertGroup(_parseGroup(gMap));
        groupCount++;

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
}

class ImportResult {
  final bool success;
  final String message;
  const ImportResult({required this.success, required this.message});
}
