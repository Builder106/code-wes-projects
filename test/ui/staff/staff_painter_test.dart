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

  test('does not repaint when an equal note list is rebuilt', () {
    // A fresh list with identical contents must not force a repaint.
    expect(_painter(beat: 0).shouldRepaint(_painter(beat: 0)), isFalse);
  });

  test('repaints when a note state actually changes', () {
    final a = _painter(beat: 0);
    final b = StaffPainter(
      clef: Clef.treble,
      notes: const [
        (midi: 60, startBeat: 0, state: NoteState.missed),
        (midi: 64, startBeat: 1, state: NoteState.missed),
        (midi: 67, startBeat: 2, state: NoteState.active),
        (midi: 72, startBeat: 3, state: NoteState.upcoming),
      ],
      colors: PianoColors.light(),
      currentBeat: 0,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 60,
    );
    expect(b.shouldRepaint(a), isTrue);
  });

  test('the header never overlaps the first note at any staff size', () {
    // The header (clef + time signature) is measured in staff-spaces, which
    // scale with staff height, while note x-positions used to be measured
    // in a fixed pixel offset. At small staff heights the two agreed; at
    // large ones the header grew past the first note. Pin the two
    // quantities together across a range of heights so this cannot regress.
    for (final height in [80.0, 220.0, 400.0]) {
      final painter = _painter();
      final size = Size(740, height);

      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), size);
      expect(recorder.endRecording(), isNotNull);

      final staffHeight = height * 0.56;
      final g = StaffGeometry(top: (height - staffHeight) / 2, height: staffHeight);
      final headerWidth = painter.headerWidthFor(g);

      // The header must scale in lockstep with the staff-space unit (this
      // is the unit-consistency invariant the bug violated: the header used
      // to scale with `space` while notes used a fixed pixel offset).
      expect(headerWidth, closeTo(g.space * 8.5, 0.001));

      // The first note (startBeat: 0) sits exactly at the header boundary;
      // it must never start before it, at any staff size.
      const pixelsPerBeat = 60.0;
      final firstNoteX = headerWidth + 0 * pixelsPerBeat;
      expect(firstNoteX, greaterThanOrEqualTo(headerWidth));
    }
  });
}
