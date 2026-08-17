import 'package:flutter/material.dart';
import '../../models/engine_models.dart';

/// Piano keyboard widget with 61 keys (5 octaves from C2)
class PianoKeyboard extends StatefulWidget {
  final int highlightedKey; // MIDI note currently pressed (from touch)
  final int midiHighlightKey; // MIDI note currently detected from audio
  final Set<int> activeNotes; // Notes currently active in the sheet music
  final Map<int, NoteState> noteStates; // State of each note in the level
  final double keyWidth;
  final double whiteKeyHeight;
  final double blackKeyHeightRatio;
  final double blackKeyWidthRatio;
  final Function(int midiNote, bool isDown)? onKeyPressed;

  const PianoKeyboard({
    super.key,
    this.highlightedKey = -1,
    this.midiHighlightKey = -1,
    this.activeNotes = const {},
    this.noteStates = const {},
    this.keyWidth = 24.0,
    this.whiteKeyHeight = 180.0,
    this.blackKeyHeightRatio = 0.6,
    this.blackKeyWidthRatio = 0.6,
    this.onKeyPressed,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  // 61 keys starting from C2 (MIDI 36) to C7 (MIDI 96)
  // 36 white keys and 25 black keys
  static const int _startOctave = 2; // C2
  static const int _octaveCount = 5; // 5 full octaves (C2..B6) + C7

  // Track which keys are currently pressed by touch
  final Set<int> _pressedKeys = {};

  // White key relative offsets in an octave: C, D, E, F, G, A, B
  static const List<int> _whiteKeyOffsets = [0, 2, 4, 5, 7, 9, 11];
  static const List<int> _blackKeyOffsets = [1, 3, 6, 8, 10];

  // Black key definitions: (semitone offset in octave, whiteKeyLeftIndex)
  // C# (1, between C(0) and D(1)), D# (3, between D(1) and E(2)),
  // F# (6, between F(3) and G(4)), G# (8, between G(4) and A(5)), A# (10, between A(5) and B(6))
  static const List<({int semitone, int whiteIndex})> _blackKeyDefs = [
    (semitone: 1, whiteIndex: 1),
    (semitone: 3, whiteIndex: 2),
    (semitone: 6, whiteIndex: 4),
    (semitone: 8, whiteIndex: 5),
    (semitone: 10, whiteIndex: 6),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const totalWhiteKeys = _octaveCount * 7 + 1; // 36 white keys
    final totalWidth = totalWhiteKeys * widget.keyWidth;
    final blackKeyWidth = widget.keyWidth * widget.blackKeyWidthRatio;
    final blackKeyHeight = widget.whiteKeyHeight * widget.blackKeyHeightRatio;

    return Container(
      height: widget.whiteKeyHeight + 20,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          height: widget.whiteKeyHeight,
          child: Stack(
            children: [
              // White keys row
              Row(
                children: List.generate(totalWhiteKeys, (index) {
                  final octave = _startOctave + (index ~/ 7);
                  final noteInOctave = index % 7;
                  final midiNote = (octave == _startOctave + _octaveCount)
                      ? 96 // C7
                      : (octave + 1) * 12 + _whiteKeyOffsets[noteInOctave];

                  final isPressed = _pressedKeys.contains(midiNote) ||
                      widget.highlightedKey == midiNote;
                  final isMidiHighlighted = widget.midiHighlightKey == midiNote;
                  final isActive = widget.activeNotes.contains(midiNote);

                  Color keyColor;
                  if (isMidiHighlighted) {
                    keyColor = isDarkMode ? Colors.lightBlueAccent : Colors.blue[300]!;
                  } else if (isPressed) {
                    keyColor = isDarkMode ? Colors.blue[700]! : Colors.blue[100]!;
                  } else if (isActive) {
                    final noteState = widget.noteStates[midiNote];
                    if (noteState != null) {
                      keyColor = _getNoteStateColor(noteState, isDarkMode);
                    } else {
                      keyColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
                    }
                  } else {
                    keyColor = isDarkMode ? Colors.grey[850]! : Colors.white;
                  }

                  return _WhiteKey(
                    keyWidth: widget.keyWidth,
                    keyHeight: widget.whiteKeyHeight,
                    color: keyColor,
                    isPressed: isPressed || isMidiHighlighted,
                    midiNote: midiNote,
                    label: _getNoteName(midiNote),
                    onPressed: (down) => widget.onKeyPressed?.call(midiNote, down),
                    onTapDown: () => setState(() => _pressedKeys.add(midiNote)),
                    onTapUp: () => setState(() => _pressedKeys.remove(midiNote)),
                    isDarkMode: isDarkMode,
                  );
                }),
              ),

              // Black keys overlays
              ...List.generate(_octaveCount * 5, (index) {
                final octaveIdx = index ~/ 5;
                final def = _blackKeyDefs[index % 5];
                final octave = _startOctave + octaveIdx;
                final midiNote = (octave + 1) * 12 + def.semitone;

                // Center black key on boundary between white keys
                final boundaryX = (octaveIdx * 7 + def.whiteIndex) * widget.keyWidth;
                final posX = boundaryX - (blackKeyWidth / 2);

                final isPressed = _pressedKeys.contains(midiNote) ||
                    widget.highlightedKey == midiNote;
                final isMidiHighlighted = widget.midiHighlightKey == midiNote;
                final isActive = widget.activeNotes.contains(midiNote);

                Color keyColor;
                if (isMidiHighlighted) {
                  keyColor = isDarkMode ? Colors.lightBlueAccent[200]! : Colors.blue[400]!;
                } else if (isPressed) {
                  keyColor = isDarkMode ? Colors.blue[900]! : Colors.blue[200]!;
                } else if (isActive) {
                  final noteState = widget.noteStates[midiNote];
                  if (noteState != null) {
                    keyColor = _getNoteStateColor(noteState, isDarkMode).withValues(alpha: 0.8);
                  } else {
                    keyColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
                  }
                } else {
                  keyColor = isDarkMode ? Colors.grey[900]! : Colors.black87;
                }

                return Positioned(
                  left: posX,
                  top: 0,
                  child: _BlackKey(
                    keyWidth: blackKeyWidth,
                    keyHeight: blackKeyHeight,
                    color: keyColor,
                    isPressed: isPressed || isMidiHighlighted,
                    midiNote: midiNote,
                    label: _getNoteName(midiNote),
                    onPressed: (down) => widget.onKeyPressed?.call(midiNote, down),
                    onTapDown: () => setState(() => _pressedKeys.add(midiNote)),
                    onTapUp: () => setState(() => _pressedKeys.remove(midiNote)),
                    isDarkMode: isDarkMode,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool _isWhiteKey(int midiNote) {
    final octaveNote = midiNote % 12;
    return _whiteKeyOffsets.contains(octaveNote);
  }

  bool _isBlackKey(int midiNote) {
    final octaveNote = midiNote % 12;
    return _blackKeyOffsets.contains(octaveNote);
  }

  String _getNoteName(int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1; // MIDI 60 = C4
    return '${noteNames[midiNote % 12]}$octave';
  }

  Color _getNoteStateColor(NoteState state, bool isDarkMode) {
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
}

/// White key widget
class _WhiteKey extends StatelessWidget {
  final double keyWidth;
  final double keyHeight;
  final Color color;
  final bool isPressed;
  final int midiNote;
  final String label;
  final Function(bool down)? onPressed;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final bool isDarkMode;

  const _WhiteKey({
    required this.keyWidth,
    required this.keyHeight,
    required this.color,
    required this.isPressed,
    required this.midiNote,
    required this.label,
    this.onPressed,
    this.onTapDown,
    this.onTapUp,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        onTapDown?.call();
        onPressed?.call(true);
      },
      onTapUp: (_) {
        onTapUp?.call();
        onPressed?.call(false);
      },
      onTapCancel: () {
        onTapUp?.call();
        onPressed?.call(false);
      },
      child: Container(
        width: keyWidth,
        height: keyHeight,
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
            width: 0.5,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Note label at bottom
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Highlight for middle C
            if (midiNote == 60)
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.redAccent : Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Black key widget
class _BlackKey extends StatelessWidget {
  final double keyWidth;
  final double keyHeight;
  final Color color;
  final bool isPressed;
  final int midiNote;
  final String label;
  final Function(bool down)? onPressed;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final bool isDarkMode;

  const _BlackKey({
    required this.keyWidth,
    required this.keyHeight,
    required this.color,
    required this.isPressed,
    required this.midiNote,
    required this.label,
    this.onPressed,
    this.onTapDown,
    this.onTapUp,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        onTapDown?.call();
        onPressed?.call(true);
      },
      onTapUp: (_) {
        onTapUp?.call();
        onPressed?.call(false);
      },
      onTapCancel: () {
        onTapUp?.call();
        onPressed?.call(false);
      },
      child: Container(
        width: keyWidth,
        height: keyHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
        ),
      ),
    );
  }
}

/// Compact piano keyboard for smaller screens
class CompactPianoKeyboard extends StatelessWidget {
  final int highlightedKey;
  final int midiHighlightKey;
  final Set<int> activeNotes;
  final Map<int, NoteState> noteStates;
  final Function(int midiNote, bool isDown)? onKeyPressed;

  const CompactPianoKeyboard({
    super.key,
    this.highlightedKey = -1,
    this.midiHighlightKey = -1,
    this.activeNotes = const {},
    this.noteStates = const {},
    this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PianoKeyboard(
      highlightedKey: highlightedKey,
      midiHighlightKey: midiHighlightKey,
      activeNotes: activeNotes,
      noteStates: noteStates,
      keyWidth: 16.0,
      whiteKeyHeight: 120.0,
      blackKeyHeightRatio: 0.55,
      blackKeyWidthRatio: 0.55,
      onKeyPressed: onKeyPressed,
    );
  }
}