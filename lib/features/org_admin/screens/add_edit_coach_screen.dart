import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddEditCoachScreen extends StatefulWidget {
  final String? coachId;
  const AddEditCoachScreen({super.key, this.coachId});

  @override
  State<AddEditCoachScreen> createState() => _AddEditCoachScreenState();
}

class _AddEditCoachScreenState extends State<AddEditCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _branchId;
  bool get _isEditing => widget.coachId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = context
            .read<CoachProvider>()
            .coaches
            .where((c) => c.uid == widget.coachId)
            .firstOrNull;
        if (c != null) {
          _nameCtrl.text = c.name;
          _emailCtrl.text = c.email;
          _phoneCtrl.text = c.phone;
          setState(() => _branchId = c.branchId);
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
    if (_branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a branch')));
      return;
    }

    final provider = context.read<CoachProvider>();
    final auth = context.read<AuthProvider>().userModel!;
    bool success;

    if (_isEditing) {
      success = await provider.updateCoach(
        uid: widget.coachId!,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        branchId: _branchId!,
      );
    } else {
      success = await provider.createCoach(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        organizationId: auth.organizationId,
        branchId: _branchId!,
        adminUid: auth.uid,
      );

      if (success && mounted) {
        await context.read<InvitationProvider>().sendInvite(
              email: _emailCtrl.text.trim(),
              role: AppConstants.roleCoach,
              organizationId: auth.organizationId,
              branchId: _branchId!,
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
            ? 'Coach updated'
            : 'Invitation sent to ${_emailCtrl.text.trim()}'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final provider = context.watch<CoachProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Coach' : 'Invite Coach'),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_branchId),
                initialValue: _branchId,
                decoration: const InputDecoration(
                    labelText: 'Assign to Branch',
                    prefixIcon: Icon(Icons.account_tree_outlined)),
                hint: const Text('Select Branch'),
                items: branches
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => _branchId = v),
                validator: (v) => v == null ? 'Select branch' : null,
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
                  'An email with a sign-in link will be sent to the coach.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Coach Email',
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
