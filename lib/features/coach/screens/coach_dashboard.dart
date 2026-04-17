import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/session_card.dart';

class CoachDashboard extends StatelessWidget {
  const CoachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionProvider>();
    final players = context.watch<PlayerProvider>().players;
    final user = auth.userModel;

    final now = DateTime.now();
    final todaySessions = sessions.upcomingSessions
        .where((s) =>
            s.dateTime.year == now.year &&
            s.dateTime.month == now.month &&
            s.dateTime.day == now.day)
        .toList();

    final thisWeek = sessions.upcomingSessions
        .where((s) =>
            s.dateTime.isAfter(now) &&
            s.dateTime.isBefore(now.add(const Duration(days: 7))))
        .toList();

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
            // Welcome card
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
                  Text(
                    'Hello, Coach ${user?.name.split(' ').first ?? ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatPill(
                          label: '${players.length}',
                          suffix: 'players'),
                      const SizedBox(width: 12),
                      _StatPill(
                          label: '${thisWeek.length}',
                          suffix: 'sessions this week'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's sessions
            if (todaySessions.isNotEmpty) ...[
              const Text(
                "Today's Sessions",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              ...todaySessions.map((s) => SessionCard(
                    session: s,
                    actions: [
                      TextButton.icon(
                        onPressed: () => context
                            .push('/coach/sessions/${s.id}/attendance'),
                        icon: const Icon(Icons.check_circle_outline,
                            size: 16),
                        label: const Text('Mark Attendance'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen),
                      ),
                    ],
                  )),
              const SizedBox(height: 16),
            ],

            // Upcoming
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Sessions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                ),
                TextButton(
                  onPressed: () => context.go('/coach/sessions'),
                  child: const Text('See all'),
                ),
              ],
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
}

class _StatPill extends StatelessWidget {
  final String label;
  final String suffix;
  const _StatPill({required this.label, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $suffix',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

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
            Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: AppTheme.textGrey)),
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
