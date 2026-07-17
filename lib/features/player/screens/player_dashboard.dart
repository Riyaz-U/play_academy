import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/guardian_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../models/attendance_model.dart';
import '../../../models/sport_profile_model.dart';
import '../../../models/stats_history_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/session_card.dart';

class PlayerDashboard extends StatefulWidget {
  const PlayerDashboard({super.key});

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  List<SportProfileModel> _profiles = [];
  List<StatsHistoryModel> _history = [];
  String? _selectedSport;
  String? _selectedStatKey; // null = Overall
  String? _activePlayerId;
  StreamSubscription<List<SportProfileModel>>? _profileSub;
  StreamSubscription<List<StatsHistoryModel>>? _historySub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final String? uid = auth.isGuardian
        ? context.watch<GuardianProvider>().selectedChild?.uid
        : auth.userModel?.uid;

    if (uid != null && uid != _activePlayerId) {
      _activePlayerId = uid;
      _profileSub?.cancel();
      _historySub?.cancel();
      _selectedSport = null;
      final fs = FirestoreService();
      _profileSub = fs.streamSportProfiles(uid).listen((profiles) {
        if (mounted) {
          setState(() {
            _profiles = profiles;
            _selectedSport ??=
                profiles.isNotEmpty ? profiles.first.sport : null;
          });
        }
      });
      _historySub = fs.streamStatsHistory(uid).listen((history) {
        if (mounted) setState(() => _history = history);
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  SportProfileModel? get _selectedProfile => _profiles
      .where((p) => p.sport == _selectedSport)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final playerSelf = context.watch<PlayerProvider>().self;
    final displayName = playerSelf?.name ?? user?.name ?? '';
    final sessions = context.watch<SessionProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final payments = context.watch<PaymentProvider>();

    final now = DateTime.now();
    final nextSession = sessions.upcomingSessions.isNotEmpty
        ? sessions.upcomingSessions.first
        : null;

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

    final recentPerf = attendance.playerAttendance
        .where((a) => a.rating != null && a.rating! > 0)
        .toList()
      ..sort((a, b) => b.markedAt.compareTo(a.markedAt));
    final recentPerfSlice = recentPerf.take(5).toList();

    final total = attendance.playerAttendance.length;
    final present =
        attendance.playerAttendance.where((a) => a.status == 'present').length;
    final late =
        attendance.playerAttendance.where((a) => a.status == 'late').length;
    final absent =
        attendance.playerAttendance.where((a) => a.status == 'absent').length;

    final profile = _selectedProfile;
    final statKeys = _selectedSport != null
        ? (AppConstants.sportStats[_selectedSport] ?? [])
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Academy'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child:
                  Icon(Icons.person, color: AppTheme.onPrimary, size: 20),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sport tabs ────────────────────────────────────────────────
            if (_profiles.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _profiles.map((p) {
                    final selected = p.sport == _selectedSport;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                            p.sport[0].toUpperCase() + p.sport.substring(1)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedSport = p.sport),
                        selectedColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.onPrimary
                              : AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                        decoration: const BoxDecoration(
                          color: AppTheme.onPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
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
                              displayName,
                              style: const TextStyle(
                                  color: AppTheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM').format(now),
                              style: TextStyle(
                                  color: AppTheme.onPrimary
                                      .withValues(alpha: 0.75),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (profile != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.onPrimary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '#${profile.jerseyNumber}',
                                style: const TextStyle(
                                    color: AppTheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                profile.position,
                                style: TextStyle(
                                    color: AppTheme.onPrimary
                                        .withValues(alpha: 0.8),
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
                      if (profile != null)
                        _StatPill(
                          label: profile.overall.toStringAsFixed(0),
                          suffix: 'overall',
                          icon: Icons.sports_score,
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
            if (profile != null && statKeys.isNotEmpty) ...[
              _SectionHeader(title: 'Player Stats'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.borderDark.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverallBadge(overall: profile.overall),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: statKeys
                            .take((statKeys.length / 2).ceil())
                            .map((k) => _StatBar(
                                  label: k[0].toUpperCase() + k.substring(1),
                                  value: profile.stats[k] ?? 50,
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: statKeys
                            .skip((statKeys.length / 2).ceil())
                            .map((k) => _StatBar(
                                  label: k[0].toUpperCase() + k.substring(1),
                                  value: profile.stats[k] ?? 50,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Performance Trend ─────────────────────────────────────────
            if (_selectedSport != null) ...[
              () {
                final sportHistory = (_history
                      .where((h) => h.sport == _selectedSport)
                      .toList()
                    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)));
                if (sportHistory.length < 2) return const SizedBox.shrink();
                return _PerformanceTrendSection(
                  history: sportHistory,
                  statKeys: statKeys,
                  selectedKey: _selectedStatKey,
                  onKeyChanged: (k) => setState(() => _selectedStatKey = k),
                );
              }(),
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
// ── Performance Trend Section ─────────────────────────────────────────────────

class _PerformanceTrendSection extends StatelessWidget {
  final List<StatsHistoryModel> history;
  final List<String> statKeys;
  final String? selectedKey;
  final ValueChanged<String?> onKeyChanged;

  const _PerformanceTrendSection({
    required this.history,
    required this.statKeys,
    required this.selectedKey,
    required this.onKeyChanged,
  });

  List<FlSpot> _spots() {
    return history.asMap().entries.map((e) {
      final value = selectedKey == null
          ? e.value.overall
          : (e.value.stats[selectedKey] ?? 0).toDouble();
      return FlSpot(e.key.toDouble(), value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots();
    final dates = history.map((h) => DateFormat('d MMM').format(h.recordedAt)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text('Performance Trend',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        const SizedBox(height: 10),

        // Stat selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Overall chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Overall'),
                  selected: selectedKey == null,
                  onSelected: (_) => onKeyChanged(null),
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: selectedKey == null
                        ? AppTheme.onPrimary
                        : AppTheme.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              // Per-stat chips
              ...statKeys.map((k) {
                final isSelected = selectedKey == k;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(k[0].toUpperCase() + k.substring(1)),
                    selected: isSelected,
                    onSelected: (_) => onKeyChanged(k),
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.onPrimary
                          : AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Line chart
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primaryGreen,
                      strokeColor: AppTheme.cardDark,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final date = idx < dates.length ? dates[idx] : '';
                    return LineTooltipItem(
                      '$date\n${s.y.toStringAsFixed(1)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= dates.length) {
                        return const SizedBox.shrink();
                      }
                      // Only show first, last, and middle to avoid crowding
                      final show = idx == 0 ||
                          idx == dates.length - 1 ||
                          (dates.length > 4 && idx == (dates.length ~/ 2));
                      if (!show) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(dates[idx],
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 9)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          color: AppTheme.textSubtle, fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.borderDark, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}

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

// ── Overall badge ─────────────────────────────────────────────────────────────
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

// ── Stat bar ──────────────────────────────────────────────────────────────────
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

// ── Attendance box ────────────────────────────────────────────────────────────
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
        border:
            Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
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
                i < (record.rating ?? 0)
                    ? Icons.star
                    : Icons.star_border,
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

// ── Stat pill ─────────────────────────────────────────────────────────────────
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
            style:
                const TextStyle(color: AppTheme.onPrimary, fontSize: 12),
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
                    decoration: TextDecoration.underline,
                    decorationColor: color)),
          ),
        ],
      ),
    );
  }
}

// ── Empty card ────────────────────────────────────────────────────────────────
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
        border:
            Border.all(color: AppTheme.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textSubtle),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  color: AppTheme.textGrey, fontSize: 13)),
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
        border:
            Border.all(color: AppTheme.borderDark.withValues(alpha: 0.5)),
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
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textGrey),
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
