# Piano Tool

A Flutter piano practice app. Sheet music scrolls horizontally while the
microphone listens, and each note is marked hit or missed against the pitch you
actually played.

Landscape only, on purpose. Sheet music and a five octave keyboard both want
horizontal space, and locking a single screen would rotate you in and out while
navigating.

## Status

The visual foundation is done and tested. The screens around it are not.

Working: the design system, the staff renderer, pitch detection, and the scoring
engine. Running the app still shows the pre-revamp practice screen, which has a
dead speed slider, a Stop and a Replay button that do the same thing, and no UI
at all when microphone permission is denied. That screen is replaced in phase 2.

See `JOURNAL.md` for the decisions behind the current state, and
`docs/specs/` and `docs/plans/` for the design and implementation notes.

## Where the levels actually come from

Read this before touching level content, because the obvious answer is wrong.

Levels are **hardcoded in Dart**, in `lib/data/level_repository.dart`
(`_loadBuiltInLevels`). There are three: a C major scale, a simple melody, and a
mixed rhythm study.

`assets/levels/twinkle_twinkle.json` is not used. Nothing reads it. It is
written in a nested `pitch` and `duration` format that `LevelModel.fromJson`
cannot parse, and the method that would load it, `LevelRepository.loadAll`, is
never called from anywhere. That method also expects `manifest.json` and
`stages.json`, neither of which exists, and it wraps the whole attempt in a
`catch` that discards the error and silently falls back to the hardcoded levels.

So the JSON pipeline is dead in three separate ways at once. Earlier versions of
this README documented that JSON format as if it were the level format, which is
how a wrong assumption about the data model reached a design document. Trust
`lib/models/level_models.dart`.

## Architecture

```text
lib/
├── main.dart                     App entry, theme, landscape lock
├── models/                       Freezed data models and JSON serialisation
│   ├── level_models.dart         LevelNote, LevelMeasure, LevelModel, StageModel
│   ├── audio_models.dart         PitchEvent, AudioEngineConfig
│   └── engine_models.dart        NoteState, StageEvent, StageEngineStateModel
├── data/
│   └── level_repository.dart     Hardcoded levels (see the section above)
├── audio/
│   ├── pitch_detector.dart       YIN fundamental frequency estimator
│   └── audio_engine.dart         Microphone permission and pitch stream
├── engine/
│   └── stage_engine.dart         Pitch matching, scoring, playback state
└── ui/
    ├── theme/
    │   ├── tokens.dart           Colour, spacing, and motion tokens
    │   └── app_theme.dart        Material 3 themes built from the tokens
    ├── staff/
    │   ├── staff_geometry.dart   Clef, and every measurement in staff-spaces
    │   ├── note_glyph.dart       Notehead shapes per note state
    │   ├── staff_painter.dart    One staff system: lines, clef, notes, playhead
    │   ├── staff_view.dart       One or more systems stacked
    │   └── horizontal_staff.dart Legacy scrolling wrapper, replaced in phase 2
    ├── keyboard/
    │   └── piano_keyboard.dart   Legacy 61 key keyboard, replaced in phase 2
    └── game/
        └── game_screen.dart      Legacy practice screen, replaced in phase 2
```

## The data model

A note is a MIDI number and a position in beats. There is no pitch name, no
octave field, and no clef.

```dart
LevelNote(
  midiNote: 60,        // C4
  startBeat: 0,
  durationBeats: 1,
  measureIndex: 0,
  beatIndex: 0,
)
```

`LevelModel` carries `tempo`, `beatsPerMeasure`, `totalMeasures`, its measures,
and a `clefOctave` plus `transpose`. It does not carry a clef. `Clef` is a
rendering concept and lives in `lib/ui/staff/staff_geometry.dart`, because the
renderer is told which clef to draw rather than reading it from the level.

`NoteState` has six values: `upcoming`, `active`, `hitPerfect`, `hitGood`,
`hitOkay`, `missed`. The staff draws the three hit gradations identically.

## How notes are drawn

Every measurement derives from the staff's own height. One staff space is a
quarter of it. Noteheads are one space tall, the time signature is four, stems
are about two. Halving the staff halves everything, which is why a grand staff
needs no separate code path: it is two systems, not a special case.

Note state is carried by shape before colour. Upcoming is a hollow hairline,
the note currently due is filled with a ring, a hit is filled solid, and a miss
is hollow with a slash struck through it. Filled against hollow noteheads is
real notation, and it means the display still works for red-green colour
blindness, which affects roughly one man in twelve.

Clefs are drawn from bundled Bravura, the SMuFL reference font. Unicode clef
codepoints render from whatever font the operating system supplies, land in the
wrong vertical position, and are missing outright on some Android builds.

## Pitch detection

`PitchDetector` implements the YIN estimator: a difference function, cumulative
mean normalisation, the first dip below a 0.1 threshold, parabolic interpolation
for sub-sample accuracy, and an autocorrelation confidence score.

Defaults live in `AudioConfig`: 44.1kHz, a 1024 sample buffer, 80Hz to 2000Hz,
and a 50 cent tolerance, which is a quarter tone.

## Fonts

Three families are bundled under `assets/fonts/`, all free under the OFL.
Cormorant Garamond carries titles, IBM Plex Sans carries body text and every
metric, and Bravura carries music glyphs. Cormorant and Plex are variable fonts
registered with one asset each and no weight entries, so weight is selected
through `fontVariations` on the `wght` axis rather than by file.

They are bundled rather than fetched through `google_fonts` so that golden tests
do not depend on the network and the app works offline from first launch.

## Building and testing

Builds and tests run on a Linux ARM64 VM, not on the development Mac, so no
build artifacts land locally.

```bash
verify-on-vm "<path to this repo>" "flutter test"
verify-on-vm "<path to this repo>" "flutter analyze --no-fatal-infos"
```

55 tests pass. `flutter analyze` reports 75 infos, all pre-existing in the
legacy files.

Golden tests are skipped off Linux. Font rasterisation differs by host and
Flutter's default comparator is byte exact, so the images are generated and
checked on the same platform.

`test/flutter_test_config.dart` loads the three fonts before any test runs.
Without it, Flutter renders text as empty boxes and golden images silently bake
in missing glyphs. An earlier set of goldens passed every test while showing
black rectangles where the clef and time signature belonged.

Regenerating goldens, in this order, because the sync to the VM deletes first:

```bash
verify-on-vm "<repo>" "flutter test --update-goldens"
rsync -a ampere-dev:work/verify/piano-tool/test/ui/staff/goldens/ test/ui/staff/goldens/
verify-on-vm "<repo>" "flutter test"
```

Then look at the images. Twice now, a defect that every test passed was caught
only by opening the PNG.

## Platform notes

Android needs `RECORD_AUDIO` and a minimum SDK of 24. iOS needs
`NSMicrophoneUsageDescription` and iOS 12.

Android build tooling does not ship for Linux ARM64, so the VM can run every
test but cannot currently produce an APK.

## Still to build

The five screens and routing, progress saved with `shared_preferences`, the
engine wrapped in Riverpod so the staff stops rebuilding every frame, the
keyboard reduced to a visualisation, a real state for denied microphone
permission, and making the speed slider work, which needs
`StageEngine.setPlaybackSpeed` implemented first: it is currently a stub that
ignores its argument.
