import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/video_analysis_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/video_provider.dart';

class VideoAnalysisScreen extends StatelessWidget {
  const VideoAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videos = context.watch<VideoProvider>().videos;
    final loading = context.watch<VideoProvider>().loading;
    final role = context.read<AuthProvider>().userModel?.role;
    final canEdit =
        role == AppConstants.roleOrgAdmin || role == AppConstants.roleCoach;

    return Scaffold(
      appBar: AppBar(title: const Text('Video Analysis')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadSheet(context),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Add Footage'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? _EmptyState(canEdit: canEdit, onAdd: () => _showUploadSheet(context))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: videos.length,
                  itemBuilder: (ctx, i) => _VideoCard(
                    video: videos[i],
                    canEdit: canEdit,
                    onDelete: () => _confirmDelete(context, videos[i]),
                    onTap: () => context.push(
                        '/coach/video/${videos[i].id}',
                        extra: videos[i]),
                  ),
                ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _UploadSheet(),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VideoAnalysisModel video) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Delete "${video.title}"? This cannot be undone.'),
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
      context.read<VideoProvider>().deleteVideo(video.id);
    }
  }
}

// ── Video Card ───────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoAnalysisModel video;
  final bool canEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.canEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.play_circle_outline,
              color: AppTheme.primaryGreen, size: 26),
        ),
        title: Text(video.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (video.category != null && video.category!.isNotEmpty)
              Text(video.category!,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGrey)),
            Text(
              DateFormat('d MMM yyyy').format(video.createdAt),
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textGrey),
            ),
          ],
        ),
        trailing: canEdit
            ? IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppTheme.errorRed),
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right, color: AppTheme.textGrey),
        onTap: onTap,
      ),
    );
  }
}

// ── Upload Sheet ─────────────────────────────────────────

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text('Upload Match Footage',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Video URL *',
                hintText: 'https://example.com/video.mp4',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                hintText: 'e.g. U15 Match vs City Academy',
              ),
              textCapitalization: TextCapitalization.sentences,
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
                  : const Text('Create Analysis'),
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
    await context.read<VideoProvider>().addVideo({
      'title': _titleCtrl.text.trim(),
      'videoUrl': _urlCtrl.text.trim(),
      if (_categoryCtrl.text.trim().isNotEmpty)
        'category': _categoryCtrl.text.trim(),
      'uploadedBy': auth.uid,
      'uploadedByName': auth.name,
      'organizationId': auth.organizationId,
      'branchId': auth.branchId ?? '',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
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
            Icon(Icons.videocam_outlined,
                size: 72, color: Colors.grey.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            const Text('No footage yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Upload match or training footage to start adding annotations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            if (canEdit) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Add First Video'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
