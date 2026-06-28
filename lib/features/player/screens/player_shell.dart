import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/notification_service.dart';

class PlayerShell extends StatefulWidget {
  final Widget child;
  const PlayerShell({super.key, required this.child});

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) return;
      context.read<SessionProvider>().listenToUpcoming(user.branchId ?? '');
      context.read<SessionProvider>().listenToSessions(user.branchId ?? '');
      context.read<AttendanceProvider>().listenToPlayerAttendance(user.uid);
      context.read<PaymentProvider>().listenToPlayerPayments(user.uid);
      // listenToSelf also starts the selfSportProfiles stream
      context.read<PlayerProvider>().listenToSelf(user.uid);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync FCM sport topics whenever selfSportProfiles changes.
    final sports = context
        .watch<PlayerProvider>()
        .selfSportProfiles
        .map((p) => p.sport)
        .toList();
    NotificationService().syncSportTopics(sports);
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
    return Scaffold(
      body: widget.child,
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
