import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../core/theme/app_theme.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final players = context.watch<PlayerProvider>().players;
    final coaches = context.watch<CoachProvider>().coaches;

    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/branches/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: branches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_tree_outlined,
                      size: 72,
                      color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('No branches yet',
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () => context.push('/org/branches/add'),
                      child: const Text('Create First Branch'),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              itemBuilder: (context, i) {
                final branch = branches[i];
                final playerCount =
                    players.where((p) => p.branchId == branch.id).length;
                final coachCount =
                    coaches.where((c) => c.branchId == branch.id).length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree,
                          color: AppTheme.primaryGreen),
                    ),
                    title: Text(branch.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (branch.location.isNotEmpty)
                          Text(branch.location,
                              style: const TextStyle(fontSize: 12)),
                        Text(
                          '${branch.city} • $playerCount players • $coachCount coaches',
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          context.push('/org/branches/edit/${branch.id}');
                        } else if (v == 'delete') {
                          final confirmed = await _confirmDelete(context);
                          if (confirmed && context.mounted) {
                            context.read<BranchProvider>().deleteBranch(branch.id);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: AppTheme.errorRed))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Branch'),
            content: const Text(
                'Are you sure? This will not delete players or coaches in this branch.'),
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
