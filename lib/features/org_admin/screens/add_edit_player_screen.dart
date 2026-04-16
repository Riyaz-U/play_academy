import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddEditPlayerScreen extends StatefulWidget {
  final String? playerId;
  const AddEditPlayerScreen({super.key, this.playerId});

  @override
  State<AddEditPlayerScreen> createState() => _AddEditPlayerScreenState();
}

class _AddEditPlayerScreenState extends State<AddEditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _position = AppConstants.positions.first;
  String _category = AppConstants.categories[2]; // U17
  String? _branchId;
  bool _obscure = true;
  bool get _isEditing => widget.playerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = context
            .read<PlayerProvider>()
            .players
            .where((p) => p.uid == widget.playerId)
            .firstOrNull;
        if (p != null) {
          _nameCtrl.text = p.name;
          _emailCtrl.text = p.email;
          _ageCtrl.text = p.age.toString();
          _jerseyCtrl.text = p.jerseyNumber.toString();
          _phoneCtrl.text = p.phone;
          setState(() {
            _position = p.position;
            _category = p.category;
            _branchId = p.branchId;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ageCtrl.dispose();
    _jerseyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branchId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a branch')));
      return;
    }

    final provider = context.read<PlayerProvider>();
    final adminUid = context.read<AuthProvider>().userModel!.uid;
    final orgId = context.read<AuthProvider>().userModel!.organizationId;

    bool success;
    if (_isEditing) {
      success = await provider.updatePlayer(
        uid: widget.playerId!,
        name: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        position: _position,
        jerseyNumber: int.tryParse(_jerseyCtrl.text) ?? 0,
        phone: _phoneCtrl.text.trim(),
        category: _category,
        branchId: _branchId!,
      );
    } else {
      success = await provider.createPlayer(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        position: _position,
        jerseyNumber: int.tryParse(_jerseyCtrl.text) ?? 0,
        phone: _phoneCtrl.text.trim(),
        category: _category,
        organizationId: orgId,
        branchId: _branchId!,
        adminUid: adminUid,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Player updated successfully'
            : 'Player account created'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final provider = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Player' : 'Add Player'),
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
              _Label('Personal Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
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
                          prefixIcon: Icon(Icons.phone)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter phone' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter age';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _Label('Academy Details'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_position),
                      initialValue: _position,
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: AppConstants.positions
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _position = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_category),
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: AppConstants.categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jerseyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Jersey #',
                          prefixIcon: Icon(Icons.sports_soccer)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter jersey #';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_branchId),
                      initialValue: _branchId,
                      decoration: const InputDecoration(labelText: 'Branch'),
                      hint: const Text('Select'),
                      items: branches
                          .map((b) => DropdownMenuItem(
                              value: b.id, child: Text(b.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _branchId = v),
                      validator: (v) =>
                          v == null ? 'Select branch' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!_isEditing) ...[
                _Label('Login Credentials'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share these credentials with the player to login.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(provider.error!,
                      style: const TextStyle(color: AppTheme.errorRed)),
                ),
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
                      : Text(_isEditing ? 'Save Changes' : 'Create Player'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppTheme.textDark));
}
