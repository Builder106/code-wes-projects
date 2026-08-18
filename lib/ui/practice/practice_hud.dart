import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PracticeHud extends StatelessWidget {
  const PracticeHud({
    super.key,
    required this.title,
    required this.tempo,
    required this.score,
    required this.accuracy,
    required this.progress,
    this.onBack,
  });

  final String title;
  final int tempo;
  final int score;
  final double accuracy;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: PianoSpacing.sm),
          decoration: BoxDecoration(
            color: colors.paper2,
            border: Border(bottom: BorderSide(color: colors.rule)),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  iconSize: 18,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Back',
                ),
              // The title yields, never the metrics. This is what stops the
              // header collapsing to "C ..." on a narrow screen.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(width: PianoSpacing.sm),
              _Metric(label: 'BPM', value: '$tempo'),
              const SizedBox(width: PianoSpacing.md),
              _Metric(label: 'Score', value: '$score'),
              const SizedBox(width: PianoSpacing.md),
              _Metric(label: 'Acc', value: '${(accuracy * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.rule2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: text.labelSmall),
        Text(value, style: text.labelLarge),
      ],
    );
  }
}
