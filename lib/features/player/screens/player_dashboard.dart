import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../models/attendance_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/session_card.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user        = context.watch<AuthProvider>().userModel;
    final playerData  = context.watch<PlayerProvider>().self;
    final sessions    = context.watch<SessionProvider>();
    final attendance  = context.watch<AttendanceProvider>();
    final payments    = context.watch<PaymentProvider>();

    final now = DateTime.now();
    final nextSession = sessions.upcomingSessions.isNotEmpty
        ? sessions.upcomingSessions.first
        : null;

    final recentHighlights = sessions.sessions
        .where((s) => s.isCompleted && s.highlights != null && s.highlights!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final highlightSession = recentHighlights.isNotEmpty ? recentHighlights.first : null;

    final hasPendingPayment = payments.pendingPayments.isNotEmpty;

    // Last 5 rated attendance records (most recent first)
    final recentPerf = attendance.playerAttendance
        .where((a) => a.rating != null && a.rating! > 0)
        .toList()
      ..sort((a, b) => b.markedAt.compareTo(a.markedAt));
    final recentPerfSlice = recentPerf.take(5).toList();

    // Attendance breakdown
    final total   = attendance.playerAttendance.length;
    final present = attendance.playerAttendance.where((a) => a.status == 'present').length;
    final late    = attendance.playerAttendance.where((a) => a.status == 'late').length;
    final absent  = attendance.playerAttendance.where((a) => a.status == 'absent').length;

    final stats = playerData?.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Academy'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, color: AppTheme.onPrimary, size: 20),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
            // ── Profile card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
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
                          color: AppTheme.onPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppTheme.primaryGreen,
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
                                  color: AppTheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM').format(now),
                              style: TextStyle(
                                  color: AppTheme.onPrimary.withValues(alpha: 0.75),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Jersey number badge
                      if (playerData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.onPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '#${playerData.jerseyNumber}',
                                style: const TextStyle(
                                    color: AppTheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                playerData.position,
                                style: TextStyle(
                                    color: AppTheme.onPrimary.withValues(alpha: 0.8),
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatPill(
                        label:
                            '${attendance.attendancePercentage.toStringAsFixed(0)}%',
                        suffix: 'attendance',
                        icon: Icons.check_circle_outline,
                      ),
                      _StatPill(
                        label: attendance.averageRating > 0
                            ? attendance.averageRating.toStringAsFixed(1)
                            : 'N/A',
                        suffix: 'avg rating',
                        icon: Icons.star_outline,
                      ),
                      if (playerData != null)
                        _StatPill(
                          label: stats!.overall.toStringAsFixed(0),
                          suffix: 'overall',
                          icon: Icons.sports_soccer,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pending payment alert ─────────────────────────────────────
            if (hasPendingPayment)
              _AlertBanner(
                icon: Icons.payment_outlined,
                message:
                    '${payments.pendingPayments.length} payment${payments.pendingPayments.length > 1 ? 's' : ''} pending',
                actionLabel: 'Pay Now',
                color: AppTheme.warningOrange,
                onAction: () => context.go('/player/payments'),
              ),

            // ── Player Stats ──────────────────────────────────────────────
            if (stats != null) ...[
              _SectionHeader(title: 'Player Stats'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.borderDark.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _OverallBadge(overall: stats.overall),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _StatBar(label: 'Pace',       value: stats.pace),
                              _StatBar(label: 'Shooting',   value: stats.shooting),
                              _StatBar(label: 'Passing',    value: stats.passing),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _StatBar(label: 'Dribbling',  value: stats.dribbling),
                              _StatBar(label: 'Defending',  value: stats.defending),
                              _StatBar(label: 'Physical',   value: stats.physical),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Attendance Summary ────────────────────────────────────────
            if (total > 0) ...[
              _SectionHeader(title: 'Attendance Summary'),
              Row(
                children: [
                  Expanded(
                    child: _AttendanceBox(
                      count: present,
                      label: 'Present',
                      color: AppTheme.primaryGreen,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttendanceBox(
                      count: late,
                      label: 'Late',
                      color: AppTheme.accentAmber,
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttendanceBox(
                      count: absent,
                      label: 'Absent',
                      color: AppTheme.errorRed,
                      icon: Icons.cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Recent Performance ────────────────────────────────────────
            if (recentPerfSlice.isNotEmpty) ...[
              _SectionHeader(title: 'Recent Performance'),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.borderDark.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: recentPerfSlice
                      .map((a) => _PerformanceRow(record: a))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Next Session ──────────────────────────────────────────────
            _SectionHeader(title: 'Next Session'),
            if (nextSession == null)
              _EmptyCard(
                icon: Icons.calendar_today_outlined,
                message: 'No upcoming sessions',
              )
            else
              SessionCard(session: nextSession),
            const SizedBox(height: 20),

            // ── Recent Highlights ─────────────────────────────────────────
            _SectionHeader(title: 'Recent Highlights'),
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

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark),
      ),
    );
  }
}

// ── Overall badge (circular) ──────────────────────────────────────────────────
class _OverallBadge extends StatelessWidget {
  final double overall;
  const _OverallBadge({required this.overall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            overall.toStringAsFixed(0),
            style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const Text(
            'OVR',
            style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

// ── Stat bar (label + progress + value) ──────────────────────────────────────
class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  const _StatBar({required this.label, required this.value});

  Color get _barColor {
    if (value >= 75) return AppTheme.primaryGreen;
    if (value >= 50) return AppTheme.accentAmber;
    return AppTheme.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 10)),
              Text('$value',
                  style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 5,
              backgroundColor: AppTheme.borderDark,
              valueColor: AlwaysStoppedAnimation(_barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance summary box ────────────────────────────────────────────────────
class _AttendanceBox extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _AttendanceBox(
      {required this.count,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Recent performance row ────────────────────────────────────────────────────
class _PerformanceRow extends StatelessWidget {
  final AttendanceModel record;
  const _PerformanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(record.markedAt),
                  style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (record.ratingNote != null &&
                    record.ratingNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      record.ratingNote!,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < (record.rating ?? 0) ? Icons.star : Icons.star_border,
                size: 14,
                color: AppTheme.accentAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat pill (profile card) ──────────────────────────────────────────────────
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
        color: AppTheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.onPrimary, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label $suffix',
            style: const TextStyle(color: AppTheme.onPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Alert banner ──────────────────────────────────────────────────────────────
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

// ── Empty state card ──────────────────────────────────────────────────────────
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

// ── Highlight card ────────────────────────────────────────────────────────────
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
                    const Icon(Icons.star, size: 12, color: AppTheme.accentAmber),
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
