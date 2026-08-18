import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The left control column. Fixed width because it holds icon buttons at a
/// real touch target; the horizontal axis has room to spare.
class TransportColumn extends StatelessWidget {
  const TransportColumn({
    super.key,
    required this.isPlaying,
    required this.speed,
    required this.onPlayPause,
    required this.onStop,
    required this.onReplay,
    required this.onSpeedChanged,
  });

  static const double width = 60;

  /// The speeds the label cycles through, slowest first.
  static const List<double> speedSteps = [0.5, 0.75, 1.0, 1.5, 2.0];

  final bool isPlaying;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onReplay;
  final ValueChanged<double> onSpeedChanged;

  double get _nextSpeed {
    // Nearest step, so a speed set elsewhere still advances sensibly.
    var nearest = 0;
    for (var i = 1; i < speedSteps.length; i++) {
      if ((speedSteps[i] - speed).abs() < (speedSteps[nearest] - speed).abs()) {
        nearest = i;
      }
    }
    return speedSteps[(nearest + 1) % speedSteps.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.paper3,
        border: Border(right: BorderSide(color: colors.rule)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPlayPause,
            iconSize: 22,
            style: IconButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentInk,
            ),
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
          const SizedBox(height: PianoSpacing.sm),
          IconButton(
            onPressed: onStop,
            iconSize: 18,
            icon: const Icon(Icons.stop),
            tooltip: 'Stop and hold position',
          ),
          IconButton(
            onPressed: onReplay,
            iconSize: 18,
            icon: const Icon(Icons.replay),
            tooltip: 'Replay from the start',
          ),
          const SizedBox(height: PianoSpacing.xs),
          Tooltip(
            message: 'Playback speed',
            child: InkWell(
              onTap: () => onSpeedChanged(_nextSpeed),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PianoSpacing.xs,
                  vertical: PianoSpacing.xs2,
                ),
                child: Text('${speed.toStringAsFixed(1)}x',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
