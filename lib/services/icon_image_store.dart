import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda ícones de grupo E fotos de personagem como PNG dentro da pasta
/// interna do app (os dois dividem a mesma pasta — ver [cleanupOrphans]).
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

  /// Desenha um avatar simples (fundo colorido + iniciais) e salva como PNG
  /// interno, igual a uma foto importada. Serve ao EXEMPLO: o dono vê como um
  /// card fica com foto sem precisar escolher arquivo nenhum — e troca por um
  /// print do jogo quando quiser.
  ///
  /// Best-effort de propósito: qualquer falha (ou demora) devolve null e quem
  /// chamou apenas fica sem foto — nunca derruba quem está montando dados.
  static Future<String?> generatePlaceholder(
      String initials, int argbColor) async {
    try {
      return await _drawPlaceholder(initials, argbColor)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  static int _genSeq = 0;

  static Future<String?> _drawPlaceholder(
      String initials, int argbColor) async {
    const side = 256; // px do PNG gerado
    const sideF = 256.0; // o mesmo, em double (const não aceita toDouble())
    const rect = ui.Rect.fromLTWH(0, 0, sideF, sideF);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, rect);
    canvas.drawRect(rect, ui.Paint()..color = ui.Color(argbColor));

    final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: initials.length <= 2 ? 120 : 78, // 3+ letras não estouram
      fontWeight: ui.FontWeight.bold,
    ))
          ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
          ..addText(initials))
        .build()
      ..layout(const ui.ParagraphConstraints(width: sideF));
    canvas.drawParagraph(
        paragraph, ui.Offset(0, (sideF - paragraph.height) / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(side, side);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (png == null) return null;

    final dir = await _iconsDir();
    await dir.create(recursive: true);
    final dest = File(p.join(dir.path,
        'icon_gen_${DateTime.now().millisecondsSinceEpoch}_${_genSeq++}.png'));
    await dest.writeAsBytes(png.buffer.asUint8List(), flush: true);
    return dest.path;
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

  /// Varredura de órfãos: apaga PNGs de group_icons/ que NINGUÉM referencia
  /// (sobras de crash/fechamento no meio de um import).
  ///
  /// ⚠️ [referencedPaths] tem que trazer as fotos de grupo E de personagem —
  /// as duas moram nesta mesma pasta. Use
  /// `TrackerRepository.getAllIconImagePathsInUse()`; passar só uma das listas
  /// apagaria as fotos da outra. Chamar no início da sessão, nunca com dialog
  /// aberto.
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
