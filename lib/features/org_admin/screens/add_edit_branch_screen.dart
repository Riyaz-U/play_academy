import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddEditBranchScreen extends StatefulWidget {
  final String? branchId;
  const AddEditBranchScreen({super.key, this.branchId});

  @override
  State<AddEditBranchScreen> createState() => _AddEditBranchScreenState();
}

class _AddEditBranchScreenState extends State<AddEditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  bool get _isEditing => widget.branchId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final branch = context
            .read<BranchProvider>()
            .getBranchById(widget.branchId!);
        if (branch != null) {
          _nameCtrl.text = branch.name;
          _locationCtrl.text = branch.location;
          _cityCtrl.text = branch.city;
          _countryCtrl.text = branch.country;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<BranchProvider>();
    bool success;
    if (_isEditing) {
      success = await provider.updateBranch(
        id: widget.branchId!,
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
      );
    } else {
      final orgId =
          context.read<AuthProvider>().userModel?.organizationId ?? '';
      success = await provider.createBranch(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        organizationId: orgId,
      );
    }
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BranchProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Branch' : 'Add Branch'),
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
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  prefixIcon: Icon(Icons.account_tree),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter branch name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter country' : null,
              ),
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
                      : Text(_isEditing ? 'Save Changes' : 'Create Branch', style: TextStyle(fontSize: 14, color: AppTheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
