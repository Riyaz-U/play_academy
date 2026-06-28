import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/batch_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/batch_provider.dart';

class AddEditBatchScreen extends StatefulWidget {
  final String? batchId;
  const AddEditBatchScreen({super.key, this.batchId});

  @override
  State<AddEditBatchScreen> createState() => _AddEditBatchScreenState();
}

class _AddEditBatchScreenState extends State<AddEditBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _sport = AppConstants.sports.first;
  String _category = AppConstants.categories.first;
  bool _saving = false;

  BatchModel? _existing;

  bool get _isEdit => widget.batchId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final batch = context
            .read<BatchProvider>()
            .batches
            .where((b) => b.id == widget.batchId)
            .firstOrNull;
        if (batch != null) {
          setState(() {
            _existing = batch;
            _nameCtrl.text = batch.name;
            _sport = batch.sport;
            _category = batch.category;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<BatchProvider>();
      if (_isEdit && _existing != null) {
        await provider.updateBatch(_existing!.id, name: _nameCtrl.text.trim());
      } else {
        final auth = context.read<AuthProvider>();
        await provider.createBatch(
          name: _nameCtrl.text.trim(),
          sport: _sport,
          category: _category,
          branchId: auth.userModel?.branchId ?? '',
          organizationId: auth.userModel?.organizationId ?? '',
          createdBy: auth.userModel?.uid ?? '',
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Batch' : 'New Batch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Batch Name',
                hintText: 'e.g. U13 Morning, Senior Evening',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              DropdownButtonFormField<String>(
                initialValue: _sport,
                decoration: const InputDecoration(labelText: 'Sport'),
                items: AppConstants.sports
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s[0].toUpperCase() + s.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _sport = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 8),
              Text(
                'Sport and category cannot be changed after creation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save Changes' : 'Create Batch'),
            ),
          ],
        ),
      ),
    );
  }
}
