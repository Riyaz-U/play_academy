import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/session_provider.dart';

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
    });
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/coach/sessions')) return 1;
    if (loc.startsWith('/coach/players')) return 2;
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
        ],
      ),
    );
  }
}
