import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_engine.dart';
import '../../data/level_repository.dart';
import '../../data/progress_repository.dart';
import '../../engine/stage_engine.dart';
import '../../models/engine_models.dart';
import '../../models/level_models.dart';

/// Whether the microphone was granted. Overridden in tests so the controller
/// can run without hardware.
final audioGrantedProvider = FutureProvider<bool>((ref) async {
  final engine = AudioEngine();
  final granted = await engine.initialize();
  if (granted) {
    await engine.start();
    ref.onDispose(engine.dispose);
  } else {
    await engine.dispose();
  }
  return granted;
});

/// Alias kept for call sites that read microphone state by its UI-facing
/// name rather than the underlying grant check.
final micPermissionProvider = audioGrantedProvider;

/// Everything the practice screen can show, in one immutable value.
class StageUiState {
  const StageUiState({
    required this.level,
    required this.notes,
    required this.noteStates,
    required this.currentBeat,
    required this.score,
    required this.accuracy,
    required this.status,
    required this.speed,
  });

  final LevelModel level;
  final List<LevelNote> notes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final int score;
  final double accuracy;
  final StageEngineStatus status;
  final double speed;

  double get progress {
    final total = level.totalMeasures * level.beatsPerMeasure;
    return total > 0 ? (currentBeat / total).clamp(0.0, 1.0) : 0.0;
  }

  StageUiState copyWith({
    List<NoteState>? noteStates,
    double? currentBeat,
    int? score,
    double? accuracy,
    StageEngineStatus? status,
    double? speed,
  }) =>
      StageUiState(
        level: level,
        notes: notes,
        noteStates: noteStates ?? this.noteStates,
        currentBeat: currentBeat ?? this.currentBeat,
        score: score ?? this.score,
        accuracy: accuracy ?? this.accuracy,
        status: status ?? this.status,
        speed: speed ?? this.speed,
      );
}

class StageController extends StateNotifier<StageUiState> {
  StageController(this._engine, this._stageId, this._progress, StageUiState initial)
      : super(initial) {
    _sub = _engine.events.listen(_onEvent);
  }

  final StageEngine _engine;
  final String _stageId;
  final ProgressRepository _progress;
  StreamSubscription<StageEvent>? _sub;

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  void start() {
    _engine.start();
    _progress.setLastPlayed(_stageId);
    _sync();
  }

  void pause() {
    _engine.pause();
    _sync();
  }

  void resume() {
    _engine.resume();
    _sync();
  }

  /// Halts and holds position. Distinct from [replay], which rewinds.
  void stop() {
    _engine.stop();
    _sync();
  }

  /// Returns to the start and plays again.
  void replay() {
    _engine.reset();
    _engine.start();
    _sync();
  }

  void seekTo(double beat) {
    _engine.seekToBeat(beat);
    _sync();
  }

  void setSpeed(double speed) {
    final clamped = speed.clamp(minSpeed, maxSpeed);
    _engine.setPlaybackSpeed(clamped);
    state = state.copyWith(speed: clamped);
  }

  void _onEvent(StageEvent event) {
    _sync();
    event.whenOrNull(stageCompleted: (accuracy, score, totalNotes, hitNotes) {
      _progress.record(stageId: _stageId, accuracy: accuracy, score: score);
    });
  }

  void _sync() {
    final s = _engine.state;
    state = state.copyWith(
      noteStates: List.of(s.noteStates),
      currentBeat: s.currentBeat,
      score: s.score,
      accuracy: s.accuracy,
      status: s.engineState,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

final stageControllerProvider =
    StateNotifierProvider.family<StageController, StageUiState, String>((ref, stageId) {
  final stages = ref.read(levelRepositoryProvider).getAllStages();
  final stage = stages.cast<StageModel?>().firstWhere(
        (s) => s?.id == stageId,
        orElse: () => null,
      );
  if (stage == null) {
    // Loud, not silent: a bad id is a routing bug and should not render an
    // empty staff that looks like a loading state.
    throw StateError('No stage with id "$stageId"');
  }

  final engine = StageEngine(level: stage.level);
  final notes = [
    for (final m in stage.level.measures) ...m.notes,
  ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));

  return StageController(
    engine,
    stageId,
    ref.read(progressRepositoryProvider),
    StageUiState(
      level: stage.level,
      notes: notes,
      noteStates: List.of(engine.state.noteStates),
      currentBeat: 0,
      score: 0,
      accuracy: 0,
      status: engine.state.engineState,
      speed: 1.0,
    ),
  );
});

// Narrow slices. A widget watching one of these does not rebuild when an
// unrelated field changes, which is the whole point of this file.
final currentBeatProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.currentBeat)));
final scoreProvider = Provider.family<int, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.score)));
final accuracyProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.accuracy)));
final engineStatusProvider = Provider.family<StageEngineStatus, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.status)));
final noteStatesProvider = Provider.family<List<NoteState>, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.noteStates)));
final playbackSpeedProvider = Provider.family<double, String>(
    (ref, id) => ref.watch(stageControllerProvider(id).select((s) => s.speed)));
