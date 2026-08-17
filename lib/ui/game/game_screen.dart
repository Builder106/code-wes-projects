import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/level_models.dart';
import '../../models/audio_models.dart';
import '../../models/engine_models.dart';
import '../../data/level_repository.dart';
import '../../audio/audio_engine.dart';
import '../../engine/stage_engine.dart';
import '../staff/horizontal_staff.dart';
import '../keyboard/piano_keyboard.dart';

/// Main game screen combining staff and keyboard
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  StageModel? _currentStage;
  LevelModel? _currentLevel;
  StageEngine? _stageEngine;
  StreamSubscription<StageEvent>? _eventSubscription;
  AudioEngine? _audioEngine;
  StreamSubscription<PitchEvent>? _audioSubscription;

  // UI state
  double _pixelsPerBeat = 80.0;
  int _midiHighlightKey = -1;
  int _touchHighlightKey = -1;
  Set<int> _activeNotes = {};
  Map<int, NoteState> _noteStates = {};

  // Animation
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    // Initialize audio and initial stage
    _initAudioEngine();
    _loadInitialStage();
  }

  Future<void> _initAudioEngine() async {
    _audioEngine = AudioEngine();
    final granted = await _audioEngine!.initialize();
    if (granted && mounted) {
      await _audioEngine!.start();
      _audioSubscription = _audioEngine!.pitchStream.listen((event) {
        if (!mounted) return;
        setState(() {
          _midiHighlightKey = event.midiNote;
        });
        _stageEngine?.processPitchEvent(event);
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _midiHighlightKey == event.midiNote) {
            setState(() {
              _midiHighlightKey = -1;
            });
          }
        });
      });
    }
  }

  Future<void> _loadInitialStage() async {
    final repo = ref.read(levelRepositoryProvider);
    await Future.delayed(const Duration(milliseconds: 100)); // Allow asset loading

    final stages = repo.getAllStages();
    if (stages.isNotEmpty) {
      final firstStage = stages.firstWhere((s) => s.order == 1, orElse: () => stages.first);
      _switchToStage(firstStage);
    }
  }

  void _switchToStage(StageModel stage) {
    // Clean up previous engine
    _eventSubscription?.cancel();
    _stageEngine?.dispose();

    setState(() {
      _currentStage = stage;
      _currentLevel = stage.level;
      _stageEngine = StageEngine(level: stage.level);
      _pixelsPerBeat = 80.0;
      _midiHighlightKey = -1;
      _touchHighlightKey = -1;
      _activeNotes = {};
      _noteStates = {};
    });

    // Subscribe to stage events
    _eventSubscription = _stageEngine!.events.listen(_onStageEvent);

    // Start the stage automatically
    _stageEngine!.start();
  }

  void _onStageEvent(StageEvent event) {
    if (!mounted) return;

    event.when(
      noteHit: (noteIndex, result, currentBeat) {
        _updateNoteState(noteIndex, result.noteState);
        _updateActiveNotes(currentBeat);
      },
      noteMissed: (noteIndex, currentBeat) {
        _updateNoteState(noteIndex, NoteState.missed);
        _updateActiveNotes(currentBeat);
      },
      stageCompleted: (accuracy, score, totalNotes, hitNotes) {
        _showCompletionDialog(accuracy, score, totalNotes, hitNotes);
      },
      playbackPosition: (currentBeat, progress, isPlaying) {
        setState(() {
          // Trigger rebuild for playhead animation
        });
        _updateActiveNotes(currentBeat);
      },
      stateChanged: (state) {
        setState(() {});
      },
    );
  }

  void _updateNoteState(int noteIndex, NoteState state) {
    if (_currentLevel == null) return;

    final allNotes = _getAllNotes();
    if (noteIndex < 0 || noteIndex >= allNotes.length) return;

    final note = allNotes[noteIndex];
    setState(() {
      _noteStates[note.midiNote] = state;
    });
  }

  void _updateActiveNotes(double currentBeat) {
    if (_currentLevel == null) return;

    final allNotes = _getAllNotes();
    final newActiveNotes = <int>{};

    for (final note in allNotes) {
      final noteEndBeat = note.startBeat + note.durationBeats;
      if (currentBeat >= note.startBeat - 0.5 && currentBeat < noteEndBeat) {
        newActiveNotes.add(note.midiNote);
      }
    }

    setState(() {
      _activeNotes = newActiveNotes;
    });
  }

  List<LevelNote> _getAllNotes() {
    if (_currentLevel == null) return [];

    final notes = <LevelNote>[];
    for (final measure in _currentLevel!.measures) {
      notes.addAll(measure.notes);
    }
    notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    return notes;
  }

  void _showCompletionDialog(double accuracy, int score, int totalNotes, int hitNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Stage Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%'),
            Text('Score: $score'),
            Text('Notes Hit: $hitNotes / $totalNotes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stageEngine?.reset();
              _stageEngine?.start();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNextStage();
            },
            child: const Text('Next Stage'),
          ),
        ],
      ),
    );
  }

  void _loadNextStage() {
    if (_currentStage == null) return;

    final repo = ref.read(levelRepositoryProvider);
    final stages = repo.getAllStages();
    final currentIndex = stages.indexWhere((s) => s.id == _currentStage!.id);

    if (currentIndex + 1 < stages.length) {
      _switchToStage(stages[currentIndex + 1]);
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioEngine?.dispose();
    _eventSubscription?.cancel();
    _stageEngine?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onKeyPressed(int midiNote, bool down) {
    setState(() {
      if (down) {
        _touchHighlightKey = midiNote;
        // Send to stage engine as if it were a pitch event
        if (_stageEngine != null) {
          // Simulate a pitch event for testing
          _stageEngine!.processPitchEvent(PitchEvent(
            frequency: _midiToFrequency(midiNote),
            confidence: 1.0,
            midiNote: midiNote,
            timestamp: _stageEngine!.state.currentBeat * 60.0 / _currentLevel!.tempo,
            volume: 1.0,
          ));
        }
      } else {
        _touchHighlightKey = -1;
      }
    });
  }

  double _midiToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLevel == null || _stageEngine == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allNotes = _getAllNotes();
    final state = _stageEngine!.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStage!.title),
        actions: [
          // Tempo display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_currentLevel!.tempo} BPM',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ),
          // Score display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Score: ${state.score}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          // Accuracy display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Accuracy: ${(state.accuracy * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: state.accuracy >= 0.9
                          ? Colors.green
                          : state.accuracy >= 0.7
                              ? Colors.orange
                              : Colors.red,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal staff (70% height)
          Expanded(
            flex: 7,
            child: HorizontalStaff(
              level: _currentLevel!,
              allNotes: allNotes,
              noteStates: _getNoteStatesList(allNotes),
              currentBeat: state.currentBeat,
              pixelsPerBeat: _pixelsPerBeat,
              onSeek: (beat) {
                _stageEngine?.seekToBeat(beat);
              },
            ),
          ),

          // Playback controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    state.engineState == StageEngineStatus.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 32,
                  ),
                  onPressed: () {
                    if (state.engineState == StageEngineStatus.playing) {
                      _stageEngine?.pause();
                    } else if (state.engineState == StageEngineStatus.paused) {
                      _stageEngine?.resume();
                    } else if (state.engineState == StageEngineStatus.idle ||
                        state.engineState == StageEngineStatus.stopped) {
                      _stageEngine?.start();
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.stop, size: 32),
                  onPressed: () => _stageEngine?.reset(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.replay, size: 32),
                  onPressed: () => _stageEngine?.reset(),
                ),
                const Spacer(),
                // Speed control
                Text('Speed: ${_stageEngine!.state.currentBeat > 0 ? "1.0x" : "1.0x"}'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: 1.0,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '1.0x',
                    onChanged: (value) {
                      // TODO: Implement speed change
                    },
                  ),
                ),
                const Spacer(),
                // Progress indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Piano keyboard (30% height)
          Expanded(
            flex: 3,
            child: PianoKeyboard(
              highlightedKey: _touchHighlightKey,
              midiHighlightKey: _midiHighlightKey,
              activeNotes: _activeNotes,
              noteStates: _noteStates,
              keyWidth: 24.0,
              whiteKeyHeight: 160.0,
              onKeyPressed: _onKeyPressed,
            ),
          ),
        ],
      ),
    );
  }

  List<NoteState> _getNoteStatesList(List<LevelNote> allNotes) {
    return allNotes.map((note) => _noteStates[note.midiNote] ?? NoteState.upcoming).toList();
  }
}

/// Provider for the current game state
final gameStateProvider = StateProvider<GameState>((ref) => GameState.initial());

/// Provider for stage selection
final selectedStageProvider = StateProvider<String?>((ref) => null);