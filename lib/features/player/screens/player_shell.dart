import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/guardian_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../models/player_model.dart';
import '../../../services/notification_service.dart';

class PlayerShell extends StatefulWidget {
  final Widget child;
  const PlayerShell({super.key, required this.child});

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  String? _activePlayerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.userModel;
      if (user == null) return;

      if (auth.isGuardian) {
        // Start streaming children; streams initialized in didChangeDependencies
        // once GuardianProvider sets selectedChild
        context.read<GuardianProvider>().listen(user.uid);
      } else {
        _initStreams(user.uid, user.branchId ?? '');
        _activePlayerId = user.uid;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();

    if (auth.isGuardian) {
      final child = context.watch<GuardianProvider>().selectedChild;
      if (child != null && child.uid != _activePlayerId) {
        _activePlayerId = child.uid;
        _initStreams(child.uid, child.branchId);
      }
    }

    // Sync FCM sport topics whenever selfSportProfiles changes
    final sports = context
        .watch<PlayerProvider>()
        .selfSportProfiles
        .map((p) => p.sport)
        .toList();
    NotificationService().syncSportTopics(sports);
  }

  void _initStreams(String playerId, String branchId) {
    context.read<SessionProvider>().listenToUpcoming(branchId);
    context.read<SessionProvider>().listenToSessions(branchId);
    context.read<AttendanceProvider>().listenToPlayerAttendance(playerId);
    context.read<PaymentProvider>().listenToPlayerPayments(playerId);
    context.read<PlayerProvider>().listenToSelf(playerId);
  }

  @override
  void dispose() {
    // Clear guardian state when shell is torn down (sign-out / role change)
    context.read<GuardianProvider>().clear();
    super.dispose();
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/player/schedule')) return 1;
    if (loc.startsWith('/player/attendance')) return 2;
    if (loc.startsWith('/player/payments')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian = context.watch<AuthProvider>().isGuardian;
    final guardian = context.watch<GuardianProvider>();

    return Scaffold(
      body: Column(
        children: [
          if (isGuardian && guardian.hasMultipleChildren)
            _ChildSwitcherBar(
              selected: guardian.selectedChild,
              children: guardian.children,
              onSelect: (child) {
                context.read<GuardianProvider>().selectChild(child);
              },
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/player');
            case 1:
              context.go('/player/schedule');
            case 2:
              context.go('/player/attendance');
            case 3:
              context.go('/player/payments');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}

// ── Child switcher bar ────────────────────────────────────────────────────────
class _ChildSwitcherBar extends StatelessWidget {
  final PlayerModel? selected;
  final List<PlayerModel> children;
  final ValueChanged<PlayerModel> onSelect;

  const _ChildSwitcherBar({
    required this.selected,
    required this.children,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => _showPicker(context),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.15),
                  child: Text(
                    selected != null && selected!.name.isNotEmpty
                        ? selected!.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected?.name ?? 'Select child',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Tap to switch',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Switch Child',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final child in children)
              ListTile(
                leading: CircleAvatar(
                  child: Text(child.name.isNotEmpty
                      ? child.name[0].toUpperCase()
                      : '?'),
                ),
                title: Text(child.name),
                subtitle: Text('Age ${child.age}'),
                selected: child.uid == selected?.uid,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onSelect(child);
                },
                trailing: child.uid == selected?.uid
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
