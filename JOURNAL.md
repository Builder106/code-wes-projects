# Journal

A dated log of decisions and the reasoning behind them, especially the ones that
are not obvious from the code.

## 2026-08-17: UI revamp, phase 1 (visual foundation)

Branch `ui-revamp-foundation`, 13 commits. Spec in
`docs/specs/2026-08-17-ui-revamp-design.md`, plan in
`docs/plans/2026-08-17-ui-revamp-foundation.md`.

Delivered a token layer, a Material 3 theme, three bundled fonts, staff geometry
in staff-space units, a rewritten staff painter, a `StaffView`, and three golden
images. The tests went from 7 passing with 1 failing to 55 passing with none,
and `flutter analyze` dropped from 83 infos to 75.

### Why the app looked broken

The single screen was laid out for a wide desktop window and was running
portrait on a phone. The transport row hard-coded a 100px slider and a 200px
progress bar inside a `Row` with two `Spacer`s, which overflowed a 1080px screen
by 211px. Three `AppBar` actions squeezed the title to `"C ..."`. Sixty-one keys
at a fixed 24px needed 1464px. A 70/30 flex split gave the staff a thousand
pixels of column for four hundred of content.

### Decisions worth remembering

**The README does not describe this codebase.** It documents a level format with
a nested `pitch` object and a `clef` field. The real `LevelNote` uses a flat
`midiNote` int, and there is no clef type anywhere in `lib/`. `LevelModel`
carries `clefOctave` and `transpose` instead. The spec was written partly from
the README and inherited the error, which surfaced only when a task tried to
import `Clef`. Read the models, not the README. The README still needs fixing.

**`Clef` is a UI-layer concept, for now.** Defined in
`lib/ui/staff/staff_geometry.dart` because the models have no clef. `StaffView`
takes a list of systems, each naming its own clef, so the caller decides whether
to draw one staff or two. Moving it into the level format belongs with the
practice screen that would read it.

**`NoteState` has six values, not four.** `upcoming, active, hitPerfect,
hitGood, hitOkay, missed`. All three hit gradations render as the same filled
notehead. Encoding hit quality visually is a scoring-feedback decision nobody has
made yet, and inventing one during a layout fix would have been scope creep.

**Note state is a shape before it is a colour.** Filled, hollow, ringed, or
struck through. The previous build distinguished hit from missed only by green
against red, which is invisible to red-green colour blindness. Filled against
hollow noteheads is real notation, so the fix costs nothing and reads as more
musical rather than less.

**Fonts are bundled, not fetched.** `google_fonts` was removed. Runtime fetching
made golden tests depend on the network and left the app with no offline
guarantee. Cormorant Garamond and IBM Plex Sans are variable fonts registered
with one asset each and no `weight:` keys, so weight is driven by
`fontVariations` on the `wght` axis. An earlier attempt registered the same
variable font under five static-looking filenames, which meant every weight
resolved to identical bytes and there was no weight contrast at all.

**Clefs come from Bravura.** Unicode `U+1D11E` and `U+1D122` render from
whatever font the OS supplies, land in the wrong vertical position, and are
missing entirely on some Android builds. Bravura is the SMuFL reference font and
is free under the OFL. This is what the empty `assets/fonts/` entry in
`pubspec.yaml` had always been declared for.

**Everything on the staff is sized in staff-spaces.** One space is a quarter of
the staff height. Noteheads are one space, the time signature is four, stems are
about two. This is what makes a grand staff free: halve the band and every glyph
scales with it, with no second code path.

**`test/flutter_test_config.dart` is load-bearing.** Flutter test harnesses do
not load fonts declared in `pubspec.yaml`. Without that file, text renders as
tofu boxes and the golden images bake missing glyphs in as expected output. The
first set of goldens passed 51 of 51 tests while showing black rectangles where
the clef and time signature belong.

**Golden tests are skipped off Linux.** Font rasterisation differs by host and
the default comparator is byte-exact, so the images are generated and verified
on the Linux VM. The two non-golden layout tests still run everywhere.

### The bug that came back

The original overflow was a content-derived size combined with a fixed offset.
The rewritten painter reintroduced exactly that shape: the clef and time
signature were sized in staff-spaces, which scale with staff height, while notes
started at a fixed `leadingBeats * pixelsPerBeat`. The two agreed on a short
staff and collided on a tall one, putting the time signature on top of the first
two notes. `leadingBeats` is gone and the note origin now derives from the
header width, so there is only one way to express the offset.

### What the tests did not catch

Both visual defects in the golden images, the tofu glyphs and the collision,
passed every test. A golden that captures a broken rendering locks the defect in
as expected output, so every later run confirms the bug rather than finding it.
Look at the images.

### Deliberately left for phase 2

The five screens and routing, `ProgressRepository` on `shared_preferences`, the
Riverpod wrapping of `StageEngine`, the practice-screen layout with its 60dp
control column, the keyboard rewrite as visualization only, the
microphone-permission state, wiring the speed slider to
`StageEngine.setPlaybackSpeed`, and giving Stop and Replay distinct behaviour.

Correction to an earlier note above: `setPlaybackSpeed` does not work and never
did. Its body is two comments, it ignores its argument, and `_config` is final,
so the playback tick reads a speed that is permanently 1.0. Making the slider
work needs a small engine change, not just a UI connection.

Also carried forward: the brace on the grand staff, which is unreachable until
the level format carries a second staff; time-signature digits drawn in Cormorant
rather than Bravura's own glyphs; and `lib/ui/game/game_screen.dart`, which is
still the pre-revamp screen and is replaced wholesale in phase 2.
