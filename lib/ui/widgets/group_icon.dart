import 'dart:io';

import 'package:flutter/material.dart';

/// Ícone de grupo: mostra a foto interna se existir; senão (arquivo ausente,
/// corrompido ou nunca definido) cai no emoji — fallback garantido.
class GroupIcon extends StatelessWidget {
  final String? imagePath;
  final String? emoji;
  final double size;

  const GroupIcon({
    super.key,
    this.imagePath,
    this.emoji,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiFallback(),
        ),
      );
    }
    return _emojiFallback();
  }

  Widget _emojiFallback() =>
      Text(emoji ?? '⚔️', style: TextStyle(fontSize: size));
}
