import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/attendance_model.dart';

class PlayerAttendanceScreen extends StatelessWidget {
  const PlayerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final sessions = context.watch<SessionProvider>();
    final records = attendance.playerAttendance
      ..sort((a, b) => b.markedAt.compareTo(a.markedAt));

    final pct = attendance.attendancePercentage;
    final avg = attendance.averageRating;
    final attended = records.where((r) => r.attended).length;

    return Scaffold(
      appBar: AppBar(title: Text('Attendance (${records.length})')),
      body: Column(
        children: [
          // Summary header
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Percentage circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 7,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen),
                      ),
                      Center(
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(
                        label: 'Sessions attended',
                        value: '$attended / ${records.length}',
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Average rating',
                        value: avg > 0 ? '${avg.toStringAsFixed(1)} / 5' : 'N/A',
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Present',
                        value:
                            '${records.where((r) => r.isPresent).length}',
                        valueColor: AppTheme.successGreen,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Late',
                        value:
                            '${records.where((r) => r.isLate).length}',
                        valueColor: AppTheme.warningOrange,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Absent',
                        value:
                            '${records.where((r) => r.isAbsent).length}',
                        valueColor: AppTheme.errorRed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Records list
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text('No attendance records yet',
                            style: TextStyle(color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: records.length,
                    itemBuilder: (ctx, i) {
                      final r = records[i];
                      // Try to find the session title
                      final session = sessions.sessions
                          .where((s) => s.id == r.sessionId)
                          .toList();
                      final title = session.isNotEmpty
                          ? session.first.title
                          : 'Session';
                      final sessionType = session.isNotEmpty
                          ? session.first.type
                          : AppConstants.sessionTypeTraining;

                      return _AttendanceRecord(
                        record: r,
                        sessionTitle: title,
                        sessionType: sessionType,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textDark)),
      ],
    );
  }
}

class _AttendanceRecord extends StatelessWidget {
  final AttendanceModel record;
  final String sessionTitle;
  final String sessionType;

  const _AttendanceRecord({
    required this.record,
    required this.sessionTitle,
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (record.status) {
      AppConstants.attendancePresent => (AppTheme.successGreen, 'Present'),
      AppConstants.attendanceLate => (AppTheme.warningOrange, 'Late'),
      _ => (AppTheme.errorRed, 'Absent'),
    };

    final typeColor = sessionType == AppConstants.sessionTypeMatch
        ? AppTheme.accentAmber
        : AppTheme.primaryGreen;
    final typeLabel =
        sessionType == AppConstants.sessionTypeMatch ? 'Match' : 'Training';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(typeLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: typeColor,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('d MMM yyyy').format(record.markedAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            // Rating row (if rated)
            if (record.rating != null && record.rating! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < record.rating! ? Icons.star : Icons.star_outline,
                      size: 16,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${record.rating}/5 by ${record.markedByName}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
            if (record.ratingNote != null &&
                record.ratingNote!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('"${record.ratingNote}"',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
