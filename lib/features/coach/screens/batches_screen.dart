import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/batch_model.dart';
import '../../../models/player_model.dart';
import '../../../models/sport_profile_model.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/firestore_service.dart';

class BatchesScreen extends StatelessWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batches = context.watch<BatchProvider>().batches;

    final Map<String, List<BatchModel>> grouped = {};
    for (final b in batches) {
      grouped.putIfAbsent(b.sport, () => []).add(b);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coach/batches/add'),
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
                for (final sport in grouped.keys) ...[
                  _SportHeader(sport: sport),
                  for (final batch in grouped[sport]!)
                    _BatchTile(batch: batch),
                ],
              ],
            ),
    );
  }
}

class _SportHeader extends StatelessWidget {
  final String sport;
  const _SportHeader({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        sport[0].toUpperCase() + sport.substring(1),
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  final BatchModel batch;
  const _BatchTile({required this.batch});

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerProvider>().players;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          batch.name.isNotEmpty ? batch.name[0].toUpperCase() : 'B',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(batch.name),
      subtitle: Text(batch.category),
      onTap: () => _showMembersSheet(context, players),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Manage players',
            onPressed: () => _showMembersSheet(context, players),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/coach/batches/edit/${batch.id}');
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete batch?'),
                    content:
                        Text('Delete "${batch.name}"? This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<BatchProvider>().deleteBatch(batch.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _showMembersSheet(
      BuildContext context, List<PlayerModel> branchPlayers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BatchMembersSheet(
        batch: batch,
        branchPlayers: branchPlayers,
      ),
    );
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

  // Returns a map of playerId → SportProfileModel for this batch's sport
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
      builder: (_, scrollCtrl) => StreamBuilder<Map<String, SportProfileModel>>(
        stream: _profilesStream(),
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? {};

          // Only show players who have a sport profile for this sport
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
                                  color:
                                      Theme.of(context).colorScheme.outline)),
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
                        ? 'No players enrolled in ${widget.batch.sport} yet.\nEnroll players in this sport first.'
                        : 'No players found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline),
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
                            : (_) =>
                                _toggle(player.uid, profile, !inBatch),
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
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
