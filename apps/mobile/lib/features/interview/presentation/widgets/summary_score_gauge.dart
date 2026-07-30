import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Radial arc gauge displaying the overall interview score.
///
/// Renders a circular track with a gradient-filled arc proportional to the
/// score, a centered score number, and a qualitative label beneath.
/// Animates the arc sweep on first build.
class SummaryScoreGauge extends StatefulWidget {
  const SummaryScoreGauge({
    required this.score,
    super.key,
    this.maxScore = 5.0,
    this.size = 120.0,
  });

  /// The score to display (e.g. 4.2).
  final double score;

  /// The maximum possible score.
  final double maxScore;

  /// Diameter of the gauge.
  final double size;

  @override
  State<SummaryScoreGauge> createState() => _SummaryScoreGaugeState();
}

class _SummaryScoreGaugeState extends State<SummaryScoreGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final fraction = (widget.score / widget.maxScore).clamp(0.0, 1.0);
    _sweepAnimation = Tween<double>(begin: 0, end: fraction).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sweepAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ScoreArcPainter(
              fraction: _sweepAnimation.value,
              trackColor: VoiceMockColors.scoreGaugeTrack,
              gradientStart: VoiceMockColors.gradientStart,
              gradientEnd: VoiceMockColors.gradientEnd,
            ),
            child: child,
          );
        },
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.score.toStringAsFixed(1),
                  style: VoiceMockTypography.scoreDisplay,
                ),
                const SizedBox(width: 2),
                Text(
                  '/ ${widget.maxScore.toInt()}',
                  style: VoiceMockTypography.micro.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  _ScoreArcPainter({
    required this.fraction,
    required this.trackColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final double fraction;
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;

  static const double _strokeWidth = 8;
  static const double _startAngle = -math.pi * 0.75; // 7:30 position
  static const double _totalSweep = math.pi * 1.5; // 270° arc

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _totalSweep, false, trackPaint);

    // Filled arc
    if (fraction > 0) {
      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _totalSweep,
          colors: [gradientStart, gradientEnd],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        _startAngle,
        _totalSweep * fraction,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) =>
      fraction != oldDelegate.fraction;
}
