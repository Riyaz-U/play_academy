import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../models/batch_model.dart';
import '../../../models/player_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = AppConstants.sessionTypeTraining;
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 2));
  int _durationMinutes = 90;

  final Set<String> _selectedBatchIds = {};
  final Set<String> _selectedPlayerIds = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _dateTime = DateTime(
            date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day,
            time.hour, time.minute);
      });
    }
  }

  // Derive sport from the first selected batch (all selected batches share same sport)
  String? _derivedSport(List<BatchModel> batches) {
    if (_selectedBatchIds.isEmpty) return null;
    try {
      return batches.firstWhere((b) => _selectedBatchIds.contains(b.id)).sport;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(List<BatchModel> batches) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchIds.isEmpty && _selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one batch or add specific players')));
      return;
    }
    final user = context.read<AuthProvider>().userModel!;
    final success = await context.read<SessionProvider>().createSession(
          title: _titleCtrl.text.trim(),
          type: _type,
          dateTime: _dateTime,
          location: _locationCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          sport: _derivedSport(batches),
          batchIds: _selectedBatchIds.toList(),
          playerIds: _selectedPlayerIds.toList(),
          durationMinutes: _durationMinutes,
          organizationId: user.organizationId,
          branchId: user.branchId ?? '',
          coachUid: user.uid,
          coachName: user.name,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session scheduled!'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final batches = context.watch<BatchProvider>().batches;
    final allPlayers = context.watch<PlayerProvider>().players;

    // Group batches by sport
    final Map<String, List<BatchModel>> batchesBySport = {};
    for (final b in batches) {
      batchesBySport.putIfAbsent(b.sport, () => []).add(b);
    }

    // When a batch is selected, only allow batches of the same sport
    final activeSport = _derivedSport(batches);

    final selectedPlayers =
        allPlayers.where((p) => _selectedPlayerIds.contains(p.uid)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Session'),
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
              // ── Session Type ──────────────────────────────
              const Text('Session Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Training',
                      icon: Icons.fitness_center,
                      selected: _type == AppConstants.sessionTypeTraining,
                      onTap: () =>
                          setState(() => _type = AppConstants.sessionTypeTraining),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'Match',
                      icon: Icons.emoji_events,
                      selected: _type == AppConstants.sessionTypeMatch,
                      onTap: () =>
                          setState(() => _type = AppConstants.sessionTypeMatch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Batch Selection (required) ────────────────
              Row(
                children: [
                  const Text('Batches',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('(optional if players are picked)',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 8),
              if (batches.isEmpty)
                Text('No batches available. Create a batch first.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 13))
              else
                for (final sport in batchesBySport.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 4),
                    child: Text(
                      sport[0].toUpperCase() + sport.substring(1),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: batchesBySport[sport]!.map((b) {
                      final sel = _selectedBatchIds.contains(b.id);
                      // Disable batches of a different sport once one is selected
                      final disabled =
                          activeSport != null && b.sport != activeSport;
                      return FilterChip(
                        label: Text('${b.name} · ${b.category}'),
                        selected: sel,
                        onSelected: disabled
                            ? null
                            : (_) => setState(() {
                                  if (sel) {
                                    _selectedBatchIds.remove(b.id);
                                  } else {
                                    _selectedBatchIds.add(b.id);
                                  }
                                }),
                        selectedColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryGreen,
                        disabledColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        labelStyle: TextStyle(
                            color: disabled
                                ? Theme.of(context).colorScheme.outline
                                : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                ],
              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', prefixIcon: Icon(Icons.title)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // ── Date & Time ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined)),
                        child: Text(DateFormat('d MMM yyyy').format(_dateTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Time',
                            prefixIcon: Icon(Icons.access_time_outlined)),
                        child: Text(DateFormat('h:mm a').format(_dateTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),

              // ── Duration ──────────────────────────────────
              DropdownButtonFormField<int>(
                initialValue: _durationMinutes,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 45, child: Text('45 min')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                  DropdownMenuItem(value: 120, child: Text('2 hours')),
                ],
                onChanged: (v) => setState(() => _durationMinutes = v ?? 90),
              ),
              const SizedBox(height: 12),

              // ── Location ──────────────────────────────────
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 12),

              // ── Notes ─────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),

              // ── Add Specific Players ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Specific Players',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Outside the selected batches',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final picked =
                          await showModalBottomSheet<Set<String>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _PlayerPickerSheet(
                          allPlayers: allPlayers,
                          selectedIds: Set.of(_selectedPlayerIds),
                        ),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _selectedPlayerIds
                            ..clear()
                            ..addAll(picked);
                        });
                      }
                    },
                    child: const Text('Pick Players'),
                  ),
                ],
              ),
              if (selectedPlayers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: selectedPlayers
                      .map((p) => Chip(
                            label: Text(p.name),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(
                                () => _selectedPlayerIds.remove(p.uid)),
                          ))
                      .toList(),
                ),
              ],

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
                  onPressed:
                      provider.isLoading ? null : () => _save(batches),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Schedule Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Player picker bottom sheet ────────────────────────────────────────────────
class _PlayerPickerSheet extends StatefulWidget {
  final List<PlayerModel> allPlayers;
  final Set<String> selectedIds;

  const _PlayerPickerSheet({
    required this.allPlayers,
    required this.selectedIds,
  });

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  late final Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allPlayers
        .where((p) =>
            _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Pick Players',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Done (${_selected.length})'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search players…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No players found'))
                : ListView.builder(
                    controller: controller,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final selected = _selected.contains(p.uid);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (_) => setState(() {
                          if (selected) {
                            _selected.remove(p.uid);
                          } else {
                            _selected.add(p.uid);
                          }
                        }),
                        title: Text(p.name),
                        subtitle: Text('Age ${p.age}',
                            style: const TextStyle(fontSize: 11)),
                        dense: true,
                        activeColor: AppTheme.primaryGreen,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Session type button ───────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryGreen : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
