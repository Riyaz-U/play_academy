import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_academy/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/batch_model.dart';
import '../../../models/coach_model.dart';
import '../../../models/sport_profile_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/firestore_service.dart';

class OrgAdminAddEditBatchScreen extends StatefulWidget {
  final String? batchId;
  const OrgAdminAddEditBatchScreen({super.key, this.batchId});

  @override
  State<OrgAdminAddEditBatchScreen> createState() =>
      _OrgAdminAddEditBatchScreenState();
}

class _OrgAdminAddEditBatchScreenState
    extends State<OrgAdminAddEditBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _service = FirestoreService();

  String? _branchId;
  String _sport = AppConstants.sports.first;
  String _category = AppConstants.categories.first;
  List<String> _coachIds = [];
  Set<String> _playerIds = {};
  bool _saving = false;

  BatchModel? _existing;

  bool get _isEdit => widget.batchId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final branches = context.read<BranchProvider>().branches;
      if (!_isEdit && branches.isNotEmpty) {
        setState(() => _branchId = branches.first.id);
      }

      if (_isEdit) {
        final batch = context
            .read<BatchProvider>()
            .batches
            .where((b) => b.id == widget.batchId)
            .firstOrNull;
        if (batch != null) {
          setState(() {
            _existing = batch;
            _nameCtrl.text = batch.name;
            _branchId = batch.branchId;
            _sport = batch.sport;
            _category = batch.category;
            _coachIds = List.from(batch.coachIds);
          });
          // Pre-load players already in this batch
          final profiles = await _service
              .streamSportProfilesByBranch(batch.branchId, batch.sport)
              .first;
          final members = profiles
              .where((p) => p.batchId == batch.id && p.playerId.isNotEmpty)
              .map((p) => p.playerId)
              .toSet();
          if (mounted) setState(() => _playerIds = members);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<CoachModel> _coachesForBranch() {
    if (_branchId == null) return [];
    return context.read<CoachProvider>().getByBranch(_branchId!);
  }

  Future<void> _pickCoaches() async {
    final all = _coachesForBranch();
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No coaches in this branch')),
      );
      return;
    }

    final selected = Set<String>.from(_coachIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Select Coaches',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final coach = all[i];
                    final checked = selected.contains(coach.uid);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) => setSheetState(() {
                        if (v == true) {
                          selected.add(coach.uid);
                        } else {
                          selected.remove(coach.uid);
                        }
                      }),
                      title: Text(coach.name),
                      subtitle: Text(coach.email,
                          style: const TextStyle(fontSize: 12)),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _coachIds = selected.toList());
  }

  Future<void> _pickPlayers() async {
    if (_branchId == null || _branchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a branch first')),
      );
      return;
    }

    final allPlayers = context.read<PlayerProvider>().players;
    final selected = Set<String>.from(_playerIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => StreamBuilder<List<SportProfileModel>>(
            stream: _service.streamSportProfilesByBranch(_branchId!, _sport),
            builder: (context, snapshot) {
              final profiles = snapshot.data ?? [];
              final profileMap = {
                for (final p in profiles)
                  if (p.playerId.isNotEmpty) p.playerId: p
              };

              final eligible = allPlayers
                  .where((p) => profileMap.containsKey(p.uid))
                  .toList();

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Players',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                '${_sport[0].toUpperCase()}${_sport.substring(1)} · ${selected.length} selected',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(ctx).colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  else if (eligible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No players enrolled in ${_sport[0].toUpperCase()}${_sport.substring(1)} at this branch yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(ctx).colorScheme.outline),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: eligible.length,
                        itemBuilder: (_, i) {
                          final player = eligible[i];
                          final profile = profileMap[player.uid];
                          final checked = selected.contains(player.uid);
                          final inOtherBatch =
                              profile?.batchId.isNotEmpty == true &&
                                  profile?.batchId != (_existing?.id ?? '');

                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) => setSheetState(() {
                              if (checked) {
                                selected.remove(player.uid);
                              } else {
                                selected.add(player.uid);
                              }
                            }),
                            title: Text(player.name),
                            subtitle: inOtherBatch
                                ? const Text('In another batch',
                                    style: TextStyle(fontSize: 11))
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
        ),
      ),
    );

    setState(() => _playerIds = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branchId == null || _branchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a branch')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<BatchProvider>();
      if (_isEdit && _existing != null) {
        await provider.updateBatch(
          _existing!.id,
          name: _nameCtrl.text.trim(),
          coachIds: _coachIds,
        );
        await _applyPlayerChanges(_existing!.id, _existing!.branchId, _existing!.sport);
      } else {
        final auth = context.read<AuthProvider>();
        final newId = await provider.createBatch(
          name: _nameCtrl.text.trim(),
          sport: _sport,
          category: _category,
          branchId: _branchId!,
          organizationId: auth.userModel?.organizationId ?? '',
          createdBy: auth.userModel?.uid ?? '',
          coachIds: _coachIds,
        );
        await _applyPlayerChanges(newId, _branchId!, _sport);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applyPlayerChanges(
      String batchId, String branchId, String sport) async {
    // Load all current members of this batch to detect removals
    final profiles =
        await _service.streamSportProfilesByBranch(branchId, sport).first;

    final futures = <Future>[];
    for (final profile in profiles) {
      final pid = profile.playerId;
      if (pid.isEmpty) continue;
      final wantsIn = _playerIds.contains(pid);
      final alreadyIn = profile.batchId == batchId;
      if (wantsIn && !alreadyIn) {
        futures.add(_service.updateSportProfile(pid, sport, {'batchId': batchId}));
      } else if (!wantsIn && alreadyIn) {
        futures.add(_service.updateSportProfile(pid, sport, {'batchId': ''}));
      }
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final coaches = context.watch<CoachProvider>().coaches;
    final players = context.watch<PlayerProvider>().players;

    final selectedCoachNames = coaches
        .where((c) => _coachIds.contains(c.uid))
        .map((c) => c.name)
        .toList();

    final selectedPlayerNames = players
        .where((p) => _playerIds.contains(p.uid))
        .map((p) => p.name)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Batch' : 'New Batch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Branch selector (create only) or read-only label
            if (!_isEdit) ...[
              DropdownButtonFormField<String>(
                initialValue: _branchId,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: branches
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _branchId = v;
                  _coachIds = [];
                  _playerIds = {};
                }),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a branch' : null,
              ),
              const SizedBox(height: 16),
            ] else ...[
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Branch'),
                child: Text(
                  branches
                          .where((b) => b.id == _branchId)
                          .map((b) => b.name)
                          .firstOrNull ??
                      _branchId ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                onChanged: (v) => setState(() {
                  _sport = v!;
                  _playerIds = {};
                }),
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
              const SizedBox(height: 4),
              Text(
                'Sport and category cannot be changed after creation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textDark
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Sport'),
                child: Text(
                  _sport[0].toUpperCase() + _sport.substring(1),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Category'),
                child: Text(
                  _category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Coach picker
            InkWell(
              onTap: _pickCoaches,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Coaches',
                  suffixIcon: Icon(Icons.chevron_right),
                ),
                child: selectedCoachNames.isEmpty
                    ? Text(
                        'No coaches assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textDark
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedCoachNames
                            .map((name) => Chip(
                                  label: Text(name,
                                      style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Player picker
            InkWell(
              onTap: _pickPlayers,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Players',
                  suffixIcon: Icon(Icons.chevron_right),
                ),
                child: selectedPlayerNames.isEmpty
                    ? Text(
                        'No players assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textDark),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedPlayerNames
                            .map((name) => Chip(
                                  label: Text(name,
                                      style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
              ),
            ),
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
