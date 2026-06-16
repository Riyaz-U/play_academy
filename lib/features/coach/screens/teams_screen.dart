import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/team_model.dart';
import '../../../models/team_member_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../services/firestore_service.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamProvider>().teams;
    final loading = context.watch<TeamProvider>().isLoading;
    final canEdit = context.read<AuthProvider>().userModel?.role != null;

    // Group teams by sport
    final Map<String, List<TeamModel>> grouped = {};
    for (final t in teams) {
      grouped.putIfAbsent(t.sport, () => []).add(t);
    }
    final sports = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      floatingActionButton: canEdit && teams.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/coach/teams/add'),
              icon: const Icon(Icons.add),
              label: const Text('New Team'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.onPrimary,
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
              ? _EmptyState(onAdd: () => context.push('/coach/teams/add'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: sports.length,
                  itemBuilder: (ctx, si) {
                    final sport = sports[si];
                    final sportTeams = grouped[sport]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (si > 0) const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _SportHeader(sport: sport),
                        ),
                        ...sportTeams.map((t) => _TeamCard(
                              team: t,
                              onEdit: () =>
                                  context.push('/coach/teams/edit/${t.id}'),
                              onDelete: () => _confirmDelete(context, t),
                            )),
                      ],
                    );
                  },
                ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TeamModel team) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Delete "${team.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TeamProvider>().deleteTeam(team.id);
    }
  }
}

// ── Sport Section Header ─────────────────────────────────

class _SportHeader extends StatelessWidget {
  final String sport;
  const _SportHeader({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          sport[0].toUpperCase() + sport.substring(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

// ── Team Card ────────────────────────────────────────────

class _TeamCard extends StatefulWidget {
  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  List<TeamMemberModel> _members = [];
  StreamSubscription<List<TeamMemberModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirestoreService()
        .streamTeamMembers(widget.team.id)
        .listen((list) => setState(() => _members = list));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.team.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_members.length} player${_members.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: widget.onEdit,
              color: AppTheme.textGrey,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: widget.onDelete,
              color: AppTheme.errorRed,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 72, color: AppTheme.textSubtle),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first team to start organising players into squads.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create First Team',
                  style: TextStyle(color: AppTheme.onPrimary)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
