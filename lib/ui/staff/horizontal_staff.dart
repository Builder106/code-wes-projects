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
    final totalWidth = widget.level.totalMeasures * widget.level.beatsPerMeasure * widget.pixelsPerBeat;
    final staffHeight = 250.0;

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
            final beat = (localPosition.dx + _scrollController.offset) / widget.pixelsPerBeat;
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

/// Animated playhead overlay that moves smoothly
class AnimatedPlayhead extends StatefulWidget {
  final double currentBeat;
  final double pixelsPerBeat;
  final double staffHeight;
  final ScrollController scrollController;

  const AnimatedPlayhead({
    super.key,
    required this.currentBeat,
    required this.pixelsPerBeat,
    required this.staffHeight,
    required this.scrollController,
  });

  @override
  State<AnimatedPlayhead> createState() => _AnimatedPlayheadState();
}

class _AnimatedPlayheadState extends State<AnimatedPlayhead>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousBeat = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _previousBeat = widget.currentBeat;
  }

  @override
  void didUpdateWidget(covariant AnimatedPlayhead oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentBeat != oldWidget.currentBeat) {
      _previousBeat = oldWidget.currentBeat;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final interpolatedBeat = _previousBeat +
            (widget.currentBeat - _previousBeat) * _animation.value;
        final x = interpolatedBeat * widget.pixelsPerBeat - widget.scrollController.offset;

        if (x < 0 || x > MediaQuery.of(context).size.width) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: x,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _PlayheadPainter(
              color: Theme.of(context).colorScheme.error,
            ),
            size: const Size(4, double.infinity),
          ),
        );
      },
    );
  }
}

class _PlayheadPainter extends CustomPainter {
  final Color color;

  _PlayheadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Main line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Triangle at top
    final trianglePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final trianglePath = Path();
    trianglePath.moveTo(size.width / 2, -8);
    trianglePath.lineTo(size.width / 2 - 8, 0);
    trianglePath.lineTo(size.width / 2 + 8, 0);
    trianglePath.close();

    canvas.drawPath(trianglePath, trianglePaint);

    // Triangle at bottom
    final bottomTrianglePath = Path();
    bottomTrianglePath.moveTo(size.width / 2, size.height + 8);
    bottomTrianglePath.lineTo(size.width / 2 - 8, size.height);
    bottomTrianglePath.lineTo(size.width / 2 + 8, size.height);
    bottomTrianglePath.close();

    canvas.drawPath(bottomTrianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant _PlayheadPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}