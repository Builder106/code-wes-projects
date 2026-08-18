import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/engine_models.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../staff/staff_geometry.dart';
import '../staff/staff_painter.dart';
import '../staff/staff_view.dart';
import 'practice_hud.dart';
import 'stage_controller.dart';
import 'transport_column.dart';

/// The practice loop: a fixed control column on the left, with the HUD, the
/// staff, and the keyboard stacked beside it.
///
/// The control column is the only fixed size in the layout, and it sits on the
/// horizontal axis, which has slack. Every vertical child either wraps its own
/// content, is clamped, or takes the remainder, so there is no arrangement of
/// screen sizes that can overflow the column.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow slices only: a score change must not rebuild anything that reads
    // the level, and vice versa.
    final level = ref.watch(stageControllerProvider(stageId).select((s) => s.level));
    final levelNotes = ref.watch(stageControllerProvider(stageId).select((s) => s.notes));
    final noteStates = ref.watch(noteStatesProvider(stageId));
    final currentBeat = ref.watch(currentBeatProvider(stageId));
    final score = ref.watch(scoreProvider(stageId));
    final accuracy = ref.watch(accuracyProvider(stageId));
    final status = ref.watch(engineStatusProvider(stageId));
    final speed = ref.watch(playbackSpeedProvider(stageId));
    final controller = ref.read(stageControllerProvider(stageId).notifier);

    final notes = <PlacedNote>[
      for (var i = 0; i < levelNotes.length; i++)
        (
          midi: levelNotes[i].midiNote,
          startBeat: levelNotes[i].startBeat,
          state: i < noteStates.length ? noteStates[i] : NoteState.upcoming,
        ),
    ];

    // The keyboard shows what the learner should be playing now. Sounding
    // notes come from the microphone and are not wired here yet.
    final due = {
      for (final note in notes)
        if (note.state == NoteState.active) note.midi,
    };

    final totalBeats = (level.totalMeasures * level.beatsPerMeasure).toDouble();
    final progress = totalBeats > 0 ? (currentBeat / totalBeats).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            TransportColumn(
              isPlaying: status == StageEngineStatus.playing,
              speed: speed,
              onPlayPause: () {
                switch (status) {
                  case StageEngineStatus.playing:
                    controller.pause();
                  case StageEngineStatus.paused:
                    controller.resume();
                  case _:
                    controller.start();
                }
              },
              onStop: controller.stop,
              onReplay: controller.replay,
              onSpeedChanged: controller.setSpeed,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The keyboard takes a fifth of the height, floored and
                  // capped so it stays legible on a short screen without
                  // eating a tall one.
                  final keyboardHeight =
                      (constraints.maxHeight * 0.21).clamp(64.0, 88.0);

                  return Column(
                    children: [
                      PracticeHud(
                        title: level.title,
                        tempo: level.tempo,
                        score: score,
                        accuracy: accuracy,
                        progress: progress,
                        onBack: Navigator.of(context).canPop()
                            ? () => Navigator.of(context).pop()
                            : null,
                      ),
                      // The staff takes the remainder, so it grows on a larger
                      // screen instead of leaving a dead band.
                      Expanded(
                        child: StaffView(
                          systems: [(clef: Clef.treble, notes: notes)],
                          currentBeat: currentBeat,
                          totalBeats: totalBeats,
                          beatsPerMeasure: level.beatsPerMeasure,
                          pixelsPerBeat: 70,
                        ),
                      ),
                      SizedBox(
                        height: keyboardHeight,
                        child: PianoKeyboardView(due: due),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
