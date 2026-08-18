import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'note_glyph.dart';
import 'staff_geometry.dart';

/// A note positioned in beats, resolved to a MIDI number.
typedef PlacedNote = ({int midi, double startBeat, NoteState state});

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.clef,
    required this.notes,
    required this.colors,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    required this.leadingBeats,
  });

  final Clef clef;
  final List<PlacedNote> notes;
  final PianoColors colors;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final double pixelsPerBeat;

  /// Horizontal room reserved for the clef and time signature.
  final double leadingBeats;

  @override
  void paint(Canvas canvas, Size size) {
    // The staff occupies the middle 56% of the band, leaving room above and
    // below for ledger lines.
    final staffHeight = size.height * 0.56;
    final g = StaffGeometry(top: (size.height - staffHeight) / 2, height: staffHeight);

    final linePaint = Paint()
      ..color = colors.staff
      ..strokeWidth = 1.0;

    for (var i = 0; i < 5; i++) {
      final y = g.lineY(i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final barPaint = Paint()
      ..color = colors.staff.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (var beat = beatsPerMeasure; beat <= totalBeats; beat += beatsPerMeasure) {
      final x = _xForBeat(beat.toDouble());
      canvas.drawLine(Offset(x, g.topLineY), Offset(x, g.bottomLineY), barPaint);
    }

    _paintGlyph(canvas, _clefCodepoint(clef), g.clefFontSize(clef),
        Offset(g.space * 0.5, g.clefCenterY(clef)), colors.ink);

    _paintTimeSignature(canvas, g);

    for (final note in notes) {
      final x = _xForBeat(note.startBeat);
      final y = g.yForMidi(note.midi, clef);

      for (final ledgerY in g.ledgerLinesFor(note.midi, clef)) {
        canvas.drawLine(
          Offset(x - g.space, ledgerY),
          Offset(x + g.space, ledgerY),
          linePaint,
        );
      }

      // Notes above the middle line hang their stems down.
      NoteGlyph.paint(canvas, Offset(x, y), g, note.state, colors,
          stemDown: y < g.lineY(2));
    }

    final playheadX = _xForBeat(currentBeat);
    final playheadPaint = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);
    canvas.drawCircle(Offset(playheadX, 0), 3.5, Paint()..color = colors.accent);
  }

  double _xForBeat(double beat) => (beat + leadingBeats) * pixelsPerBeat;

  static int _clefCodepoint(Clef clef) =>
      switch (clef) { Clef.treble => 0xE050, Clef.bass => 0xE062 };

  void _paintGlyph(
      Canvas canvas, int codepoint, double fontSize, Offset anchor, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(fontFamily: 'Bravura', fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Bravura's glyph origin sits on its reference staff line, so the anchor
    // is the baseline rather than the visual centre.
    painter.paint(canvas, Offset(anchor.dx, anchor.dy - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
  }

  void _paintTimeSignature(Canvas canvas, StaffGeometry g) {
    final x = g.space * 5.5;
    final style = TextStyle(
      fontFamily: 'CormorantGaramond',
      fontWeight: FontWeight.w700,
      fontSize: g.timeSignatureFontSize,
      height: 0.88,
      color: colors.ink,
    );
    for (final (i, digit) in ['$beatsPerMeasure', '4'].indexed) {
      final painter = TextPainter(
        text: TextSpan(text: digit, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x, g.lineY(i == 0 ? 0 : 2)));
    }
  }

  @override
  bool shouldRepaint(StaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.notes != notes ||
      old.colors != colors ||
      old.clef != clef;
}
