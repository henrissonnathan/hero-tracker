import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Ativa o backend FFI do sqflite APENAS em desktop (Windows/Linux).
/// Em Android/iOS não faz nada — caminho atual permanece intocado (L1).
void initDesktopDatabaseFactory() {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
