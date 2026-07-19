import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/config/invite_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/player_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/session_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/drill_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/guardian_provider.dart';
import 'providers/invitation_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PlayAcademyApp());
}

class PlayAcademyApp extends StatelessWidget {
  const PlayAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => CoachProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => DrillProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => GuardianProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final _router = createRouter(context.read<AuthProvider>());
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    final authService = AuthService();

    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri.toString(), authService);
    });

    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null && mounted) {
        _handleLink(initial.toString(), authService);
      }
    } catch (_) {
      // No initial link or platform not supported
    }
  }

  void _handleLink(String url, AuthService authService) {
    if (!authService.isSignInWithEmailLink(url)) return;
    final parsed = InviteConfig.parseIncomingLink(url);
    if (parsed.email == null || parsed.inviteId == null) return;
    _router.go('/accept-invite', extra: {
      'email': parsed.email!,
      'inviteId': parsed.inviteId!,
      'link': url,
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth so router refreshListenable fires on changes
    context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Play Academy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
