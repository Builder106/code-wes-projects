import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

const _treble = (clef: Clef.treble, notes: <PlacedNote>[
  (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
  (midi: 64, startBeat: 1, state: NoteState.missed),
  (midi: 67, startBeat: 2, state: NoteState.active),
  (midi: 72, startBeat: 3, state: NoteState.upcoming),
]);
const _bass = (clef: Clef.bass, notes: <PlacedNote>[
  (midi: 48, startBeat: 0, state: NoteState.hitGood),
  (midi: 55, startBeat: 2, state: NoteState.upcoming),
]);

Widget _harness(ThemeData theme, List<StaffSystem> systems) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(
          width: 740,
          height: 220,
          child: StaffView(
            systems: systems,
            currentBeat: 2,
            totalBeats: 8,
            beatsPerMeasure: 4,
            pixelsPerBeat: 70,
          ),
        ),
      ),
    );

/// Pins the test surface to the widget's own size so captured goldens are
/// all signal, with no empty margin from the default 800x600 test surface.
Future<void> _pinSurfaceSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(740, 220));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('renders a single staff without overflow', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
    expect(tester.takeException(), isNull);
    expect(find.byType(StaffView), findsOneWidget);
  });

  testWidgets('renders a grand staff without overflow', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden: single staff, light', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_single_light.png'));
  });

  testWidgets('golden: single staff, dark', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.dark(), const [_treble]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_single_dark.png'));
  });

  testWidgets('golden: grand staff, light', (tester) async {
    await _pinSurfaceSize(tester);
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_grand_light.png'));
  });
}
