import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_org_screen.dart';
import '../../features/org_admin/screens/org_admin_shell.dart';
import '../../features/org_admin/screens/org_dashboard.dart';
import '../../features/org_admin/screens/branches_screen.dart';
import '../../features/org_admin/screens/add_edit_branch_screen.dart';
import '../../features/org_admin/screens/branch_detail_screen.dart';
import '../../features/org_admin/screens/players_screen.dart';
import '../../features/org_admin/screens/add_edit_player_screen.dart';
import '../../features/org_admin/screens/coaches_screen.dart';
import '../../features/org_admin/screens/add_edit_coach_screen.dart';
import '../../features/org_admin/screens/guardians_screen.dart';
import '../../features/org_admin/screens/add_edit_guardian_screen.dart';
import '../../features/coach/screens/coach_shell.dart';
import '../../features/coach/screens/coach_dashboard.dart';
import '../../features/coach/screens/sessions_screen.dart';
import '../../features/coach/screens/add_session_screen.dart';
import '../../features/coach/screens/mark_attendance_screen.dart';
import '../../features/coach/screens/qr_generator_screen.dart';
import '../../features/coach/screens/coach_players_screen.dart';
import '../../features/coach/screens/drills_screen.dart';
import '../../features/coach/screens/batches_screen.dart';
import '../../features/org_admin/screens/admin_batches_screen.dart';
import '../../features/org_admin/screens/add_edit_batch_screen.dart';
import '../../features/player/screens/player_shell.dart';
import '../../features/player/screens/player_dashboard.dart';
import '../../features/player/screens/player_schedule_screen.dart';
import '../../features/player/screens/player_attendance_screen.dart';
import '../../features/player/screens/player_payments_screen.dart';
import '../../features/player/screens/qr_scanner_screen.dart';
import '../../features/shared/player_detail_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _orgAdminShellKey = GlobalKey<NavigatorState>();
final _coachShellKey = GlobalKey<NavigatorState>();
final _playerShellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final role = authProvider.userModel?.role;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) return null;

      final onAuthPage = loc == '/login' || loc == '/register';

      if (status == AuthStatus.unauthenticated) {
        return onAuthPage ? null : '/login';
      }

      if (onAuthPage) {
        if (role == AppConstants.roleOrgAdmin) return '/org';
        if (role == AppConstants.roleCoach) return '/coach';
        if (role == AppConstants.rolePlayer) return '/player';
        if (role == AppConstants.roleGuardian) return '/player';
      }

      if (loc.startsWith('/org') && role != AppConstants.roleOrgAdmin) {
        return '/login';
      }
      if (loc.startsWith('/coach') && role != AppConstants.roleCoach) {
        return '/login';
      }
      if (loc.startsWith('/player') &&
          role != AppConstants.rolePlayer &&
          role != AppConstants.roleGuardian) {
        return '/login';
      }

      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterOrgScreen()),

      // ── Org Admin Shell ──────────────────────────────────
      ShellRoute(
        navigatorKey: _orgAdminShellKey,
        builder: (_, _, child) => OrgAdminShell(child: child),
        routes: [
          GoRoute(path: '/org', builder: (_, _) => const OrgDashboard()),
          GoRoute(
              path: '/org/branches', builder: (_, _) => const BranchesScreen()),
          GoRoute(
              path: '/org/players', builder: (_, _) => const OrgPlayersScreen()),
          GoRoute(
              path: '/org/coaches', builder: (_, _) => const CoachesScreen()),
          GoRoute(
              path: '/org/batches',
              builder: (_, _) => const AdminBatchesScreen()),
          GoRoute(
              path: '/org/guardians',
              builder: (_, _) => const GuardiansScreen()),
        ],
      ),

      // ── Coach Shell ──────────────────────────────────────
      ShellRoute(
        navigatorKey: _coachShellKey,
        builder: (_, _, child) => CoachShell(child: child),
        routes: [
          GoRoute(path: '/coach', builder: (_, _) => const CoachDashboard()),
          GoRoute(
              path: '/coach/sessions',
              builder: (_, _) => const CoachSessionsScreen()),
          GoRoute(
              path: '/coach/drills', builder: (_, _) => const DrillsScreen()),
          GoRoute(
              path: '/coach/players',
              builder: (_, _) => const CoachPlayersScreen()),
          GoRoute(
              path: '/coach/batches',
              builder: (_, _) => const BatchesScreen()),
        ],
      ),

      // ── Player Shell ─────────────────────────────────────
      ShellRoute(
        navigatorKey: _playerShellKey,
        builder: (_, _, child) => PlayerShell(child: child),
        routes: [
          GoRoute(path: '/player', builder: (_, _) => const PlayerDashboard()),
          GoRoute(
              path: '/player/schedule',
              builder: (_, _) => const PlayerScheduleScreen()),
          GoRoute(
              path: '/player/attendance',
              builder: (_, _) => const PlayerAttendanceScreen()),
          GoRoute(
              path: '/player/payments',
              builder: (_, _) => const PlayerPaymentsScreen()),
        ],
      ),

      // ── Full-screen routes (no shell) ────────────────────
      // Org Admin
      GoRoute(
          path: '/org/branches/add',
          builder: (_, _) => const AddEditBranchScreen()),
      GoRoute(
          path: '/org/branches/edit/:id',
          builder: (_, state) =>
              AddEditBranchScreen(branchId: state.pathParameters['id'])),
      GoRoute(
          path: '/org/branches/:id',
          builder: (_, state) =>
              BranchDetailScreen(branchId: state.pathParameters['id']!)),
      GoRoute(
          path: '/org/players/add',
          builder: (_, _) => const AddEditPlayerScreen()),
      GoRoute(
          path: '/org/players/edit/:id',
          builder: (_, state) =>
              AddEditPlayerScreen(playerId: state.pathParameters['id'])),
      GoRoute(
          path: '/org/players/:id',
          builder: (_, state) => PlayerDetailScreen(
                playerId: state.pathParameters['id']!,
                backRoute: '/org/players',
              )),
      GoRoute(
          path: '/org/coaches/add',
          builder: (_, _) => const AddEditCoachScreen()),
      GoRoute(
          path: '/org/coaches/edit/:id',
          builder: (_, state) =>
              AddEditCoachScreen(coachId: state.pathParameters['id'])),
      GoRoute(
          path: '/org/batches/add',
          builder: (_, _) => const OrgAdminAddEditBatchScreen()),
      GoRoute(
          path: '/org/batches/edit/:id',
          builder: (_, state) => OrgAdminAddEditBatchScreen(
              batchId: state.pathParameters['id'])),
      GoRoute(
          path: '/org/guardians/add',
          builder: (_, _) => const AddEditGuardianScreen()),
      GoRoute(
          path: '/org/guardians/edit/:id',
          builder: (_, state) =>
              AddEditGuardianScreen(guardianId: state.pathParameters['id'])),

      // Coach
      GoRoute(
          path: '/coach/sessions/add',
          builder: (_, _) => const AddSessionScreen()),
      GoRoute(
          path: '/coach/sessions/:sessionId/attendance',
          builder: (_, state) => MarkAttendanceScreen(
              sessionId: state.pathParameters['sessionId']!)),
      GoRoute(
          path: '/coach/sessions/:sessionId/qr',
          builder: (_, state) =>
              QrGeneratorScreen(sessionId: state.pathParameters['sessionId']!)),
      GoRoute(
          path: '/coach/players/:id',
          builder: (_, state) => PlayerDetailScreen(
                playerId: state.pathParameters['id']!,
                backRoute: '/coach/players',
              )),
      // Player
      GoRoute(path: '/player/scan', builder: (_, _) => const QrScannerScreen()),
    ],
  );
}
