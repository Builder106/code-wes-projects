import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/level_models.dart';
import '../../models/engine_models.dart';
import '../theme/app_theme.dart';
import 'staff_geometry.dart';
import 'staff_painter.dart';

/// Horizontal scrolling sheet music staff widget
class HorizontalStaff extends StatefulWidget {
  final LevelModel level;
  final List<LevelNote> allNotes;
  final List<NoteState> noteStates;
  final double currentBeat;
  final double pixelsPerBeat;
  final VoidCallback? onTap;
  final Function(double beat)? onSeek;

  const HorizontalStaff({
    super.key,
    required this.level,
    required this.allNotes,
    required this.noteStates,
    required this.currentBeat,
    required this.pixelsPerBeat,
    this.onTap,
    this.onSeek,
  });

  @override
  State<HorizontalStaff> createState() => _HorizontalStaffState();
}

class _HorizontalStaffState extends State<HorizontalStaff>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _targetScrollOffset = 0.0;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animationController.addListener(_onAnimationTick);
  }

  @override
  void didUpdateWidget(covariant HorizontalStaff oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to follow playhead when not user scrolling
    if (!_isUserScrolling && widget.currentBeat != oldWidget.currentBeat) {
      _scrollToBeat(widget.currentBeat, animate: true);
    }
  }

  void _onAnimationTick() {
    if (!_isUserScrolling) {
      _scrollController.jumpTo(_targetScrollOffset);
    }
  }

  void _scrollToBeat(double beat, {bool animate = false}) {
    final targetOffset = beat * widget.pixelsPerBeat - _getCenterOffset();
    _targetScrollOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate && mounted) {
      _animationController.forward(from: 0.0);
    } else {
      _scrollController.jumpTo(_targetScrollOffset);
    }
  }

  double _getCenterOffset() {
    // Center the playhead at 30% from left
    return MediaQuery.of(context).size.width * 0.3;
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffHeight = 250.0;
    // Mirrors StaffPainter.paint: the staff occupies the middle 56% of the
    // band, leaving room above and below for ledger lines. The two must
    // stay in sync, since this is how the header width lines up with what
    // the painter actually draws.
    final staffBandHeight = staffHeight * 0.56;
    final geometry = StaffGeometry(
      top: (staffHeight - staffBandHeight) / 2,
      height: staffBandHeight,
    );
    final headerWidth = StaffPainter.headerWidthFor(geometry);
    final totalWidth = headerWidth +
        widget.level.totalMeasures * widget.level.beatsPerMeasure * widget.pixelsPerBeat;

    return GestureDetector(
      onHorizontalDragStart: (_) => _isUserScrolling = true,
      onHorizontalDragEnd: (_) => _isUserScrolling = false,
      onHorizontalDragUpdate: (details) {
        if (_isUserScrolling) {
          _scrollController.jumpTo(
            (_scrollController.offset - details.primaryDelta!).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
          );
        }
      },
      onTapDown: (details) {
        if (widget.onSeek != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final beat = (localPosition.dx + _scrollController.offset - headerWidth) /
                widget.pixelsPerBeat;
            widget.onSeek!(beat);
          }
        }
        widget.onTap?.call();
      },
      child: Container(
        height: staffHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: math.max(totalWidth, MediaQuery.of(context).size.width),
            height: staffHeight,
            child: CustomPaint(
              size: Size(totalWidth, staffHeight),
              painter: StaffPainter(
                clef: Clef.treble,
                notes: [
                  for (var i = 0; i < widget.allNotes.length; i++)
                    if (!widget.allNotes[i].isRest)
                      (
                        midi: widget.allNotes[i].midiNote,
                        startBeat: widget.allNotes[i].startBeat,
                        state: i < widget.noteStates.length
                            ? widget.noteStates[i]
                            : NoteState.upcoming,
                      ),
                ],
                colors: PianoTheme.colorsOf(context),
                currentBeat: widget.currentBeat,
                totalBeats: (widget.level.totalMeasures * widget.level.beatsPerMeasure)
                    .toDouble(),
                beatsPerMeasure: widget.level.beatsPerMeasure,
                pixelsPerBeat: widget.pixelsPerBeat,
              ),
            ),
          ),
        ),
      ),
    );
  }
}