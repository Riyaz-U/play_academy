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
      _setError('Invalid invitation link. Please ask your admin to resend the invite.');
      return;
    }

    try {
      // If already signed in with the same email (re-tap after crash, or the
      // Firestore user doc was already created on a previous attempt), skip sign-in.
      final current = FirebaseAuth.instance.currentUser;
      final alreadySignedIn = current != null &&
          current.email?.toLowerCase() == widget.email.toLowerCase();

      if (alreadySignedIn) {
        _uid = current.uid;
      } else {
        if (widget.link.isEmpty) {
          _setError(
              'The sign-in link could not be read. Please open the email link '
              'directly from your mail app, or ask your admin to resend the invite.');
          return;
        }
        final credential = await _authService.completeEmailLinkSignIn(
            widget.email, widget.link);
        _uid = credential.user?.uid;
      }

      if (_uid == null) {
        _setError('Sign-in failed. Please try again.');
        return;
      }

      final invite = await _firestoreService.getInvitationById(widget.inviteId);

      if (invite == null || invite.isRevoked) {
        _setError(invite == null
            ? 'Invitation not found. It may have been deleted by your admin.'
            : 'This invitation has been revoked. Please contact your admin.');
        return;
      }

      if (invite.isAccepted) {
        _navigateHome(invite.role);
        return;
      }

      _invite = invite;

      // Ensure a users doc exists so AuthProvider won't sign the user out while
      // they fill the form. If admin pre-created it (the normal flow), leave it
      // intact — only create it for email-link-only invites where no doc exists.
      final existingDoc = await _firestoreService.getUserDoc(_uid!);
      if (existingDoc == null) {
        await _firestoreService.createUserDoc(_uid!, {
          'email': widget.email.toLowerCase(),
          'role': invite.role,
          'organizationId': invite.organizationId,
          'isActive': true,
          if (invite.name != null && invite.name!.isNotEmpty) 'name': invite.name,
        });
      }

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
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final now = DateTime.now();

      // Update the user doc with the submitted name/phone.
      await _firestoreService.updateUserDoc(_uid!, {
        'name': name,
        'phone': phone,
      });

      // Update the role-specific doc. If admin pre-created it (normal flow) we
      // just patch name/phone; otherwise create it from scratch.
      try {
        if (_invite!.role == AppConstants.roleCoach) {
          await _firestoreService.updateCoachDoc(_uid!, {'name': name, 'phone': phone});
        } else {
          await _firestoreService.updatePlayerDoc(_uid!, {'name': name, 'phone': phone});
        }
      } catch (_) {
        // Doc doesn't exist yet (email-link-only invite) — create it.
        final roleData = {
          'email': widget.email.toLowerCase(),
          'name': name,
          'phone': phone,
          'organizationId': _invite!.organizationId,
          'branchId': _invite!.branchId ?? '',
          'isActive': true,
          'createdAt': now,
        };
        if (_invite!.role == AppConstants.roleCoach) {
          await _firestoreService.createCoachDoc(_uid!, roleData);
        } else {
          await _firestoreService.createPlayerDoc(_uid!, roleData);
        }
      }

      await _authService.updatePassword(_passCtrl.text);
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

  IconData _roleIcon(String role) => switch (role) {
        AppConstants.roleCoach => Icons.sports_soccer,
        AppConstants.roleGuardian => Icons.family_restroom,
        _ => Icons.sports,
      };

  String _roleLabel(String role) => switch (role) {
        AppConstants.roleCoach => 'Coach',
        AppConstants.roleGuardian => 'Guardian',
        _ => 'Player',
      };

  Color _roleColor(String role) => switch (role) {
        AppConstants.roleCoach => const Color(0xFFF59E0B),
        AppConstants.roleGuardian => const Color(0xFF6366F1),
        _ => AppTheme.primaryGreen,
      };

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
                    child: Icon(_roleIcon(_invite!.role),
                        size: 32, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  const Text('Set Up Your Account',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _roleColor(_invite!.role).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _roleColor(_invite!.role).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Joining as ${_roleLabel(_invite!.role)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _roleColor(_invite!.role)),
                    ),
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
