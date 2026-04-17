// Run with: flutter test test/generate_icon_test.dart
// Generates assets/icon/app_icon.png (1024×1024)
// Then run:  dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate app icon', () async {
    const sz = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, sz, sz));

    _drawIcon(canvas, sz);

    final picture = recorder.endRecording();
    final image = await picture.toImage(sz.toInt(), sz.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = Directory('assets/icon');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('assets/icon/app_icon.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('\n✅  Icon saved → assets/icon/app_icon.png\n');
  });
}

// ─────────────────────────────────────────────────────────────────────────────

void _drawIcon(ui.Canvas canvas, double sz) {
  final c = ui.Offset(sz / 2, sz / 2);

  // 1 ── Background: near-black with faint green tint
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, sz, sz),
    ui.Paint()
      ..shader = ui.Gradient.radial(
        c, sz * 0.72,
        [const ui.Color(0xFF0A160E), const ui.Color(0xFF050505)],
        [0.0, 1.0],
      ),
  );

  // 2 ── Outer glow halo
  canvas.drawCircle(
    c, sz * 0.44,
    ui.Paint()
      ..color = const ui.Color(0xFF059669)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 48),
  );

  // 3 ── Emerald badge circle
  canvas.drawCircle(
    c, sz * 0.44,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        c - ui.Offset(sz * 0.06, sz * 0.08), sz * 0.44,
        [
          const ui.Color(0xFF05B076),
          const ui.Color(0xFF059669),
          const ui.Color(0xFF047857),
          const ui.Color(0xFF034E2A),
        ],
        [0.0, 0.35, 0.70, 1.0],
      ),
  );

  // 4 ── Badge inner ring highlight
  canvas.drawCircle(
    c, sz * 0.44,
    ui.Paint()
      ..color = const ui.Color(0x2AFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = sz * 0.007,
  );

  // ── Football ──────────────────────────────────────────────────────────────
  const ballOffsetY = -0.025; // slightly above badge centre
  final ballCenter = c + ui.Offset(0, sz * ballOffsetY);
  final ballR = sz * 0.265;

  // 5 ── Ball drop shadow
  canvas.drawCircle(
    ballCenter + ui.Offset(sz * 0.008, sz * 0.014),
    ballR,
    ui.Paint()
      ..color = const ui.Color(0x66000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 28),
  );

  // 6 ── Ball fill (sphere shading)
  canvas.drawCircle(
    ballCenter, ballR,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ballCenter - ui.Offset(ballR * 0.28, ballR * 0.30), ballR * 1.1,
        [
          const ui.Color(0xFFFFFFFF),
          const ui.Color(0xFFF0F0F0),
          const ui.Color(0xFFD8D8D8),
        ],
        [0.0, 0.55, 1.0],
      ),
  );

  // 7 ── Patches (clipped to ball)
  canvas.save();
  canvas.clipPath(
    ui.Path()..addOval(ui.Rect.fromCircle(center: ballCenter, radius: ballR)),
  );
  _drawPatches(canvas, ballCenter, ballR);
  canvas.restore();

  // 8 ── Ball edge ring
  canvas.drawCircle(
    ballCenter, ballR,
    ui.Paint()
      ..color = const ui.Color(0x22000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = sz * 0.004,
  );

  // 9 ── "PA" wordmark below ball
  _drawWordmark(canvas, c, sz);
}

// ─── Football patch pattern ───────────────────────────────────────────────────
//  Classic: 1 central pentagon + 5 surrounding, each separated by hexagonal gaps.

void _drawPatches(ui.Canvas canvas, ui.Offset ballCenter, double ballR) {
  final patchPaint = ui.Paint()..color = const ui.Color(0xFF1A1A2E);

  // Central pentagon (tip pointing up)
  final centralCr = ballR * 0.200;
  canvas.drawPath(
    _pentagon(ballCenter.dx, ballCenter.dy - ballR * 0.045,
        centralCr, -pi / 2),
    patchPaint,
  );

  // 5 surrounding pentagons
  final dist = ballR * 0.540;
  final surroundCr = ballR * 0.188;
  for (int i = 0; i < 5; i++) {
    final angle = -pi / 2 + i * 2 * pi / 5;
    final px = ballCenter.dx + dist * cos(angle);
    final py = ballCenter.dy - ballR * 0.045 + dist * sin(angle);
    // rotate each patch so a flat edge faces the central pentagon
    canvas.drawPath(
      _pentagon(px, py, surroundCr, angle + pi / 5),
      patchPaint,
    );
  }
}

ui.Path _pentagon(double cx, double cy, double r, double rotation) {
  final path = ui.Path();
  for (int i = 0; i < 5; i++) {
    final a = rotation + i * 2 * pi / 5;
    final x = cx + r * cos(a);
    final y = cy + r * sin(a);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

// ─── "PA" text monogram ───────────────────────────────────────────────────────

void _drawWordmark(ui.Canvas canvas, ui.Offset center, double sz) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: sz * 0.068,
      fontWeight: ui.FontWeight.w900,
    ),
  )
    ..pushStyle(ui.TextStyle(
      color: const ui.Color(0xCCFFFFFF),
      letterSpacing: sz * 0.012,
    ))
    ..addText('PLAY ACADEMY');

  final para = builder.build()
    ..layout(ui.ParagraphConstraints(width: sz * 0.9));

  canvas.drawParagraph(
    para,
    ui.Offset(center.dx - sz * 0.45, center.dy + sz * 0.32),
  );
}
