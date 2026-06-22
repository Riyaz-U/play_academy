import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'location_picker_screen.dart';

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

  LatLng? _pickedLocation;

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
          if (branch.latitude != null && branch.longitude != null) {
            _pickedLocation = LatLng(branch.latitude!, branch.longitude!);
          }
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

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _pickedLocation?.latitude,
          initialLng: _pickedLocation?.longitude,
        ),
      ),
    );
    if (result != null) {
      setState(() => _pickedLocation = result);
    }
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
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
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
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  prefixIcon: Icon(Icons.account_tree),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter branch name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country *',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter country' : null,
              ),
              const SizedBox(height: 20),

              // ── Map location picker ───────────────────────────────────
              const Text('Map Location',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openMapPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pickedLocation != null
                          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _pickedLocation == null
                      ? Row(
                          children: [
                            Icon(Icons.map_outlined,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 10),
                            const Text('Tap to pick location on map',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 14)),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.location_pin,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Location selected',
                                      style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AppTheme.textGrey),
                              onPressed: _openMapPicker,
                              tooltip: 'Change',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppTheme.textGrey),
                              onPressed: () =>
                                  setState(() => _pickedLocation = null),
                              tooltip: 'Remove',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                ),
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
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Branch',
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.onPrimary),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
