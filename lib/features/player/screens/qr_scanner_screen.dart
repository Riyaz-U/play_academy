import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _fs = FirestoreService();
  final _controller = MobileScannerController();

  bool _processing = false;
  _ScanResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _result != null) return;
    final barcode = capture.barcodes.firstOrNull;
    final token = barcode?.rawValue;
    if (token == null || token.isEmpty) return;

    // Capture before async gap
    final user = context.read<AuthProvider>().userModel;

    setState(() => _processing = true);
    await _controller.stop();
    if (user == null) {
      _setResult(_ScanResult.error('Not logged in.'));
      return;
    }

    try {
      final qrSession = await _fs.getQrSessionByToken(token);

      if (qrSession == null) {
        _setResult(_ScanResult.error('QR code is invalid or has expired.'));
        return;
      }
      if (!qrSession.isValid) {
        _setResult(_ScanResult.error(
            qrSession.isExpired ? 'This QR code has expired.' : 'QR code is no longer active.'));
        return;
      }

      // Mark attendance
      await _fs.saveAttendance({
        'sessionId': qrSession.sessionId,
        'playerId': user.uid,
        'playerName': user.name,
        'status': AppConstants.attendancePresent,
        'markedBy': user.uid,
        'markedByName': user.name,
        'markedAt': Timestamp.fromDate(DateTime.now()),
        'organizationId': user.organizationId,
        'branchId': user.branchId ?? qrSession.branchId,
        'markedVia': 'qr',
      });

      _setResult(_ScanResult.success('You\'re checked in! Attendance marked as Present.'));
    } catch (e) {
      _setResult(_ScanResult.error('Something went wrong. Please try again.'));
    }
  }

  void _setResult(_ScanResult result) {
    if (mounted) setState(() { _result = result; _processing = false; });
  }

  void _reset() {
    setState(() => _result = null);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: _result != null
          ? _ResultView(result: _result!, onRetry: _reset)
          : _ScannerView(
              controller: _controller,
              processing: _processing,
              onDetect: _onDetect,
            ),
    );
  }
}

// ── Scanner View ─────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final bool processing;
  final void Function(BarcodeCapture) onDetect;

  const _ScannerView({
    required this.controller,
    required this.processing,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(controller: controller, onDetect: onDetect),

        // Overlay with cutout
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),

        // Instructions
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (processing)
                const CircularProgressIndicator(color: AppTheme.primaryGreen)
              else ...[
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white70, size: 28),
                const SizedBox(height: 10),
                const Text(
                  'Point your camera at the\nQR code shown by your coach',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Corner frame
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(painter: _CornerFramePainter()),
          ),
        ),
      ],
    );
  }
}

// ── Result View ──────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final _ScanResult result;
  final VoidCallback onRetry;

  const _ResultView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.isSuccess;
    final color = isSuccess ? AppTheme.successGreen : AppTheme.errorRed;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(icon, size: 96, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            isSuccess ? 'Checked In!' : 'Check-In Failed',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (isSuccess)
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Dashboard'),
            )
          else
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            ),
        ],
      ),
    );
  }
}

// ── Scan Result model ────────────────────────────────────

class _ScanResult {
  final bool isSuccess;
  final String message;
  const _ScanResult._({required this.isSuccess, required this.message});
  factory _ScanResult.success(String msg) =>
      _ScanResult._(isSuccess: true, message: msg);
  factory _ScanResult.error(String msg) =>
      _ScanResult._(isSuccess: false, message: msg);
}

// ── Overlay painters ─────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    const cutSize = 240.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: cutSize, height: cutSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r = 12.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(r, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w - r, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h - r), paint);
    canvas.drawLine(Offset(r, h), Offset(len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - len, h), Offset(w - r, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h - r), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
