import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';

class OrgPlayersScreen extends StatefulWidget {
  const OrgPlayersScreen({super.key});

  @override
  State<OrgPlayersScreen> createState() => _OrgPlayersScreenState();
}

class _OrgPlayersScreenState extends State<OrgPlayersScreen> {
  String? _selectedBranchId;

  @override
  Widget build(BuildContext context) {
    final allPlayers = context.watch<PlayerProvider>().players;
    final branches = context.watch<BranchProvider>().branches;

    var filtered = allPlayers;
    if (_selectedBranchId != null) {
      filtered = filtered.where((p) => p.branchId == _selectedBranchId).toList();
    }
    // category filter removed — category now lives in sportProfiles

    return Scaffold(
      appBar: AppBar(
        title: Text('Players (${filtered.length})'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/players/add'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Player'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Branch filter
                if (branches.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Branches',
                          selected: _selectedBranchId == null,
                          onTap: () =>
                              setState(() => _selectedBranchId = null),
                        ),
                        ...branches.map((b) => _FilterChip(
                              label: b.name,
                              selected: _selectedBranchId == b.id,
                              onTap: () =>
                                  setState(() => _selectedBranchId = b.id),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text('No players found',
                            style: TextStyle(color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final branch = context
                          .read<BranchProvider>()
                          .getBranchById(p.branchId);
                      return Opacity(
                        opacity: p.isActive ? 1.0 : 0.55,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => context.push('/org/players/${p.uid}'),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryGreen.withValues(alpha: 0.1),
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                if (!p.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSubtle
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Inactive',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textGrey,
                                            fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'Age ${p.age} • ${branch?.name ?? p.branchId}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textGrey),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  context.push('/org/players/edit/${p.uid}');
                                } else if (v == 'toggle_active') {
                                  context
                                      .read<PlayerProvider>()
                                      .setActive(p.uid, !p.isActive);
                                } else if (v == 'delete') {
                                  final ok = await _confirmDelete(context);
                                  if (ok && context.mounted) {
                                    context
                                        .read<PlayerProvider>()
                                        .deletePlayer(p.uid);
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                  value: 'toggle_active',
                                  child: Text(p.isActive
                                      ? 'Deactivate'
                                      : 'Activate'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style:
                                          TextStyle(color: AppTheme.errorRed)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Player'),
            content: const Text(
                'This will permanently delete the player account. Continue?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryGreen,
        showCheckmark: true,
        labelStyle: TextStyle(
            color: selected ? AppTheme.primaryGreen : AppTheme.textGrey),
      ),
    );
  }
}
