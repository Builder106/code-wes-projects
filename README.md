# Piano Tool

A Flutter-based piano learning app with horizontal scrolling sheet music and real-time pitch detection.

## Features

- **Horizontal Sheet Music**: Scrollable staff rendering with treble/bass clef, measure lines, and note visualization
- **Real-time Pitch Detection**: YIN algorithm implementation for fundamental frequency estimation
- **Interactive Piano Keyboard**: 61-key (5 octave) visual keyboard with touch feedback
- **Game Engine**: Note matching with configurable pitch tolerance, scoring, and progression
- **Level System**: JSON-based level format with tempo, time signature, and measure/note data

## Architecture

```text
lib/
├── main.dart                    # App entry point
├── models/
│   ├── level_models.dart        # Level, Measure, Note, Pitch, Duration, Clef
│   ├── audio_models.dart        # PitchEvent, AudioConfig
│   └── engine_models.dart       # StageModel, StageNote, StageEvent, StageState
├── data/
│   └── level_repository.dart    # Asset-based level loading with caching
├── audio/
│   ├── pitch_detector.dart      # YIN algorithm implementation
│   └── audio_engine.dart        # Microphone permission + pitch detection wrapper
├── engine/
│   └── stage_engine.dart        # Core game logic: pitch matching, state machine
��── ui/
    ├── staff/
    │   ├── staff_painter.dart   # CustomPainter for staff rendering
    │   └── horizontal_staff.dart # Scrollable staff widget
    ├── keyboard/
    │   └── piano_keyboard.dart  # 61-key piano keyboard widget
    └── game/
        └── game_screen.dart     # Main game UI combining staff + keyboard
```

## Level Format (JSON)

```json
{
  "id": "twinkle_twinkle",
  "title": "Twinkle Twinkle Little Star - Right Hand",
  "tempo": 100,
  "timeSignature": { "numerator": 4, "denominator": 4 },
  "clef": "treble",
  "measures": [
    {
      "number": 1,
      "notes": [
        { "pitch": { "noteName": "c", "octave": 4 }, "duration": "quarter", "startBeat": 1.0 }
      ]
    }
  ],
  "difficulty": 1,
  "pitchToleranceCents": 50.0
}
```

## Getting Started

### Prerequisites

- Flutter SDK 3.2.0+
- Dart 3.2.0+
- Android Studio / Xcode for device deployment

### Installation

```bash
cd piano_tool
flutter pub get
flutter run
```

### Code Generation

After modifying freezed/json_serializable models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Key Components

### Pitch Detection (YIN Algorithm)

The `PitchDetector` class implements the YIN fundamental frequency estimator:

1. **Difference Function**: Computes squared difference for each lag τ
2. **Cumulative Mean Normalized Difference**: Normalizes to find periodicities
3. **Threshold Detection**: Finds first dip below threshold (0.1)
4. **Parabolic Interpolation**: Refines period estimate for sub-sample accuracy
5. **Confidence Calculation**: Autocorrelation at detected period

### Stage Engine

Manages the game state machine:

- `Idle` → `Playing` → `Paused` / `Completed` / `Failed`
- Matches detected pitches to expected notes within tolerance (default 50 cents)
- Emits events: `NoteHit`, `NoteMissed`, `StageCompleted`, `PlaybackPosition`

### Staff Rendering

Custom `StaffPainter` draws:

- 5-line staff with configurable spacing
- Treble/bass clef symbols
- Time signature
- Measure lines and beat grid
- Notes with stems, flags, accidentals, and ledger lines
- Color-coded note states (upcoming/active/hit/missed)
- Animated playhead

## Configuration

Key tunable parameters in `AudioConfig`:

- `sampleRate`: 44100 Hz (CD quality)
- `bufferSize`: 1024 samples (~23ms at 44.1kHz)
- `minConfidence`: 0.01 (filter noise)
- `minFrequency`/`maxFrequency`: 80-2000 Hz (piano range)
- `pitchToleranceCents`: 50 (quarter tone tolerance)

## Platform Notes

### Android

- Requires `RECORD_AUDIO` permission
- Minimum SDK 24 (Android 7.0)

### iOS

- Requires `NSMicrophoneUsageDescription` in Info.plist
- Minimum iOS 12.0

## Future Improvements

- [ ] WebRTC AEC/AGC for echo cancellation
- [ ] MIDI input support
- [ ] Audio playback of background music
- [ ] More sophisticated note onset detection
- [ ] Multi-voice/polyphonic detection
- [ ] Level editor UI
- [ ] Progress tracking and statistics
