import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../widgets/session_card.dart';

class CoachDashboard extends StatelessWidget {
  const CoachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final sessions = context.watch<SessionProvider>();
    final players = context.watch<PlayerProvider>().players;
    final dash = context.watch<DashboardProvider>();
    final summary = dash.summary;

    final now = DateTime.now();
    final todaySessions = sessions.upcomingSessions.where((s) =>
        s.dateTime.year == now.year &&
        s.dateTime.month == now.month &&
        s.dateTime.day == now.day).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            // ── Welcome banner ──────────────────────────────
            _WelcomeBanner(
              name: user?.name.split(' ').first ?? 'Coach',
              date: now,
              playerCount: players.length,
              sessionCount: sessions.upcomingSessions.length,
            ),
            const SizedBox(height: 20),

            // ── Metric cards ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.people,
                    label: 'Players',
                    value: '${summary.totalPlayers}',
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.calendar_today,
                    label: 'Upcoming',
                    value: '${summary.upcomingSessions}',
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.check_circle_outline,
                    label: 'Attendance',
                    value:
                        '${(summary.attendanceRate * 100).toStringAsFixed(0)}%',
                    color: _attendanceColor(summary.attendanceRate),
                    subtitle: 'last 30 days',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Pending',
                    value: summary.payments.totalDue > 0
                        ? '₹${_compact(summary.payments.totalDue)}'
                        : '—',
                    color: AppTheme.accentAmber,
                    subtitle: '${summary.payments.pendingCount + summary.payments.overdueCount} unpaid',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Weekly attendance chart ──────────────────────
            if (summary.weeklyAttendance.isNotEmpty) ...[
              _SectionHeader(
                  title: 'Weekly Attendance',
                  action: null),
              const SizedBox(height: 12),
              _AttendanceBarChart(data: summary.weeklyAttendance),
              const SizedBox(height: 24),
            ],

            // ── Payment breakdown ────────────────────────────
            if (summary.payments.totalCount > 0) ...[
              const _SectionHeader(title: 'Payments', action: null),
              const SizedBox(height: 12),
              _PaymentBreakdown(payments: summary.payments),
              const SizedBox(height: 24),
            ],

            // ── Today's sessions ─────────────────────────────
            if (todaySessions.isNotEmpty) ...[
              const _SectionHeader(title: "Today's Sessions", action: null),
              const SizedBox(height: 12),
              ...todaySessions.map((s) => SessionCard(
                    session: s,
                    actions: [
                      TextButton.icon(
                        onPressed: () => context
                            .push('/coach/sessions/${s.id}/attendance'),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Mark Attendance'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
            ],

            // ── Upcoming sessions ────────────────────────────
            _SectionHeader(
              title: 'Upcoming Sessions',
              action: TextButton(
                onPressed: () => context.go('/coach/sessions'),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 8),
            if (sessions.upcomingSessions.isEmpty)
              _EmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'No upcoming sessions',
                actionLabel: 'Schedule Session',
                onAction: () => context.push('/coach/sessions/add'),
              )
            else
              ...sessions.upcomingSessions.take(3).map((s) => SessionCard(
                    session: s,
                    onTap: () =>
                        context.push('/coach/sessions/${s.id}/attendance'),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coach/sessions/add'),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _attendanceColor(double rate) {
    if (rate >= 0.75) return AppTheme.successGreen;
    if (rate >= 0.5) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  String _compact(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

// ── Welcome Banner ───────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final DateTime date;
  final int playerCount;
  final int sessionCount;

  const _WelcomeBanner({
    required this.name,
    required this.date,
    required this.playerCount,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen, Color(0xFF022C22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, Coach $name',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(date),
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Pill(icon: Icons.people, label: '$playerCount players'),
              const SizedBox(width: 10),
              _Pill(
                  icon: Icons.upcoming_outlined,
                  label: '$sessionCount upcoming'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Metric Card ──────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textGrey)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSubtle)),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        if (action != null) action!,
      ],
    );
  }
}

// ── Attendance Bar Chart ─────────────────────────────────

class _AttendanceBarChart extends StatelessWidget {
  final List<AttendanceTrend> data;
  const _AttendanceBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(
        0, (m, t) => t.total > m ? t.total.toDouble() : m);
    final chartMax = (maxY < 4 ? 4 : maxY + 2).ceilToDouble();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final day = data[group.x];
                return BarTooltipItem(
                  '${DateFormat('EEE').format(day.date)}\n'
                  '${day.present}P  ${day.late}L  ${day.absent}A',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('EEE').format(data[i].date),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textGrey),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (chartMax / 4).ceilToDouble(),
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.borderDark.withValues(alpha: 0.5),
                strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final hasData = t.total > 0;
            return BarChartGroupData(
              x: i,
              groupVertically: false,
              barRods: [
                BarChartRodData(
                  toY: hasData ? (t.present + t.late).toDouble() : 0,
                  color: AppTheme.primaryGreen,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: hasData ? t.absent.toDouble() : 0,
                  color: AppTheme.errorRed.withValues(alpha: 0.6),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 3,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Payment Breakdown ────────────────────────────────────

class _PaymentBreakdown extends StatelessWidget {
  final PaymentSummary payments;
  const _PaymentBreakdown({required this.payments});

  @override
  Widget build(BuildContext context) {
    final total = payments.totalCount;
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          // Pie chart
          SizedBox(
            width: 90,
            height: 90,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: [
                  if (payments.paidCount > 0)
                    PieChartSectionData(
                      value: payments.paidCount.toDouble(),
                      color: AppTheme.successGreen,
                      radius: 20,
                      title: '',
                    ),
                  if (payments.pendingCount > 0)
                    PieChartSectionData(
                      value: payments.pendingCount.toDouble(),
                      color: AppTheme.accentAmber,
                      radius: 20,
                      title: '',
                    ),
                  if (payments.overdueCount > 0)
                    PieChartSectionData(
                      value: payments.overdueCount.toDouble(),
                      color: AppTheme.errorRed,
                      radius: 20,
                      title: '',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  color: AppTheme.successGreen,
                  label: 'Paid',
                  count: payments.paidCount,
                  amount: payments.paidAmount,
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  color: AppTheme.accentAmber,
                  label: 'Pending',
                  count: payments.pendingCount,
                  amount: payments.pendingAmount,
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  color: AppTheme.errorRed,
                  label: 'Overdue',
                  count: payments.overdueCount,
                  amount: payments.overdueAmount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final double amount;
  const _LegendRow(
      {required this.color,
      required this.label,
      required this.count,
      required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textGrey)),
        const Spacer(),
        Text(
          '$count  ₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}K' : amount.toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    );
  }
}

// ── Empty State ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.textSubtle),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppTheme.textGrey)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
