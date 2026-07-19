import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/invitation_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

enum _AcceptState { verifying, form, saving, done, error }

class AcceptInviteScreen extends StatefulWidget {
  final String email;
  final String inviteId;
  final String link;

  const AcceptInviteScreen({
    super.key,
    required this.email,
    required this.inviteId,
    required this.link,
  });

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  _AcceptState _state = _AcceptState.verifying;
  String? _errorMsg;
  InvitationModel? _invite;
  String? _uid;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _verifyAndSignIn();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: sign in with email link, load invitation ─────────────────────

  Future<void> _verifyAndSignIn() async {
    setState(() {
      _state = _AcceptState.verifying;
      _errorMsg = null;
    });

    if (widget.email.isEmpty || widget.inviteId.isEmpty) {
      _setError(
          'Invalid invitation link. Please ask your admin to resend the invite.');
      return;
    }

    try {
      // If already signed in with the same email (e.g., re-tapping the link after
      // a crash or background/foreground cycle), skip re-authenticating with the link.
      final current = FirebaseAuth.instance.currentUser;
      final alreadySignedIn = current != null &&
          current.email?.toLowerCase() == widget.email.toLowerCase();

      if (alreadySignedIn) {
        _uid = current.uid;
      } else {
        if (widget.link.isEmpty) {
          _setError(
              'Invalid invitation link. Please ask your admin to resend the invite.');
          return;
        }
        final credential = await _authService.completeEmailLinkSignIn(
            widget.email, widget.link);
        _uid = credential.user?.uid;
      }

      final invite =
          await _firestoreService.getInvitationById(widget.inviteId);

      if (invite == null || invite.isRevoked) {
        _setError(invite == null
            ? 'Invitation not found. It may have been deleted by your admin.'
            : 'This invitation has been revoked. Please contact your admin.');
        return;
      }

      if (invite.isAccepted) {
        // Already set up — just go home
        _navigateHome(invite.role);
        return;
      }

      _invite = invite;
      if (invite.name != null && invite.name!.isNotEmpty) {
        _nameCtrl.text = invite.name!;
      }
      setState(() => _state = _AcceptState.form);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e.code));
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  // ── Step 2: complete profile ──────────────────────────────────────────────

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _state = _AcceptState.saving);

    try {
      await _authService.updatePassword(_passCtrl.text);

      if (_uid != null) {
        await _firestoreService.updateUserDoc(_uid!, {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        });
      }

      await _firestoreService.updateInvitationStatus(
          widget.inviteId, AppConstants.inviteStatusAccepted);

      setState(() => _state = _AcceptState.done);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) _navigateHome(_invite!.role);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _state = _AcceptState.form;
        _errorMsg = _friendlyAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        _state = _AcceptState.form;
        _errorMsg = 'Something went wrong. Please try again.';
      });
    }
  }

  void _setError(String msg) =>
      setState(() {
        _state = _AcceptState.error;
        _errorMsg = msg;
      });

  void _navigateHome(String role) {
    if (!mounted) return;
    switch (role) {
      case AppConstants.roleCoach:
        context.go('/coach');
      default:
        context.go('/player');
    }
  }

  String _friendlyAuthError(String code) => switch (code) {
        'invalid-action-code' ||
        'expired-action-code' =>
          'This invitation link has expired. Please ask your admin to resend it.',
        'invalid-email' =>
          'Email mismatch. This link was sent to ${widget.email}.',
        'user-disabled' =>
          'This account has been disabled. Please contact your admin.',
        _ =>
          'Sign-in failed ($code). Please try again or contact your admin.',
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_state) {
          _AcceptState.verifying => _buildVerifying(),
          _AcceptState.form => _buildForm(),
          _AcceptState.saving => _buildSaving(),
          _AcceptState.done => _buildDone(),
          _AcceptState.error => _buildError(),
        },
      ),
    );
  }

  Widget _buildVerifying() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 20),
            Text('Verifying your invitation…',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 15)),
          ],
        ),
      );

  Widget _buildSaving() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 20),
            Text('Setting up your account…',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 15)),
          ],
        ),
      );

  Widget _buildDone() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 40, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            const Text("You're all set!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Taking you to your dashboard…',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          ],
        ),
      );

  Widget _buildError() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppTheme.errorRed),
            ),
            const SizedBox(height: 20),
            const Text('Invitation Error',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Text(
              _errorMsg ?? 'An error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textGrey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      );

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports,
                        size: 32, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  const Text('Set Up Your Account',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Text(
                    "You've been invited to Play Academy",
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Email (display only) ────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.email,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textDark)),
                  ),
                  const Icon(Icons.lock_outline,
                      size: 14, color: AppTheme.textSubtle),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile fields ──────────────────────────
            const Text('Your Profile',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
            ),
            const SizedBox(height: 28),

            // ── Password ────────────────────────────────
            const Text('Create Password',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            const Text(
              'You\'ll use this to log in from now on.',
              style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            // ── Inline error ────────────────────────────
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(_errorMsg!,
                  style: const TextStyle(
                      color: AppTheme.errorRed, fontSize: 13)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _completeProfile,
                child: const Text('Set Up Account',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
