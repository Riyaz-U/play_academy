import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/player_model.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../services/firestore_service.dart';

class AddEditTeamScreen extends StatefulWidget {
  final String? teamId;
  const AddEditTeamScreen({super.key, this.teamId});

  bool get isEditing => teamId != null;

  @override
  State<AddEditTeamScreen> createState() => _AddEditTeamScreenState();
}

class _AddEditTeamScreenState extends State<AddEditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _sport = AppConstants.sports.first;
  String _search = '';
  Set<String> _selectedPlayerIds = {};
  bool _saving = false;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingMembers = true);
    final team = context.read<TeamProvider>().getById(widget.teamId!);
    if (team == null) {
      setState(() => _loadingMembers = false);
      return;
    }
    _nameCtrl.text = team.name;
    _sport = team.sport;
    final members =
        await FirestoreService().streamTeamMembers(team.id).first;
    setState(() {
      _selectedPlayerIds = members.map((m) => m.playerId).toSet();
      _loadingMembers = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<PlayerModel> get _filteredPlayers {
    final players = context.read<PlayerProvider>().players;
    if (_search.isEmpty) return players.where(  (p) => !_selectedPlayerIds.contains(p.uid)).toList();
    final q = _search.toLowerCase();
    return players.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Team' : 'New Team'),
      ),
      body: _loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        // Team name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Team Name *'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Sport
                        DropdownButtonFormField<String>(
                          initialValue: _sport,
                          decoration: const InputDecoration(labelText: 'Sport'),
                          items: AppConstants.sports
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                        s[0].toUpperCase() + s.substring(1)),
                                  ))
                              .toList(),
                          onChanged: isEdit
                              ? null
                              : (v) => setState(() => _sport = v!),
                        ),
                        const SizedBox(height: 20),

                        // Members section header
                        Row(
                          children: [
                            const Text(
                              'Select Players',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedPlayerIds.length} selected',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Search
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search players…',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Player list
                  Expanded(
                    child: Builder(builder: (context) {
                      final players = _filteredPlayers;
                      if (players.isEmpty) {
                        return const Center(
                          child: Text('No players found',
                              style: TextStyle(color: AppTheme.textGrey)),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: players.length,
                        itemBuilder: (ctx, i) {
                          final p = players[i];
                          final selected = _selectedPlayerIds.contains(p.uid);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selectedPlayerIds.add(p.uid);
                              } else {
                                _selectedPlayerIds.remove(p.uid);
                              }
                            }),
                            title: Text(p.name,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(p.email,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textGrey)),
                            activeColor: AppTheme.primaryGreen,
                            dense: true,
                          );
                        },
                      );
                    }),
                  ),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Update Team' : 'Create Team'),
                    ),
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
    final teamProvider = context.read<TeamProvider>();
    final allPlayers = context.read<PlayerProvider>().players;
    final selectedPlayers =
        allPlayers.where((p) => _selectedPlayerIds.contains(p.uid)).toList();

    bool ok;
    if (widget.isEditing) {
      ok = await teamProvider.updateTeam(widget.teamId!, {
        'name': _nameCtrl.text.trim(),
      });
      if (ok) {
        // Sync members: get current, add new, remove removed
        final currentMembers = await FirestoreService()
            .streamTeamMembers(widget.teamId!)
            .first;
        final currentIds = currentMembers.map((m) => m.playerId).toSet();
        final toAdd = _selectedPlayerIds.difference(currentIds);
        final toRemove = currentIds.difference(_selectedPlayerIds);

        for (final pid in toAdd) {
          final player = allPlayers.firstWhere((p) => p.uid == pid);
          await teamProvider.addMember(widget.teamId!, player, auth.uid);
        }
        for (final pid in toRemove) {
          await teamProvider.removeMember(widget.teamId!, pid);
        }
      }
    } else {
      ok = await teamProvider.createTeam(
        name: _nameCtrl.text.trim(),
        sport: _sport,
        branchId: auth.branchId ?? '',
        organizationId: auth.organizationId,
        createdBy: auth.uid,
        members: selectedPlayers,
      );
    }

    setState(() => _saving = false);
    if (ok && mounted) context.pop();
  }
}
