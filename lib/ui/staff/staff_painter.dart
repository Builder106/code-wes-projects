import 'package:flutter/material.dart';
import '../../models/level_models.dart';
import '../../models/engine_models.dart';

/// Custom painter for horizontal sheet music staff
class StaffPainter extends CustomPainter {
  final LevelModel level;
  final List<LevelNote> allNotes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final double beatsPerMeasure;
  final double pixelsPerBeat;
  final double staffTop;
  final double staffHeight;
  final int clefOctave;
  final bool showMeasureNumbers;
  final bool showBeatGrid;
  final bool isDarkMode;

  static const List<int> _diatonicOffsets = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

  StaffPainter({
    required this.level,
    required this.allNotes,
    required this.noteStates,
    required this.currentBeat,
    required this.pixelsPerBeat,
    this.beatsPerMeasure = 4.0,
    this.staffTop = 40.0,
    this.staffHeight = 180.0,
    this.clefOctave = 4,
    this.showMeasureNumbers = true,
    this.showBeatGrid = true,
    this.isDarkMode = false,
  });

  double get staffCenter => staffTop + staffHeight / 2;
  double get lineGap => 14.0;
  double get stepSpacing => lineGap / 2.0;

  /// Get diatonic relative step from B4 (middle line of treble staff = 0)
  int _getRelativeDiatonicStep(int midiNote) {
    final octave = (midiNote ~/ 12) - 1;
    final noteInOctave = midiNote % 12;
    final absDiatonicStep = octave * 7 + _diatonicOffsets[noteInOctave];
    const b4DiatonicStep = 4 * 7 + 6; // B4 = 34
    return absDiatonicStep - b4DiatonicStep;
  }

  /// Convert MIDI note to Y position on staff
  double midiToY(int midiNote) {
    final relativeStep = _getRelativeDiatonicStep(midiNote);
    return staffCenter - (relativeStep * stepSpacing);
  }

  /// Get note head color based on state
  Color _getNoteColor(NoteState state, bool isDarkMode) {
    switch (state) {
      case NoteState.upcoming:
        return isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
      case NoteState.active:
        return isDarkMode ? Colors.lightBlueAccent : Colors.blue[600]!;
      case NoteState.hitPerfect:
        return isDarkMode ? Colors.greenAccent : Colors.green[600]!;
      case NoteState.hitGood:
        return isDarkMode ? Colors.lightGreenAccent : Colors.green[400]!;
      case NoteState.hitOkay:
        return isDarkMode ? Colors.amberAccent : Colors.orange[600]!;
      case NoteState.missed:
        return isDarkMode ? Colors.redAccent : Colors.red[600]!;
    }
  }

  /// Get stem direction (up or down)
  bool _stemUp(int midiNote) {
    // B4 (midi 71) is step 0. Notes below B4 have stems pointing UP; at/above B4 have stems pointing DOWN.
    return _getRelativeDiatonicStep(midiNote) < 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..color = isDarkMode ? Colors.white70 : Colors.black87;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode ? Colors.white : Colors.black;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Calculate staff dimensions
    final double staffLeft = 0;
    final double staffRight = size.width;
    final double staffBottom = staffTop + staffHeight;
    final double lineSpacing = staffHeight / 8; // 4 lines + 4 spaces = 8 positions per octave-ish

    // Draw beat grid (vertical lines)
    if (showBeatGrid) {
      final gridPaint = Paint()
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke
        ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1);

      final totalBeats = level.totalMeasures * level.beatsPerMeasure;
      for (int beat = 0; beat <= totalBeats; beat++) {
        final x = beat * pixelsPerBeat;
        if (x < 0 || x > size.width) continue;

        final isMeasureStart = beat % level.beatsPerMeasure == 0;
        gridPaint.strokeWidth = isMeasureStart ? 1.0 : 0.5;
        gridPaint.color = isMeasureStart
            ? (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.2)
            : (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1);

        canvas.drawLine(Offset(x, staffTop), Offset(x, staffBottom), gridPaint);
      }
    }

