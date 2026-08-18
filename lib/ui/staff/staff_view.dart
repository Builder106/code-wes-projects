import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'staff_geometry.dart';
import 'staff_painter.dart';

typedef StaffSystem = ({Clef clef, List<PlacedNote> notes});

/// Draws one system per entry, splitting the available height between them.
/// A grand staff is two systems; nothing about the painter changes.
class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    required this.systems,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
  });

  final List<StaffSystem> systems;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final double pixelsPerBeat;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return ColoredBox(
      color: colors.paper,
      child: Column(
        children: [
          for (final (index, system) in systems.indexed)
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: StaffPainter(
                  clef: system.clef,
                  notes: system.notes,
                  colors: colors,
                  currentBeat: currentBeat,
                  totalBeats: totalBeats,
                  beatsPerMeasure: beatsPerMeasure,
                  pixelsPerBeat: pixelsPerBeat,
                  showPlayheadCap: index == 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
