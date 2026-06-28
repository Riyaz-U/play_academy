import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/player_model.dart';
import '../../../widgets/star_rating.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String sessionId;
  const MarkAttendanceScreen({super.key, required this.sessionId});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AttendanceProvider>()
          .listenToSessionAttendance(widget.sessionId);
    });
  }

  void _initAttendance(
      AttendanceProvider attendanceProvider, List<PlayerModel> players) {
    if (!_initialized && players.isNotEmpty) {
      attendanceProvider.initForSession(
          players, attendanceProvider.sessionAttendance);
      _initialized = true;
    }
  }

  Future<void> _saveAttendance(
      BuildContext context, List<PlayerModel> players) async {
    final user = context.read<AuthProvider>().userModel!;
    final success = await context.read<AttendanceProvider>().saveAttendance(
          sessionId: widget.sessionId,
          coachUid: user.uid,
          coachName: user.name,
          organizationId: user.organizationId,
          branchId: user.branchId ?? '',
          players: players,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Attendance saved!'),
        backgroundColor: AppTheme.successGreen,
      ));
    }
  }

  Future<void> _completeSession(BuildContext context) async {
    final highlightsCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complete Session',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add highlights for players to see:',
                style: TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 12),
            TextField(
              controller: highlightsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Key moments, video links, feedback...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Mark as Completed'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      await context.read<SessionProvider>().completeSession(
            sessionId: widget.sessionId,
            highlights: highlightsCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session completed!'),
          backgroundColor: AppTheme.successGreen,
        ));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session =
        context.watch<SessionProvider>().getById(widget.sessionId);
    final allPlayers = context.watch<PlayerProvider>().players;
    final playerProvider = context.watch<PlayerProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    List<PlayerModel> players;
    if (session != null &&
        (session.batchIds.isNotEmpty || session.playerIds.isNotEmpty)) {
      final ids = {
        ...session.playerIds,
        ...playerProvider.playerIdsInBatches(session.batchIds),
      };
      players = allPlayers.where((p) => ids.contains(p.uid)).toList();
    } else {
      players = allPlayers;
    }

    _initAttendance(attendanceProvider, players);

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? 'Mark Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR Check-in',
            onPressed: () =>
                context.push('/coach/sessions/${widget.sessionId}/qr'),
          ),
          if (session != null && !session.isCompleted)
            TextButton(
              onPressed: () => _completeSession(context),
              child: const Text('Complete',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Session info
          if (session != null)
            Container(
              color: AppTheme.cardDark,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, d MMM • h:mm a').format(session.dateTime),
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${players.length} players',
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          // Summary chips
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Present',
                  count: players
                      .where((p) =>
                          attendanceProvider.getStatus(p.uid) ==
                          AppConstants.attendancePresent)
                      .length,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Late',
                  count: players
                      .where((p) =>
                          attendanceProvider.getStatus(p.uid) ==
                          AppConstants.attendanceLate)
                      .length,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Absent',
                  count: players
                      .where((p) =>
                          attendanceProvider.getStatus(p.uid) ==
                          AppConstants.attendanceAbsent)
                      .length,
                  color: AppTheme.errorRed,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Player list
          Expanded(
            child: players.isEmpty
                ? const Center(
                    child: Text('No players in this branch/category',
                        style: TextStyle(color: AppTheme.textGrey)),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: players.length,
                    itemBuilder: (ctx, i) {
                      final p = players[i];
                      final status = attendanceProvider.getStatus(p.uid);
                      final rating = attendanceProvider.getRating(p.uid);
                      final attended = status == AppConstants.attendancePresent ||
                          status == AppConstants.attendanceLate;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                        p.name.isNotEmpty
                                            ? p.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            'Age ${p.age}',
                                            style: const TextStyle(
                                                color: AppTheme.textGrey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  // Status buttons
                                  _StatusButton(
                                    label: 'P',
                                    color: AppTheme.successGreen,
                                    selected: status ==
                                        AppConstants.attendancePresent,
                                    onTap: () => attendanceProvider
                                        .updateStatus(p.uid,
                                            AppConstants.attendancePresent),
                                  ),
                                  const SizedBox(width: 4),
                                  _StatusButton(
                                    label: 'L',
                                    color: AppTheme.warningOrange,
                                    selected: status ==
                                        AppConstants.attendanceLate,
                                    onTap: () => attendanceProvider
                                        .updateStatus(p.uid,
                                            AppConstants.attendanceLate),
                                  ),
                                  const SizedBox(width: 4),
                                  _StatusButton(
                                    label: 'A',
                                    color: AppTheme.errorRed,
                                    selected: status ==
                                        AppConstants.attendanceAbsent,
                                    onTap: () => attendanceProvider
                                        .updateStatus(p.uid,
                                            AppConstants.attendanceAbsent),
                                  ),
                                ],
                              ),
                              // Rating (shown when present/late)
                              if (attended) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Rating: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textGrey)),
                                    StarRating(
                                      rating: rating ?? 0,
                                      size: 20,
                                      onChanged: (r) => attendanceProvider
                                          .updateRating(p.uid, r),
                                    ),
                                    if (rating != null && rating > 0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 6),
                                        child: Text('$rating/5',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textGrey)),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: attendanceProvider.isLoading
                ? null
                : () => _saveAttendance(context, players),
            child: attendanceProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Attendance'),
          ),
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count $label',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
