import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda ícones de grupo como PNG dentro da pasta interna do app.
///
/// Segurança: o arquivo escolhido pelo usuário NUNCA entra no app —
/// as dimensões são lidas ANTES de decodificar (rejeita "bomba de pixels":
/// PNG pequeno em bytes que explode em memória), a imagem é decodificada
/// (o que prova que é imagem de verdade), redimensionada para no máximo
/// [_maxSide]px no lado maior e re-codificada como um PNG novo gerado pelo
/// próprio app. Arquivo que falhar em qualquer etapa é recusado.
class IconImageStore {
  IconImageStore._();

  static const _dirName = 'group_icons';
  static const _maxSide = 512;
  static const _maxSourceBytes = 20 * 1024 * 1024; // 20 MB codificados
  static const _maxSourcePixels = 50 * 1000 * 1000; // 50 MP decodificados

  /// Extensões aceitas no seletor de arquivo.
  static const allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'];

  static Future<Directory> _iconsDir() async => Directory(
      p.join((await getApplicationSupportDirectory()).path, _dirName));

  /// Importa a imagem para a pasta interna. Retorna o caminho do PNG salvo,
  /// ou null se o arquivo for recusado (extensão inválida, muito grande em
  /// bytes ou pixels, não decodifica como imagem, ou erro de I/O).
  static Future<String?> importIcon(String sourcePath) async {
    try {
      final ext = p.extension(sourcePath).toLowerCase().replaceFirst('.', '');
      if (!allowedExtensions.contains(ext)) return null;

      final source = File(sourcePath);
      if (!await source.exists()) return null;
      if (await source.length() > _maxSourceBytes) return null;

      final bytes = await source.readAsBytes();

      // Dimensões SEM decodificar: barra bomba de pixels antes de alocar.
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
      } catch (_) {
        buffer.dispose();
        return null; // não é imagem reconhecível
      }
      final w = descriptor.width;
      final h = descriptor.height;
      if (w <= 0 || h <= 0 || w * h > _maxSourcePixels) {
        descriptor.dispose();
        buffer.dispose();
        return null;
      }

      // Limita o lado MAIOR a _maxSide (aspect ratio preservado).
      final ui.Codec codec;
      if (w <= _maxSide && h <= _maxSide) {
        codec = await descriptor.instantiateCodec();
      } else if (w >= h) {
        codec = await descriptor.instantiateCodec(targetWidth: _maxSide);
      } else {
        codec = await descriptor.instantiateCodec(targetHeight: _maxSide);
      }
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      if (png == null) return null;

      final dir = await _iconsDir();
      await dir.create(recursive: true);
      final dest = File(p.join(
          dir.path, 'icon_${DateTime.now().millisecondsSinceEpoch}.png'));
      await dest.writeAsBytes(png.buffer.asUint8List(), flush: true);
      return dest.path;
    } catch (_) {
      return null; // qualquer falha = arquivo recusado
    }
  }

  /// Apaga um ícone interno (ao trocar a foto ou deletar o grupo).
  /// Recusa caminhos fora de group_icons/ — um backup importado/editado
  /// nunca pode direcionar a deleção para um arquivo arbitrário.
  static Future<void> deleteIcon(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final dir = await _iconsDir();
      if (!p.isWithin(dir.path, path)) return;
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // arquivo em uso/já removido — ignorar
    }
  }

  /// Varredura de órfãos: apaga PNGs de group_icons/ que nenhum grupo
  /// referencia (sobras de crash/fechamento no meio de um import).
  /// Chamar no início da sessão, nunca com dialog de grupo aberto.
  static Future<void> cleanupOrphans(Iterable<String> referencedPaths) async {
    try {
      final dir = await _iconsDir();
      if (!await dir.exists()) return;
      final referenced = referencedPaths.map(p.canonicalize).toSet();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        if (!referenced.contains(p.canonicalize(entity.path))) {
          try {
            await entity.delete();
          } catch (_) {/* em uso — tenta na próxima sessão */}
        }
      }
    } catch (_) {
      // varredura é best-effort
    }
  }
}
