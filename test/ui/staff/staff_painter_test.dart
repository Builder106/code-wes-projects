import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

StaffPainter _painter({Clef clef = Clef.treble, double beat = 0}) => StaffPainter(
      clef: clef,
      notes: const [
        (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
        (midi: 64, startBeat: 1, state: NoteState.missed),
        (midi: 67, startBeat: 2, state: NoteState.active),
        (midi: 72, startBeat: 3, state: NoteState.upcoming),
      ],
      colors: PianoColors.light(),
      currentBeat: beat,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 60,
      leadingBeats: 2,
    );

void main() {
  test('painting does not throw for either clef', () {
    for (final clef in Clef.values) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _painter(clef: clef).paint(canvas, const Size(600, 200));
      expect(recorder.endRecording(), isNotNull);
    }
  });

  test('repaints when the playhead moves, not otherwise', () {
    expect(_painter(beat: 1).shouldRepaint(_painter(beat: 0)), isTrue);
    expect(_painter(beat: 0).shouldRepaint(_painter(beat: 0)), isFalse);
  });
}
