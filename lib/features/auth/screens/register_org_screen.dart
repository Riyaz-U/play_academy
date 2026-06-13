import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/organization_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/constants/app_constants.dart';

class RegisterOrgScreen extends StatefulWidget {
  const RegisterOrgScreen({super.key});

  @override
  State<RegisterOrgScreen> createState() => _RegisterOrgScreenState();
}

class _RegisterOrgScreenState extends State<RegisterOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 1. Create Firebase Auth account
    final UserCredential credential;
    try {
      credential = await _authService.registerWithEmailAndPassword(
        _emailCtrl.text,
        _passwordCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyError(e.code);
        _isLoading = false;
      });
      return;
    }

    final uid = credential.user!.uid;

    try {
      // 2. Create organization doc (use uid as orgId)
      final org = OrganizationModel(
        id: uid,
        name: _orgNameCtrl.text.trim(),
        adminName: _adminNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await _firestoreService.createOrganization(uid, org.toMap())
          .timeout(const Duration(seconds: 10));

      // 3. Create user doc
      final user = UserModel(
        uid: uid,
        name: _adminNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: AppConstants.roleOrgAdmin,
        organizationId: uid,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserDoc(uid, user.toMap())
          .timeout(const Duration(seconds: 10));

      // Auth listener in AuthProvider will pick this up and navigate
    } catch (e) {
      // Firestore failed — roll back by deleting the Auth account
      // so the user can try again with the same email
      await credential.user!.delete();
      if (mounted) {
        setState(() {
          _error = 'Setup failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Register Academy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sports_soccer, color: AppTheme.darkGreen, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Create your Academy',
                      style: TextStyle(
                        color: AppTheme.darkGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Set up your organization to get started',
                      style: TextStyle(
                          color: AppTheme.darkGreen, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Organization info
              _SectionLabel('Academy Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orgNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Academy Name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter academy name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter phone' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City (optional)',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Admin info
              _SectionLabel('Admin Account'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.errorRed)),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Academy'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: AppTheme.textDark,
      ),
    );
  }
}
