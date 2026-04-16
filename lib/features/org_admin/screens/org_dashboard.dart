import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/stat_card.dart';

class OrgDashboard extends StatelessWidget {
  const OrgDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branches = context.watch<BranchProvider>().branches;
    final players = context.watch<PlayerProvider>().players;
    final coaches = context.watch<CoachProvider>().coaches;
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.name ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    Text(
                      user?.name ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Organization Admin',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats
              const Text(
                'Overview',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  StatCard(
                    label: 'Branches',
                    value: '${branches.length}',
                    icon: Icons.account_tree,
                    color: AppTheme.primaryGreen,
                  ),
                  StatCard(
                    label: 'Players',
                    value: '${players.length}',
                    icon: Icons.people,
                    color: Colors.blue.shade600,
                  ),
                  StatCard(
                    label: 'Coaches',
                    value: '${coaches.length}',
                    icon: Icons.sports,
                    color: AppTheme.accentAmber,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_business,
                      label: 'Add Branch',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/org/branches/add'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_add,
                      label: 'Add Player',
                      color: Colors.blue.shade600,
                      onTap: () => context.push('/org/players/add'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.sports,
                      label: 'Add Coach',
                      color: AppTheme.accentAmber,
                      onTap: () => context.push('/org/coaches/add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Branches list
              if (branches.isNotEmpty) ...[
                const Text(
                  'Your Branches',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                ...branches.map((branch) {
                  final branchPlayers =
                      players.where((p) => p.branchId == branch.id).length;
                  final branchCoaches =
                      coaches.where((c) => c.branchId == branch.id).length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_tree,
                            color: AppTheme.primaryGreen, size: 22),
                      ),
                      title: Text(branch.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${branch.city} • $branchPlayers players • $branchCoaches coaches',
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textGrey),
                      onTap: () => context.go('/org/branches'),
                    ),
                  );
                }),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('No branches yet',
                            style: TextStyle(color: AppTheme.textGrey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/org/branches/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Branch'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
