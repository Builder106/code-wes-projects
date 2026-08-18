import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/app_theme.dart';
import 'ui/game/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole app is landscape. Locking a single screen would rotate the
  // user in and out as they navigate.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: PianoToolApp()));
}

class PianoToolApp extends ConsumerWidget {
  const PianoToolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Piano Tool',
      debugShowCheckedModeBanner: false,
      theme: PianoTheme.light(),
      darkTheme: PianoTheme.dark(),
      themeMode: ThemeMode.system,
      home: const GameScreen(),
    );
  }
}
