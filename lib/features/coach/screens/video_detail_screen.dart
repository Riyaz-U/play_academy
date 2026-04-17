import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/video_analysis_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/firestore_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoAnalysisModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl));
    await _controller.initialize();
    _controller.addListener(_onPlayerUpdate);
    if (mounted) setState(() => _initialized = true);
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(title: Text(widget.video.title)),
      body: ListView(
        children: [
          // ── Video Player ──────────────────────────────
          _VideoPlayer(
            controller: _controller,
            initialized: _initialized,
          ),
          const SizedBox(height: 12),

          // ── Annotations ───────────────────────────────
          _AnnotationsSection(
            video: widget.video,
            controller: _controller,
          ),
        ],
      ),
    );
  }
}

// ── Video Player Widget ──────────────────────────────────

class _VideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;
  final bool initialized;

  const _VideoPlayer(
      {required this.controller, required this.initialized});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: initialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  // Tap to play/pause
                  GestureDetector(
                    onTap: () {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    },
                    child: AnimatedOpacity(
                      opacity: controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  // Progress bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _ProgressBar(controller: controller),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration;
    final position = controller.value.position;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: AppTheme.primaryGreen,
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white10,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(_formatDuration(duration),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Annotations Section ──────────────────────────────────

class _AnnotationsSection extends StatefulWidget {
  final VideoAnalysisModel video;
  final VideoPlayerController controller;

  const _AnnotationsSection(
      {required this.video, required this.controller});

  @override
  State<_AnnotationsSection> createState() => _AnnotationsSectionState();
}

class _AnnotationsSectionState extends State<_AnnotationsSection> {
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().userModel?.role;
    final canEdit =
        role == AppConstants.roleOrgAdmin || role == AppConstants.roleCoach;

    return Column(
      children: [
        // Add annotation form (coaches/admins only)
        if (canEdit)
          _AddAnnotationForm(
            video: widget.video,
            controller: widget.controller,
            fs: _fs,
          ),

        // Annotations list
        StreamBuilder<List<VideoAnnotation>>(
          stream: _fs.streamAnnotations(widget.video.id),
          builder: (ctx, snap) {
            final annotations = snap.data ?? [];
            if (snap.connectionState == ConnectionState.waiting &&
                annotations.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (annotations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.comment_outlined,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                    const Text('No annotations yet',
                        style: TextStyle(color: AppTheme.textGrey)),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Text('Annotations',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${annotations.length}',
                          style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                ...annotations.map((a) => _AnnotationCard(
                      annotation: a,
                      canEdit: canEdit,
                      onSeek: () => widget.controller
                          .seekTo(Duration(seconds: a.timestamp.toInt())),
                      onDelete: () =>
                          _fs.deleteAnnotation(widget.video.id, a.id),
                    )),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Annotation Card ──────────────────────────────────────

class _AnnotationCard extends StatelessWidget {
  final VideoAnnotation annotation;
  final bool canEdit;
  final VoidCallback onSeek;
  final VoidCallback onDelete;

  const _AnnotationCard({
    required this.annotation,
    required this.canEdit,
    required this.onSeek,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final style = _typeStyle(annotation.type);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Timestamp button
              GestureDetector(
                onTap: onSeek,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow,
                          size: 12, color: AppTheme.primaryGreen),
                      const SizedBox(width: 3),
                      Text(
                        annotation.timestampLabel,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontFeatures: [
                              FontFeature.tabularFigures()
                            ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: style.border),
                ),
                child: Text(
                  AnnotationType.label(annotation.type).toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: style.text,
                      letterSpacing: 0.6),
                ),
              ),
              const Spacer(),
              if (canEdit)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close,
                      size: 16, color: AppTheme.textGrey),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(annotation.note,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textDark,
                  height: 1.4)),
          if (annotation.playerName != null &&
              annotation.playerName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 12, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(annotation.playerName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Add Annotation Form ──────────────────────────────────

class _AddAnnotationForm extends StatefulWidget {
  final VideoAnalysisModel video;
  final VideoPlayerController controller;
  final FirestoreService fs;

  const _AddAnnotationForm(
      {required this.video,
      required this.controller,
      required this.fs});

  @override
  State<_AddAnnotationForm> createState() => _AddAnnotationFormState();
}

class _AddAnnotationFormState extends State<_AddAnnotationForm> {
  final _noteCtrl = TextEditingController();
  String _type = AnnotationType.tactical;
  String? _selectedPlayerId;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerProvider>().players;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Feedback',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              hintText: 'Describe the moment…',
              labelText: 'Note',
              alignLabelWithHint: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_type),
                  initialValue: _type,
                  decoration:
                      const InputDecoration(labelText: 'Type'),
                  items: AnnotationType.all
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(AnnotationType.label(t),
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(_selectedPlayerId),
                  initialValue: _selectedPlayerId,
                  decoration:
                      const InputDecoration(labelText: 'Player'),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('All',
                            style: TextStyle(fontSize: 13))),
                    ...players.map((p) => DropdownMenuItem(
                          value: p.uid,
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedPlayerId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving || _noteCtrl.text.trim().isEmpty
                  ? null
                  : _tag,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Tag Moment'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tag() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>().userModel!;
    final position = widget.controller.value.position;
    final player = _selectedPlayerId == null
        ? null
        : context
            .read<PlayerProvider>()
            .players
            .where((p) => p.uid == _selectedPlayerId)
            .firstOrNull;

    await widget.fs.addAnnotation(widget.video.id, {
      'videoId': widget.video.id,
      'timestamp': position.inSeconds.toDouble(),
      'note': _noteCtrl.text.trim(),
      'type': _type,
      if (_selectedPlayerId != null) 'playerId': _selectedPlayerId,
      if (player != null) 'playerName': player.name,
      'authorUid': auth.uid,
      'authorName': auth.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    _noteCtrl.clear();
    if (mounted) setState(() => _saving = false);
  }
}

// ── Type Style ───────────────────────────────────────────

class _TypeStyle {
  final Color bg;
  final Color border;
  final Color text;
  const _TypeStyle(
      {required this.bg, required this.border, required this.text});
}

_TypeStyle _typeStyle(String type) {
  switch (type) {
    case AnnotationType.tactical:
      return _TypeStyle(
        bg: Colors.purple.withValues(alpha: 0.1),
        border: Colors.purple.withValues(alpha: 0.3),
        text: Colors.purple.shade400,
      );
    case AnnotationType.technical:
      return _TypeStyle(
        bg: Colors.cyan.withValues(alpha: 0.1),
        border: Colors.cyan.withValues(alpha: 0.3),
        text: Colors.cyan.shade600,
      );
    default: // feedback
      return _TypeStyle(
        bg: AppTheme.accentAmber.withValues(alpha: 0.1),
        border: AppTheme.accentAmber.withValues(alpha: 0.3),
        text: AppTheme.accentAmber,
      );
  }
}
