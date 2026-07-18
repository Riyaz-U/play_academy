import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/guardian_provider.dart';
import '../../../core/theme/app_theme.dart';

class GuardiansScreen extends StatelessWidget {
  const GuardiansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guardians = context.watch<GuardianProvider>().guardians;

    return Scaffold(
      appBar: AppBar(title: Text('Guardians (${guardians.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/guardians/add'),
        icon: const Icon(Icons.shield_outlined),
        label: const Text('Add Guardian'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: guardians.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom,
                      size: 72, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No guardian accounts yet',
                      style: TextStyle(color: AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Create guardian accounts so parents can log in and view their children\'s progress.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/org/guardians/add'),
                    child: const Text('Add First Guardian',
                        style: TextStyle(color: AppTheme.onPrimary)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: guardians.length,
              itemBuilder: (ctx, i) {
                final g = guardians[i];
                return Opacity(
                  opacity: g.isActive ? 1.0 : 0.55,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.15),
                        child: Text(
                          g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                          style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(g.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (!g.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.textSubtle.withValues(alpha: 0.15),
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
                        '${g.email} • ${g.phone}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGrey),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            context.push('/org/guardians/edit/${g.uid}');
                          } else if (v == 'toggle_active') {
                            context
                                .read<GuardianProvider>()
                                .setActive(g.uid, !g.isActive);
                          } else if (v == 'delete') {
                            final ok = await _confirmDelete(context);
                            if (ok && context.mounted) {
                              context
                                  .read<GuardianProvider>()
                                  .deleteGuardian(g.uid);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'toggle_active',
                            child:
                                Text(g.isActive ? 'Deactivate' : 'Activate'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: AppTheme.errorRed)),
                          ),
                        ],
                      ),
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
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Delete Guardian'),
            content: const Text(
                'This will permanently delete the guardian account. Any linked players will be unaffected.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
