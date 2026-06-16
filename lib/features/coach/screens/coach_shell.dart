import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/drill_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/video_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/team_provider.dart';

class CoachShell extends StatefulWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId =
          context.read<AuthProvider>().userModel?.branchId ?? '';
      if (branchId.isEmpty) return;
      context.read<PlayerProvider>().listenByBranch(branchId);
      context.read<SessionProvider>().listenToSessions(branchId);
      context.read<SessionProvider>().listenToUpcoming(branchId);
      context.read<DrillProvider>().listenByBranch(branchId);
      context.read<VideoProvider>().listenByBranch(branchId);
      context.read<TeamProvider>().listenByBranch(branchId);
      context.read<DashboardProvider>().load(branchId);
    });
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/coach/sessions')) return 1;
    if (loc.startsWith('/coach/players')) return 2;
    if (loc.startsWith('/coach/teams')) return 3;
    if (loc.startsWith('/coach/drills')) return 4;
    if (loc.startsWith('/coach/video')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/coach');
            case 1:
              context.go('/coach/sessions');
            case 2:
              context.go('/coach/players');
            case 3:
              context.go('/coach/teams');
            case 4:
              context.go('/coach/drills');
            case 5:
              context.go('/coach/video');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_gymnastics_outlined),
            selectedIcon: Icon(Icons.sports_gymnastics),
            label: 'Drills',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Video',
          ),
        ],
      ),
    );
  }
}
