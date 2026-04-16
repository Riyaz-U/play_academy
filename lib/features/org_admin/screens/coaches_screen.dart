import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';

class CoachesScreen extends StatelessWidget {
  const CoachesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coaches = context.watch<CoachProvider>().coaches;
    final branches = context.watch<BranchProvider>().branches;

    return Scaffold(
      appBar: AppBar(title: Text('Coaches (${coaches.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/coaches/add'),
        icon: const Icon(Icons.sports),
        label: const Text('Add Coach'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: coaches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_outlined,
                      size: 72,
                      color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No coaches yet',
                      style: TextStyle(color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/org/coaches/add'),
                    child: const Text('Add First Coach'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: coaches.length,
              itemBuilder: (ctx, i) {
                final c = coaches[i];
                final branch = branches
                    .where((b) => b.id == c.branchId)
                    .firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.accentAmber.withValues(alpha: 0.15),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${branch?.name ?? 'Unknown branch'} • ${c.phone}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textGrey),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          context.push('/org/coaches/edit/${c.uid}');
                        } else if (v == 'delete') {
                          final ok = await _confirmDelete(context);
                          if (ok && context.mounted) {
                            context
                                .read<CoachProvider>()
                                .deleteCoach(c.uid);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style:
                                  TextStyle(color: AppTheme.errorRed)),
                        ),
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
            title: const Text('Delete Coach'),
            content: const Text('This will permanently delete the coach account.'),
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
