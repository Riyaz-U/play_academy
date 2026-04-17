import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/session_card.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final sessions = context.watch<SessionProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final payments = context.watch<PaymentProvider>();

    final now = DateTime.now();
    final nextSession = sessions.upcomingSessions.isNotEmpty
        ? sessions.upcomingSessions.first
        : null;

    // Find the most recent completed session with highlights
    final recentHighlights = sessions.sessions
        .where((s) =>
            s.isCompleted &&
            s.highlights != null &&
            s.highlights!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final highlightSession =
        recentHighlights.isNotEmpty ? recentHighlights.first : null;

    final hasPendingPayment = payments.pendingPayments.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Academy'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.darkGreen,
                    Color(0xFF022C22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM').format(now),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _StatPill(
                        label:
                            '${attendance.attendancePercentage.toStringAsFixed(0)}%',
                        suffix: 'attendance',
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: attendance.averageRating > 0
                            ? attendance.averageRating.toStringAsFixed(1)
                            : 'N/A',
                        suffix: 'avg rating',
                        icon: Icons.star_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending payment alert
            if (hasPendingPayment)
              _AlertBanner(
                icon: Icons.payment_outlined,
                message:
                    '${payments.pendingPayments.length} payment${payments.pendingPayments.length > 1 ? 's' : ''} pending',
                actionLabel: 'Pay Now',
                color: AppTheme.warningOrange,
                onAction: () => context.go('/player/payments'),
              ),

            // Next session
            const Text(
              'Next Session',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            if (nextSession == null)
              _EmptyCard(
                icon: Icons.calendar_today_outlined,
                message: 'No upcoming sessions',
              )
            else
              SessionCard(session: nextSession),
            const SizedBox(height: 20),

            // Recent highlights
            const Text(
              'Recent Highlights',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            if (highlightSession == null)
              _EmptyCard(
                icon: Icons.highlight_outlined,
                message: 'No highlights yet',
              )
            else
              _HighlightCard(session: highlightSession),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String suffix;
  final IconData icon;
  const _StatPill(
      {required this.label, required this.suffix, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label $suffix',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final Color color;
  final VoidCallback onAction;

  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.color,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textSubtle),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final dynamic session;
  const _HighlightCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star,
                        size: 12, color: AppTheme.accentAmber),
                    const SizedBox(width: 3),
                    Text(
                      session.isMatch ? 'Match' : 'Training',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('d MMM').format(session.dateTime),
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            session.highlights ?? '',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textGrey, height: 1.4),
          ),
        ],
      ),
    );
  }
}