    // Draw staff lines (5 lines centered on staffCenter)
    for (int line = -2; line <= 2; line++) {
      final y = staffCenter + line * lineGap;
      canvas.drawLine(
        Offset(staffLeft, y),
        Offset(staffRight, y),
        paint,
      );
    }

    // Draw measure lines (thicker at measure boundaries)
    final measurePaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = isDarkMode ? Colors.white : Colors.black;

    for (int measure = 0; measure <= level.totalMeasures; measure++) {
      final x = measure * level.beatsPerMeasure * pixelsPerBeat;
      if (x < 0 || x > size.width) continue;

      canvas.drawLine(
        Offset(x, staffCenter - 2.5 * lineGap),
        Offset(x, staffCenter + 2.5 * lineGap),
        measurePaint,
      );

      // Measure numbers
      if (showMeasureNumbers && measure < level.totalMeasures) {
        textPainter.text = TextSpan(
          text: '${measure + 1}',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 4, staffCenter - 2.5 * lineGap - 18));
      }
    }

    // Draw treble clef symbol
    _drawTrebleClef(canvas, staffLeft + 20, staffTop, staffHeight, isDarkMode);

    // Draw notes
    for (int i = 0; i < allNotes.length; i++) {
      final note = allNotes[i];
      final noteState = i < noteStates.length ? noteStates[i] : NoteState.upcoming;

      if (note.isRest) continue;

      final x = note.startBeat * pixelsPerBeat;
      if (x < -50 || x > size.width + 50) continue; // Cull off-screen notes

      final y = midiToY(note.midiNote);
      final color = _getNoteColor(noteState, isDarkMode);

      // Draw note head
      _drawNoteHead(canvas, x, y, note.durationBeats, color, fillPaint, _stemUp(note.midiNote));

      // Draw ledger lines if needed
      _drawLedgerLines(canvas, x, y, note.midiNote, color);
    }

    // Draw playhead
    _drawPlayhead(canvas, currentBeat * pixelsPerBeat, staffCenter - 3 * lineGap, staffCenter + 3 * lineGap, isDarkMode, size.width);
  }

  void _drawTrebleClef(Canvas canvas, double x, double y, double height, bool isDarkMode) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = x + 15;
    final centerY = staffCenter;
    final clefHeight = lineGap * 5.5;

    // Simplified treble clef path
    final path = Path();

    // Start at bottom
    path.moveTo(centerX, centerY + clefHeight / 2);
    // Curve up and around
    path.cubicTo(
      centerX - 15, centerY + clefHeight / 2,
      centerX - 15, centerY - clefHeight / 3,
      centerX + 5, centerY - clefHeight / 3,
    );
    // Loop around
    path.cubicTo(
      centerX + 20, centerY - clefHeight / 3,
      centerX + 20, centerY + clefHeight / 4,
      centerX + 5, centerY + clefHeight / 4,
    );
    // Down to bottom
    path.cubicTo(
      centerX - 10, centerY + clefHeight / 4,
      centerX - 10, centerY + clefHeight / 2,
      centerX, centerY + clefHeight / 2,
    );
    // Tail
    path.moveTo(centerX, centerY + clefHeight / 2);
    path.lineTo(centerX, centerY + clefHeight / 2 + 15);

    canvas.drawPath(path, paint);

    // Dot on the G line (second line from bottom = staffCenter + lineGap)
    final gLineY = staffCenter + lineGap;
    final dotPaint = Paint()
      ..color = isDarkMode ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX + 18, gLineY), 2.5, dotPaint);
  }

  void _drawNoteHead(Canvas canvas, double x, double y, double duration, Color color, Paint fillPaint, bool stemUp) {
    final noteHeadWidth = 12.0;
    final noteHeadHeight = 8.0;
    final stemHeight = 35.0;
    final stemWidth = 1.5;

    fillPaint.color = color;

    // Note head (oval)
    final headRect = Rect.fromCenter(
      center: Offset(x, y),
      width: noteHeadWidth,
      height: noteHeadHeight,
    );
    canvas.drawOval(headRect, fillPaint);

    // Stem
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = stemWidth
      ..style = PaintingStyle.stroke;

    final stemX = stemUp ? x + noteHeadWidth / 2 : x - noteHeadWidth / 2;
    final stemStartY = stemUp ? y - noteHeadHeight / 2 : y + noteHeadHeight / 2;
    final stemEndY = stemUp ? stemStartY - stemHeight : stemStartY + stemHeight;

    canvas.drawLine(
      Offset(stemX, stemStartY),
      Offset(stemX, stemEndY),
      stemPaint,
    );

    // Flag for eighth notes or shorter
    if (duration <= 0.5) {
      _drawFlag(canvas, stemX, stemEndY, stemUp, color);
    }
  }

  void _drawFlag(Canvas canvas, double x, double y, bool stemUp, Color color) {
    final flagPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final flagHeight = 12.0;
    final flagWidth = 8.0;

    if (stemUp) {
      // Flag goes up and right from top of stem
      path.moveTo(x, y);
      path.quadraticBezierTo(x + flagWidth, y - flagHeight / 2, x + flagWidth, y - flagHeight);
    } else {
      // Flag goes down and right from bottom of stem
      path.moveTo(x, y);
      path.quadraticBezierTo(x + flagWidth, y + flagHeight / 2, x + flagWidth, y + flagHeight);
    }

    canvas.drawPath(path, flagPaint);
  }

  void _drawLedgerLines(Canvas canvas, double x, double y, int midiNote, Color color) {
    final relStep = _getRelativeDiatonicStep(midiNote);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const lineLength = 20.0;

    // Staff lines are at relSteps: -4 (E4), -2 (G4), 0 (B4), +2 (D5), +4 (F5)
    // Ledger lines below staff: at -6 (C4), -8 (A3), -10 (F3), etc.
    if (relStep <= -6) {
      final lowestLine = relStep.isEven ? relStep : relStep - 1;
      for (int step = -6; step >= lowestLine; step -= 2) {
        final lineY = staffCenter - (step * stepSpacing);
        canvas.drawLine(
          Offset(x - lineLength / 2, lineY),
          Offset(x + lineLength / 2, lineY),
          linePaint,
        );
      }
    }
    // Ledger lines above staff: at +6 (A5), +8 (C6), +10 (E6), etc.
    else if (relStep >= 6) {
      final highestLine = relStep.isEven ? relStep : relStep + 1;
      for (int step = 6; step <= highestLine; step += 2) {
        final lineY = staffCenter - (step * stepSpacing);
        canvas.drawLine(
          Offset(x - lineLength / 2, lineY),
          Offset(x + lineLength / 2, lineY),
          linePaint,
        );
      }
    }
  }

  void _drawPlayhead(Canvas canvas, double x, double top, double bottom, bool isDarkMode, double canvasWidth) {
    if (x < 0 || x > canvasWidth) return;

    final paint = Paint()
      ..color = isDarkMode ? Colors.redAccent : Colors.red[600]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw playhead line
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      paint,
    );

    // Draw triangle at top
    final trianglePaint = Paint()
      ..color = isDarkMode ? Colors.redAccent : Colors.red[600]!
      ..style = PaintingStyle.fill;

    final trianglePath = Path();
    trianglePath.moveTo(x, top - 8);
    trianglePath.lineTo(x - 6, top);
    trianglePath.lineTo(x + 6, top);
    trianglePath.close();

    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.currentBeat != currentBeat ||
        oldDelegate.noteStates != noteStates ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.level != level ||
        oldDelegate.isDarkMode != isDarkMode;
  }

  @override
  bool shouldRebuildSemantics(covariant StaffPainter oldDelegate) => false;
}