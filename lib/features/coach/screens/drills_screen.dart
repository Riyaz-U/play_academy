import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/drill_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/drill_provider.dart';

class DrillsScreen extends StatelessWidget {
  const DrillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drills = context.watch<DrillProvider>().drills;
    final loading = context.watch<DrillProvider>().loading;
    final role = context.read<AuthProvider>().userModel?.role;
    final canEdit =
        role == AppConstants.roleOrgAdmin || role == AppConstants.roleCoach;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drills Library'),
      ),
      floatingActionButton: canEdit && drills.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showDrillSheet(context, null),
              icon: const Icon(Icons.add),
              label: const Text('New Drill'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.onPrimary,
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : drills.isEmpty
              ? _EmptyState(canEdit: canEdit, onAdd: () => _showDrillSheet(context, null))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: drills.length,
                  itemBuilder: (ctx, i) => _DrillCard(
                    drill: drills[i],
                    canEdit: canEdit,
                    onEdit: () => _showDrillSheet(context, drills[i]),
                    onDelete: () => _confirmDelete(context, drills[i]),
                  ),
                ),
    );
  }

  void _showDrillSheet(BuildContext context, DrillModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DrillSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DrillModel drill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drill'),
        content: Text('Delete "${drill.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<DrillProvider>().deleteDrill(drill.id);
    }
  }
}

// ── Drill Card ───────────────────────────────────────────

class _DrillCard extends StatelessWidget {
  final DrillModel drill;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DrillCard({
    required this.drill,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = _categoryStyle(drill.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cat.border),
                  ),
                  child: Text(
                    DrillCategory.label(drill.category).toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cat.text,
                        letterSpacing: 0.8),
                  ),
                ),
                const Spacer(),
                if (canEdit) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    color: AppTheme.textGrey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    color: AppTheme.errorRed,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              drill.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              drill.description,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textGrey, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (drill.videoUrl != null && drill.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.play_circle_outline,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Watch Tutorial',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Category Style ───────────────────────────────────────

class _CatStyle {
  final Color bg;
  final Color border;
  final Color text;
  const _CatStyle(
      {required this.bg, required this.border, required this.text});
}

_CatStyle _categoryStyle(String cat) {
  switch (cat) {
    case DrillCategory.technical:
      return _CatStyle(
        bg: const Color(0xFF10B981).withValues(alpha: 0.1),
        border: const Color(0xFF10B981).withValues(alpha: 0.3),
        text: const Color(0xFF10B981),
      );
    case DrillCategory.tactical:
      return _CatStyle(
        bg: Colors.purple.withValues(alpha: 0.1),
        border: Colors.purple.withValues(alpha: 0.3),
        text: Colors.purple.shade400,
      );
    case DrillCategory.physical:
      return _CatStyle(
        bg: AppTheme.accentAmber.withValues(alpha: 0.1),
        border: AppTheme.accentAmber.withValues(alpha: 0.3),
        text: AppTheme.accentAmber,
      );
    default: // mental
      return _CatStyle(
        bg: Colors.cyan.withValues(alpha: 0.1),
        border: Colors.cyan.withValues(alpha: 0.3),
        text: Colors.cyan.shade600,
      );
  }
}

// ── Drill Sheet (Create / Edit) ──────────────────────────

class _DrillSheet extends StatefulWidget {
  final DrillModel? existing;
  const _DrillSheet({this.existing});

  @override
  State<_DrillSheet> createState() => _DrillSheetState();
}

class _DrillSheetState extends State<_DrillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _videoCtrl;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _videoCtrl = TextEditingController(text: e?.videoUrl ?? '');
    _category = e?.category ?? DrillCategory.technical;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Drill' : 'Create New Drill',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Drill Title *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              key: ValueKey(_category),
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: DrillCategory.all
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(DrillCategory.label(c)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Setup, objectives, coaching points…',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Video URL
            TextFormField(
              controller: _videoCtrl,
              decoration: const InputDecoration(
                labelText: 'Video Tutorial Link (optional)',
                hintText: 'https://youtube.com/…',
                prefixIcon: Icon(Icons.play_circle_outline),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update Drill' : 'Save to Library'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>().userModel!;
    final provider = context.read<DrillProvider>();

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      if (_videoCtrl.text.trim().isNotEmpty)
        'videoUrl': _videoCtrl.text.trim(),
      'organizationId': auth.organizationId,
      'branchId': auth.branchId ?? '',
      'createdBy': auth.uid,
      'createdByName': auth.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    if (widget.existing != null) {
      await provider.updateDrill(widget.existing!.id, data);
    } else {
      await provider.addDrill(data);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ── Empty State ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onAdd;
  const _EmptyState({required this.canEdit, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_gymnastics,
                size: 72, color: AppTheme.textSubtle),
            const SizedBox(height: 16),
            const Text(
              'Library is empty',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building your training curriculum by adding your first drill.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            if (canEdit) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Create First Drill', style: TextStyle(color: AppTheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
