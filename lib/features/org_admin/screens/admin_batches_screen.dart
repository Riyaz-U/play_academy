import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/batch_model.dart';
import '../../../models/player_model.dart';
import '../../../models/sport_profile_model.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/firestore_service.dart';

class AdminBatchesScreen extends StatelessWidget {
  const AdminBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batches = context.watch<BatchProvider>().batches;
    final branches = context.watch<BranchProvider>().branches;

    // Group by branchId, then by sport
    final Map<String, Map<String, List<BatchModel>>> grouped = {};
    for (final b in batches) {
      grouped.putIfAbsent(b.branchId, () => {}).putIfAbsent(b.sport, () => []).add(b);
    }

    String branchName(String id) =>
        branches.firstWhere((b) => b.id == id, orElse: () => branches.first).name;

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/org/batches/add'),
        child: const Icon(Icons.add),
      ),
      body: batches.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_work_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No batches yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + to create your first batch',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final branchId in grouped.keys) ...[
                  if (grouped.length > 1)
                    _SectionHeader(
                      label: branches.any((b) => b.id == branchId)
                          ? branchName(branchId)
                          : branchId,
                      isTop: true,
                    ),
                  for (final sport in grouped[branchId]!.keys) ...[
                    _SectionHeader(
                      label: sport[0].toUpperCase() + sport.substring(1),
                      isTop: false,
                    ),
                    for (final batch in grouped[branchId]![sport]!)
                      _AdminBatchTile(batch: batch),
                  ],
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isTop;
  const _SectionHeader({required this.label, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isTop ? 16 : 8, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isTop
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _AdminBatchTile extends StatelessWidget {
  final BatchModel batch;
  const _AdminBatchTile({required this.batch});

  @override
  Widget build(BuildContext context) {
    final coaches = context.watch<CoachProvider>().coaches;
    final players = context.watch<PlayerProvider>().players;

    final assignedCoaches =
        coaches.where((c) => batch.coachIds.contains(c.uid)).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                batch.name.isNotEmpty ? batch.name[0].toUpperCase() : 'B',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batch.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(batch.category,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (assignedCoaches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: assignedCoaches
                            .map((c) => Chip(
                                  label: Text(c.name,
                                      style: const TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(Icons.sports, size: 14),
                                ))
                            .toList(),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('No coach assigned',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Manage players',
              onPressed: () => _showMembersSheet(context, players),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.push('/org/batches/edit/${batch.id}'),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context, List<PlayerModel> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BatchMembersSheet(batch: batch, branchPlayers: players),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text('Delete "${batch.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<BatchProvider>().deleteBatch(batch.id);
    }
  }
}

// ── Batch members sheet ───────────────────────────────────────────────────────
class _BatchMembersSheet extends StatefulWidget {
  final BatchModel batch;
  final List<PlayerModel> branchPlayers;

  const _BatchMembersSheet({
    required this.batch,
    required this.branchPlayers,
  });

  @override
  State<_BatchMembersSheet> createState() => _BatchMembersSheetState();
}

class _BatchMembersSheetState extends State<_BatchMembersSheet> {
  final _service = FirestoreService();
  final Set<String> _saving = {};
  String _query = '';

  Stream<Map<String, SportProfileModel>> _profilesStream() =>
      _service
          .streamSportProfilesByBranch(
              widget.batch.branchId, widget.batch.sport)
          .map((profiles) => {
                for (final p in profiles)
                  if (p.playerId.isNotEmpty) p.playerId: p
              });

  Future<void> _toggle(
      String playerId, SportProfileModel? profile, bool add) async {
    if (profile == null) return;
    setState(() => _saving.add(playerId));
    try {
      await _service.updateSportProfile(
        playerId,
        widget.batch.sport,
        {'batchId': add ? widget.batch.id : ''},
      );
    } finally {
      if (mounted) setState(() => _saving.remove(playerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) =>
          StreamBuilder<Map<String, SportProfileModel>>(
        stream: _profilesStream(),
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? {};

          final eligible = widget.branchPlayers
              .where((p) => profiles.containsKey(p.uid))
              .where((p) =>
                  _query.isEmpty ||
                  p.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          final memberCount =
              profiles.values.where((p) => p.batchId == widget.batch.id).length;

          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.batch.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                              '${widget.batch.category} · ${widget.batch.sport[0].toUpperCase()}${widget.batch.sport.substring(1)} · $memberCount player${memberCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.outline)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search players…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(height: 4),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    profiles.isEmpty
                        ? 'No players enrolled in ${widget.batch.sport} yet.'
                        : 'No players found.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: eligible.length,
                    itemBuilder: (_, i) {
                      final player = eligible[i];
                      final profile = profiles[player.uid];
                      final inBatch = profile?.batchId == widget.batch.id;
                      final isSaving = _saving.contains(player.uid);

                      return CheckboxListTile(
                        value: inBatch,
                        onChanged: isSaving
                            ? null
                            : (_) => _toggle(player.uid, profile, !inBatch),
                        title: Text(player.name),
                        subtitle: profile?.batchId.isNotEmpty == true &&
                                profile?.batchId != widget.batch.id
                            ? const Text('In another batch',
                                style: TextStyle(fontSize: 11))
                            : null,
                        secondary: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : null,
                        dense: true,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
