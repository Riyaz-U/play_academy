import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/guardian_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddEditGuardianScreen extends StatefulWidget {
  final String? guardianId;
  const AddEditGuardianScreen({super.key, this.guardianId});

  @override
  State<AddEditGuardianScreen> createState() => _AddEditGuardianScreenState();
}

class _AddEditGuardianScreenState extends State<AddEditGuardianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool get _isEditing => widget.guardianId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final g = context
            .read<GuardianProvider>()
            .guardians
            .where((g) => g.uid == widget.guardianId)
            .firstOrNull;
        if (g != null) {
          _nameCtrl.text = g.name;
          _emailCtrl.text = g.email;
          _phoneCtrl.text = g.phone;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GuardianProvider>();
    final auth = context.read<AuthProvider>().userModel!;
    bool success;

    if (_isEditing) {
      success = await provider.updateGuardian(
        uid: widget.guardianId!,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
    } else {
      success = await provider.createGuardian(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        organizationId: auth.organizationId,
        adminUid: auth.uid,
      );

      if (success && mounted) {
        await context.read<InvitationProvider>().sendInvite(
              email: _emailCtrl.text.trim(),
              role: AppConstants.roleGuardian,
              organizationId: auth.organizationId,
              name: _nameCtrl.text.trim().isEmpty
                  ? null
                  : _nameCtrl.text.trim(),
              adminUid: auth.uid,
            );
      }
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Guardian updated'
            : 'Invitation sent to ${_emailCtrl.text.trim()}'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuardianProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Guardian' : 'Invite Guardian'),
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
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter phone' : null,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Invitation',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An email with a sign-in link will be sent to the guardian.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Guardian Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
              ],
              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(provider.error!,
                    style: const TextStyle(color: AppTheme.errorRed)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _save,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Send Invitation',
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.onPrimary),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
