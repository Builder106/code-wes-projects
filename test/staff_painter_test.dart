import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';

void main() {
  group('StaffPainter Diatonic Mapping Tests', () {
    final painter = StaffPainter(
      level: const LevelModel(
        id: 'test',
        title: 'Test',
        description: 'Test',
        tempo: 120,
        beatsPerMeasure: 4,
        totalMeasures: 1,
        measures: [],
      ),
      allNotes: const [],
      noteStates: const [],
      currentBeat: 0.0,
      pixelsPerBeat: 80.0,
      staffTop: 40.0,
      staffHeight: 180.0,
    );

    test('Middle line B4 (MIDI 71) is placed exactly at staff center', () {
      expect(painter.midiToY(71), equals(painter.staffCenter));
    });

    test('Bottom line E4 (MIDI 64) and top line F5 (MIDI 77) are equidistant from center', () {
      final yE4 = painter.midiToY(64);
      final yF5 = painter.midiToY(77);

      expect(yE4, equals(painter.staffCenter + 2 * painter.lineGap));
      expect(yF5, equals(painter.staffCenter - 2 * painter.lineGap));
    });

    test('Middle C / C4 (MIDI 60) is exactly 1 ledger line below bottom line', () {
      final yC4 = painter.midiToY(60);
      expect(yC4, equals(painter.staffCenter + 3 * painter.lineGap));
    });

    test('Diatonic steps are properly spaced across scale degrees', () {
      final yC4 = painter.midiToY(60);
      final yD4 = painter.midiToY(62);
      final yE4 = painter.midiToY(64);
      final yF4 = painter.midiToY(65);
      final yG4 = painter.midiToY(67);
      final yA4 = painter.midiToY(69);
      final yB4 = painter.midiToY(71);

      expect(yC4 - yD4, closeTo(painter.stepSpacing, 0.001));
      expect(yD4 - yE4, closeTo(painter.stepSpacing, 0.001));
      expect(yE4 - yF4, closeTo(painter.stepSpacing, 0.001));
      expect(yF4 - yG4, closeTo(painter.stepSpacing, 0.001));
      expect(yG4 - yA4, closeTo(painter.stepSpacing, 0.001));
      expect(yA4 - yB4, closeTo(painter.stepSpacing, 0.001));
    });
  });
}
