import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_tool/ui/practice/practice_screen.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/keyboard/piano_keyboard_view.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness() => ProviderScope(
      overrides: [audioGrantedProvider.overrideWith((ref) async => true)],
      child: MaterialApp(
        theme: PianoTheme.light(),
        home: const PracticeScreen(stageId: 'stage_1'),
      ),
    );

/// Landscape sizes that bracket real phones, including the narrowest.
const _sizes = [Size(640, 360), Size(740, 360), Size(915, 412)];

void main() {
  for (final size in _sizes) {
    testWidgets('renders without overflow at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness());
      await tester.pump();

      // A RenderFlex overflow surfaces as a thrown exception in tests, which
      // is exactly the failure the old screen shipped.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the staff, the keyboard, and the transport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(740, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(find.byType(StaffView), findsOneWidget);
    expect(find.byType(PianoKeyboardView), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('the title yields to the metrics rather than pushing them off',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    // Every metric stays on screen even at the narrowest width; the title is
    // the thing that ellipsizes.
    expect(find.textContaining('BPM'), findsOneWidget);
    expect(find.textContaining('Score'), findsOneWidget);
    expect(find.textContaining('Acc'), findsOneWidget);
  });

  testWidgets('all 61 keys fit without a scroll view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness());
    await tester.pump();

    expect(
      find.descendant(of: find.byType(PianoKeyboardView), matching: find.byType(Scrollable)),
      findsNothing,
    );
  });
}
