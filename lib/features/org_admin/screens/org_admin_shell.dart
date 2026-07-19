import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/guardian_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/coach_provider.dart';

class OrgAdminShell extends StatefulWidget {
  final Widget child;
  const OrgAdminShell({super.key, required this.child});

  @override
  State<OrgAdminShell> createState() => _OrgAdminShellState();
}

class _OrgAdminShellState extends State<OrgAdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId =
          context.read<AuthProvider>().userModel?.organizationId ?? '';
      if (orgId.isEmpty) return;
      context.read<BranchProvider>().listenToBranches(orgId);
      context.read<PlayerProvider>().listenByOrg(orgId);
      context.read<CoachProvider>().listenByOrg(orgId);
      context.read<BatchProvider>().listenByOrg(orgId);
      context.read<GuardianProvider>().listenByOrg(orgId);
      context.read<InvitationProvider>().listenByOrg(orgId);
    });
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/org/branches')) return 1;
    if (loc.startsWith('/org/players')) return 2;
    if (loc.startsWith('/org/coaches')) return 3;
    if (loc.startsWith('/org/batches')) return 4;
    if (loc.startsWith('/org/guardians')) return 5;
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
              context.go('/org');
            case 1:
              context.go('/org/branches');
            case 2:
              context.go('/org/players');
            case 3:
              context.go('/org/coaches');
            case 4:
              context.go('/org/batches');
            case 5:
              context.go('/org/guardians');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Branches',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Coaches',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_work_outlined),
            selectedIcon: Icon(Icons.group_work),
            label: 'Batches',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Guardians',
          ),
        ],
      ),
    );
  }
}
