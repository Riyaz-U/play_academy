import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/attendance_model.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../services/firestore_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String sessionId;
  const QrGeneratorScreen({super.key, required this.sessionId});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _fs = FirestoreService();
  final _uuid = const Uuid();

  String? _qrDocId;
  String? _token;
  bool _active = false;
  bool _generating = false;

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  StreamSubscription<List<AttendanceModel>>? _attendanceSub;
  int _scannedCount = 0;

  @override
  void initState() {
    super.initState();
    _attendanceSub = _fs
        .streamSessionAttendance(widget.sessionId)
        .listen((list) {
      if (mounted) setState(() => _scannedCount = list.where((a) => a.attended).length);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _attendanceSub?.cancel();
    if (_qrDocId != null && _active) _fs.deactivateQrSession(_qrDocId!);
    super.dispose();
  }

  Future<void> _generate(int expiryMinutes) async {
    // Capture before async gap
    final auth = context.read<AuthProvider>().userModel!;
    final session = context.read<SessionProvider>().getById(widget.sessionId);

    setState(() => _generating = true);
    if (_qrDocId != null) await _fs.deactivateQrSession(_qrDocId!);
    final token = _uuid.v4();
    final now = DateTime.now();
    final expiry = now.add(Duration(minutes: expiryMinutes));

    final id = await _fs.createQrSession({
      'sessionId': widget.sessionId,
      'branchId': auth.branchId ?? '',
      'organizationId': auth.organizationId,
      'token': token,
      'createdBy': auth.uid,
      'createdByName': auth.name,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiry),
      'isActive': true,
      if (session != null) 'sessionTitle': session.title,
    });

    setState(() {
      _qrDocId = id;
      _token = token;
      _active = true;
      _generating = false;
      _remaining = expiry.difference(DateTime.now());
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = expiry.difference(DateTime.now());
      if (rem.isNegative) {
        _countdownTimer?.cancel();
        if (mounted) setState(() { _remaining = Duration.zero; _active = false; });
        _fs.deactivateQrSession(id);
      } else {
        if (mounted) setState(() => _remaining = rem);
      }
    });
  }

  Future<void> _deactivate() async {
    _countdownTimer?.cancel();
    if (_qrDocId != null) await _fs.deactivateQrSession(_qrDocId!);
    setState(() { _active = false; _token = null; _remaining = Duration.zero; });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>().getById(widget.sessionId);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (session != null) _SessionBanner(session: session),
            const SizedBox(height: 20),
            _active && _token != null
                ? _ActiveQrCard(
                    token: _token!,
                    remaining: _remaining,
                    scannedCount: _scannedCount,
                    onDeactivate: _deactivate,
                  )
                : _GenerateCard(
                    generating: _generating,
                    onGenerate: _generate,
                  ),
            const SizedBox(height: 24),
            const _HowItWorksCard(),
          ],
        ),
      ),
    );
  }
}

// ── Session Banner ───────────────────────────────────────

class _SessionBanner extends StatelessWidget {
  final SessionModel session;
  const _SessionBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                if (session.category != null)
                  Text(session.category!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generate Card ────────────────────────────────────────

class _GenerateCard extends StatefulWidget {
  final bool generating;
  final Future<void> Function(int minutes) onGenerate;
  const _GenerateCard({required this.generating, required this.onGenerate});

  @override
  State<_GenerateCard> createState() => _GenerateCardState();
}

class _GenerateCardState extends State<_GenerateCard> {
  int _minutes = 15;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_2,
              size: 80, color: AppTheme.textSubtle.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          const Text('Generate QR Code',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Players scan this code to check in automatically.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Expires after:',
                style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 30].map((m) {
              final sel = _minutes == m;
              return ChoiceChip(
                label: Text('${m}m'),
                selected: sel,
                onSelected: (_) => setState(() => _minutes = m),
                selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                    color: sel ? AppTheme.primaryGreen : AppTheme.textGrey,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.generating ? null : () => widget.onGenerate(_minutes),
            icon: widget.generating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.qr_code),
            label: const Text('Generate QR Code'),
          ),
        ],
      ),
    );
  }
}

// ── Active QR Card ───────────────────────────────────────

class _ActiveQrCard extends StatelessWidget {
  final String token;
  final Duration remaining;
  final int scannedCount;
  final VoidCallback onDeactivate;

  const _ActiveQrCard({
    required this.token,
    required this.remaining,
    required this.scannedCount,
    required this.onDeactivate,
  });

  String get _fmtRemaining {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (remaining.inSeconds <= 30) return AppTheme.errorRed;
    if (remaining.inSeconds <= 60) return AppTheme.warningOrange;
    return AppTheme.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Expires in',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  Text(
                    _fmtRemaining,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _timerColor,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Checked in',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  Text(
                    '$scannedCount',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // QR on white background so scanners can read it
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Active — waiting for scans',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onDeactivate,
            icon: const Icon(Icons.stop_circle_outlined,
                color: AppTheme.errorRed, size: 18),
            label: const Text('Deactivate',
                style: TextStyle(color: AppTheme.errorRed)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorRed),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          ),
        ],
      ),
    );
  }
}

// ── How It Works ─────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', 'Generate a QR code for this session.'),
      ('2', 'Show the code on your phone or screen.'),
      ('3', 'Players open the app and tap "Scan QR".'),
      ('4', 'Their attendance is marked automatically.'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontSize: 13)),
          const SizedBox(height: 10),
          ...steps.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(e.$1,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.$2,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textGrey)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
