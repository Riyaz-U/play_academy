import 'dart:math';
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ── Full-screen loading screen ───────────────────────────────────────────────
class WhistleLoading extends StatelessWidget {
  final String? label;
  const WhistleLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 260, height: 170, child: WhistleAnimation()),
            const SizedBox(height: 24),
            Text(
              label ?? 'LOADING...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 5,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated widget ──────────────────────────────────────────────────────────
class WhistleAnimation extends StatefulWidget {
  const WhistleAnimation({super.key});

  @override
  State<WhistleAnimation> createState() => _WhistleAnimationState();
}

class _WhistleAnimationState extends State<WhistleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(painter: _WhistlePainter(_ctrl.value)),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
//
//  Virtual canvas: 520 × 340
//
//  Body:        circle  centre=(200,200)  r=115
//  Mouthpiece:  exits body at −40° (upper-right), half-width=20, length=130
//  Top junction on body:    (275, 111)  → body angle ≈ −49.8°
//  Bottom junction on body: (301, 141)  → body angle ≈ −30.3°
//  Tip centre:              (388,  42)  r=20 (semi-circle cap)
//  Inner hollow:            circle  centre=(200,200)  r=70
//  Lanyard ring:            circle  centre=(105, 295)  r=16
//
class _WhistlePainter extends CustomPainter {
  final double progress;
  const _WhistlePainter(this.progress);

  static const double _vw = 520;
  static const double _vh = 340;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _vw, size.height / _vh);

    final outer = _outerSilhouette();
    final inner = _innerCircle();
    final ring  = _lanyardRing();

    // ── Ghost: full outline at low opacity ───────────────────────────────────
    final ghost = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outer, ghost);
    canvas.drawPath(inner, ghost);
    canvas.drawPath(ring,  ghost);
    _drawSoundLines(canvas, ghost);

    // ── Travelling segment along the outer silhouette ────────────────────────
    final metric   = outer.computeMetrics().first;
    final totalLen = metric.length;
    final segLen   = totalLen * 0.16;   // bright segment = 16 % of outline

    final head = progress * totalLen;
    final tail = (head - segLen + totalLen) % totalLen;

    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bright = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    _drawSegment(canvas, metric, totalLen, tail, head, glow);
    _drawSegment(canvas, metric, totalLen, tail, head, bright);
  }

  void _drawSegment(
    Canvas canvas,
    PathMetric m,
    double total,
    double tail,
    double head,
    Paint paint,
  ) {
    if (head >= tail) {
      canvas.drawPath(m.extractPath(tail, head), paint);
    } else {
      // segment wraps past the end back to the start
      canvas.drawPath(m.extractPath(tail, total), paint);
      if (head > 0) canvas.drawPath(m.extractPath(0, head), paint);
    }
  }

  // ── Outer silhouette ──────────────────────────────────────────────────────
  //
  //  Traced as one continuous closed path:
  //    top junction (275,111)
  //    → top mouthpiece wall → rounded tip arc → bottom mouthpiece wall
  //    → bottom junction (301,141)
  //    → large body arc (clockwise, 340.5°) back to top junction
  //
  Path _outerSilhouette() {
    return Path()
      // top body-mouthpiece junction
      ..moveTo(275, 111)
      // top wall of mouthpiece
      ..lineTo(375, 27)
      // rounded tip: semi-circle r=20 at (388,42)
      //   start angle: atan2(27−42, 375−388) = atan2(−15,−13) ≈ −2.285 rad
      //   sweep: π  (180° clockwise)
      ..arcTo(
        Rect.fromCircle(center: const Offset(388, 42), radius: 20),
        -2.285, pi, false,
      )
      // bottom wall back to body  (ends at body junction 301,141)
      ..lineTo(301, 141)
      // large body arc: clockwise 340.5° from −30.3° back to −49.8°
      //   start: atan2(141−200, 301−200) = atan2(−59,101) ≈ −0.529 rad
      //   sweep: 5.942 rad  (≈ 340.5°)
      ..arcTo(
        Rect.fromCircle(center: const Offset(200, 200), radius: 115),
        -0.529, 5.942, false,
      )
      ..close();
  }

  // ── Inner hollow circle ───────────────────────────────────────────────────
  Path _innerCircle() => Path()
    ..addOval(Rect.fromCircle(
        center: const Offset(200, 200), radius: 70));

  // ── Lanyard ring ──────────────────────────────────────────────────────────
  Path _lanyardRing() => Path()
    ..addOval(Rect.fromCircle(
        center: const Offset(105, 295), radius: 16));

  // ── Sound-burst lines near top junction ───────────────────────────────────
  void _drawSoundLines(Canvas canvas, Paint paint) {
    for (final pts in [
      [256, 98, 238, 76],
      [264, 90, 256, 66],
      [273, 85, 270, 61],
    ]) {
      canvas.drawLine(
        Offset(pts[0].toDouble(), pts[1].toDouble()),
        Offset(pts[2].toDouble(), pts[3].toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WhistlePainter old) => old.progress != progress;
}
