// Helpers compartilhados dos testes (Fase 1 do roadmap).
import 'package:flutter_test/flutter_test.dart';

/// Bomba frames com tempo REAL até o [finder] aparecer (ou estourar [timeout]).
/// Substitui os Future.delayed fixos: o banco (FFI) roda em I/O real, que não
/// anda no tempo simulado do ambiente de teste.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  fail('Widget não apareceu em ${timeout.inSeconds}s: $finder');
}

/// O inverso: espera o [finder] SUMIR (ex.: spinner de loading).
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  fail('Widget não sumiu em ${timeout.inSeconds}s: $finder');
}
