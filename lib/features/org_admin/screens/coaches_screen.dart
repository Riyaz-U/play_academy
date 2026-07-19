import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../core/theme/app_theme.dart';

class CoachesScreen extends StatelessWidget {
  const CoachesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coaches = context.watch<CoachProvider>().coaches;
    final branches = context.watch<BranchProvider>().branches;

    final pendingCount =
        context.watch<InvitationProvider>().pendingInvitations.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Coaches (${coaches.length})'),
        actions: [_InvitesBadge(count: pendingCount)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/coaches/add'),
        icon: const Icon(Icons.sports),
        label: const Text('Add Coach'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
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
                  Padding(padding:  const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () => context.push('/org/coaches/add'),
                      child: const Text('Add First Coach', style: TextStyle(color: AppTheme.onPrimary)),
                    ),
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
                return Opacity(
                  opacity: c.isActive ? 1.0 : 0.55,
                  child: Card(
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (!c.isActive)
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
                        '${branch?.name ?? 'Unknown branch'} • ${c.phone}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGrey),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            context.push('/org/coaches/edit/${c.uid}');
                          } else if (v == 'toggle_active') {
                            context
                                .read<CoachProvider>()
                                .setActive(c.uid, !c.isActive);
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
                          PopupMenuItem(
                            value: 'toggle_active',
                            child:
                                Text(c.isActive ? 'Deactivate' : 'Activate'),
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

class _InvitesBadge extends StatelessWidget {
  final int count;
  const _InvitesBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.mail_outline),
          tooltip: 'Invitations',
          onPressed: () => context.push('/org/invitations'),
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppTheme.warningOrange,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
