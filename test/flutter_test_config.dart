import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter test harnesses do not load fonts declared in pubspec.yaml, so text
/// renders as tofu boxes unless the bytes are loaded explicitly. Golden images
/// would otherwise bake in missing glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('CormorantGaramond', 'assets/fonts/CormorantGaramond.ttf');
  await _load('IBMPlexSans', 'assets/fonts/IBMPlexSans.ttf');
  await _load('Bravura', 'assets/fonts/Bravura.otf');
  await testMain();
}

Future<void> _load(String family, String path) async {
  final data = await rootBundle.load(path);
  await ui.loadFontFromList(data.buffer.asUint8List(), fontFamily: family);
}
