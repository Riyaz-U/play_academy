import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/branch_model.dart';

class OrgDashboard extends StatelessWidget {
  const OrgDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branches = context.watch<BranchProvider>().branches;
    final playerProvider = context.watch<PlayerProvider>();
    final players = playerProvider.players;
    final coaches = context.watch<CoachProvider>().coaches;
    final playersBySport = playerProvider.playersBySport;
    final user = auth.userModel;

    // Inactive counts
    final inactivePlayers = players.where((p) => !p.isActive).length;
    final inactiveCoaches = coaches.where((c) => !c.isActive).length;
    final inactiveBranches = branches.where((b) => !b.isActive).length;
    final totalInactive = inactivePlayers + inactiveCoaches + inactiveBranches;

    // Players per branch
    final playersPerBranch = {
      for (final b in branches)
        b.id: players.where((p) => p.branchId == b.id).length,
    };


    // Recent additions (players + coaches merged, newest first)
    final recentMembers = <_RecentMember>[
      ...players.map((p) => _RecentMember(
            uid: p.uid,
            name: p.name,
            branchId: p.branchId,
            createdAt: p.createdAt,
            isPlayer: true,
          )),
      ...coaches.map((c) => _RecentMember(
            uid: c.uid,
            name: c.name,
            branchId: c.branchId,
            createdAt: c.createdAt,
            isPlayer: false,
          )),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentSlice = recentMembers.take(5).toList();

    // Players per branch (sorted for pie chart)
    final branchEntries = playersPerBranch.entries
        .map((e) {
          final branch = branches.where((b) => b.id == e.key).firstOrNull;
          return MapEntry(branch?.name ?? e.key, e.value);
        })
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, color: AppTheme.onPrimary, size: 20),
            ),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: 14),
                    ),
                    const Text(
                      'Academy Admin',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGrey),
                    ),
                  ],
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
              // Welcome banner
              _WelcomeBanner(
                name: user?.name ?? 'Admin',
                playerCount: players.length,
                branchCount: branches.length,
              ),
              const SizedBox(height: 20),

              // Metric cards 2×2
              Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Branches',
                            value: '${branches.length}',
                            icon: Icons.account_tree,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Players',
                            value: '${players.length}',
                            icon: Icons.people,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Coaches',
                            value: '${coaches.length}',
                            icon: Icons.sports,
                            color: AppTheme.neonPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Inactive',
                            value: '$totalInactive',
                            icon: Icons.person_off_outlined,
                            color: totalInactive > 0
                                ? AppTheme.errorRed
                                : AppTheme.accentAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sport breakdown
              if (playersBySport.isNotEmpty) ...[
                _SectionHeader(title: 'Players by Sport'),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (playersBySport.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _SportChip(
                                sport: e.key,
                                count: e.value,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Inactive alerts
              if (totalInactive > 0) ...[
                _SectionHeader(title: 'Attention Needed'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (inactivePlayers > 0)
                      _AlertChip(
                        label: '$inactivePlayers inactive player${inactivePlayers > 1 ? 's' : ''}',
                        icon: Icons.person_off_outlined,
                        onTap: () => context.go('/org/players'),
                      ),
                    if (inactiveCoaches > 0)
                      _AlertChip(
                        label: '$inactiveCoaches inactive coach${inactiveCoaches > 1 ? 'es' : ''}',
                        icon: Icons.sports_outlined,
                        onTap: () => context.go('/org/coaches'),
                      ),
                    if (inactiveBranches > 0)
                      _AlertChip(
                        label: '$inactiveBranches inactive branch${inactiveBranches > 1 ? 'es' : ''}',
                        icon: Icons.account_tree_outlined,
                        onTap: () => context.go('/org/branches'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Players per branch chart
              if (branches.isNotEmpty && players.isNotEmpty) ...[
                _SectionHeader(title: 'Players per Branch'),
                const SizedBox(height: 12),
                _PlayersPerBranchChart(
                  branches: branches,
                  playersPerBranch: playersPerBranch,
                ),
                const SizedBox(height: 24),
              ],

              // Players by branch pie chart
              if (branchEntries.isNotEmpty) ...[
                _SectionHeader(title: 'Players by Branch'),
                const SizedBox(height: 12),
                _CategoryPieChart(categories: branchEntries),
                const SizedBox(height: 24),
              ],

              // Recent additions
              if (recentSlice.isNotEmpty) ...[
                _SectionHeader(title: 'Recent Additions'),
                const SizedBox(height: 10),
                ...recentSlice.map((m) {
                  final branchName = branches
                      .where((b) => b.id == m.branchId)
                      .firstOrNull
                      ?.name ?? '';
                  return _RecentMemberTile(
                    member: m,
                    branchName: branchName,
                    onTap: () => m.isPlayer
                        ? context.push('/org/players/${m.uid}')
                        : null,
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Quick Actions (only shown once academy is fully set up)
              if (branches.isNotEmpty && coaches.isNotEmpty && players.isNotEmpty) ...[
                _SectionHeader(title: 'Quick Actions'),
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
              ],

              // Get started checklist (shown until all 3 steps done)
              if (branches.isEmpty || coaches.isEmpty || players.isEmpty) ...[
                _SectionHeader(
                    title: branches.isEmpty ? 'Get Started' : 'Next Steps'),
                const SizedBox(height: 10),
                _GetStartedCard(
                  steps: [
                    _SetupStep(
                      label: 'Create your first branch',
                      description: 'A branch is a physical location where training happens.',
                      isDone: branches.isNotEmpty,
                      onTap: branches.isEmpty
                          ? () => context.push('/org/branches/add')
                          : null,
                    ),
                    _SetupStep(
                      label: 'Add a coach',
                      description: 'Coaches manage sessions, drills and player progress.',
                      isDone: coaches.isNotEmpty,
                      onTap: branches.isNotEmpty && coaches.isEmpty
                          ? () => context.push('/org/coaches/add')
                          : null,
                    ),
                    _SetupStep(
                      label: 'Add your first player',
                      description: 'Players can log in, track attendance and view stats.',
                      isDone: players.isNotEmpty,
                      onTap: branches.isNotEmpty && players.isEmpty
                          ? () => context.push('/org/players/add')
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Branches list
              if (branches.isNotEmpty) ...[
                _SectionHeader(title: 'Your Branches'),
                const SizedBox(height: 12),
                ...branches.map((branch) {
                  final bp = playersPerBranch[branch.id] ?? 0;
                  final bc =
                      coaches.where((c) => c.branchId == branch.id).length;
                  return _BranchCard(
                    branch: branch,
                    playerCount: bp,
                    coachCount: bc,
                    onTap: () => context.push('/org/branches/${branch.id}'),
                  );
                }),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Welcome Banner ───────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final int playerCount;
  final int branchCount;

  const _WelcomeBanner({
    required this.name,
    required this.playerCount,
    required this.branchCount,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(today,
              style: TextStyle(
                  color: AppTheme.onPrimary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
                color: AppTheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text('Admin Dashboard',
              style: TextStyle(
                  color: AppTheme.onPrimary.withValues(alpha: 0.8),
                  fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _BannerPill(
                  icon: Icons.people,
                  label: '$playerCount players'),
              const SizedBox(width: 8),
              _BannerPill(
                  icon: Icons.account_tree,
                  label: '$branchCount branches'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BannerPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.onPrimary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: AppTheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Metric Cards ─────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark));
  }
}

// ── Players per Branch Bar Chart ─────────────────────────

class _PlayersPerBranchChart extends StatelessWidget {
  final List<BranchModel> branches;
  final Map<String, int> playersPerBranch;

  const _PlayersPerBranchChart({
    required this.branches,
    required this.playersPerBranch,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = playersPerBranch.values
        .fold<int>(0, (m, v) => v > m ? v : m)
        .toDouble();
    final chartMax = (maxVal < 4 ? 4 : maxVal + 2).ceilToDouble();

    final bars = branches
        .asMap()
        .entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (playersPerBranch[e.value.id] ?? 0).toDouble(),
                  color: AppTheme.neonCyan,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            ))
        .toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          barGroups: bars,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final name = branches[group.x].name;
                return BarTooltipItem(
                  '$name\n${rod.toY.toInt()} players',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (chartMax / 4).ceilToDouble(),
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      color: AppTheme.textSubtle, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= branches.length) {
                    return const SizedBox.shrink();
                  }
                  final name = branches[idx].name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 7)}…' : name,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppTheme.borderDark, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// ── Category Pie Chart ───────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final List<MapEntry<String, int>> categories;
  const _CategoryPieChart({required this.categories});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touched = -1;

  static const _palette = [
    AppTheme.neonGreen,
    AppTheme.neonCyan,
    AppTheme.neonPurple,
    AppTheme.accentAmber,
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
    Color(0xFF34D399),
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (_, resp) {
                    setState(() {
                      _touched = resp != null &&
                              resp.touchedSection != null
                          ? resp.touchedSection!.touchedSectionIndex
                          : -1;
                    });
                  },
                ),
                sections: widget.categories.asMap().entries.map((e) {
                  final isTouched = e.key == _touched;
                  final color = _palette[e.key % _palette.length];
                  final pct = total > 0
                      ? (e.value.value / total * 100).toStringAsFixed(1)
                      : '0';
                  return PieChartSectionData(
                    color: color,
                    value: e.value.value.toDouble(),
                    title: isTouched ? '$pct%' : '',
                    radius: isTouched ? 52 : 44,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  );
                }).toList(),
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.categories.asMap().entries.map((e) {
                final color = _palette[e.key % _palette.length];
                final pct = total > 0
                    ? (e.value.value / total * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.key,
                          style: const TextStyle(
                              color: AppTheme.textDark, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${e.value.value} ($pct%)',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branch Card ──────────────────────────────────────────

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final int playerCount;
  final int coachCount;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.playerCount,
    required this.coachCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          '${branch.city} • $playerCount players • $coachCount coaches',
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppTheme.textGrey),
        onTap: onTap,
      ),
    );
  }
}

// ── Recent Member Tile ───────────────────────────────────

class _RecentMemberTile extends StatelessWidget {
  final _RecentMember member;
  final String branchName;
  final VoidCallback? onTap;

  const _RecentMemberTile({
    required this.member,
    required this.branchName,
    this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = member.isPlayer;
    final color = isPlayer ? AppTheme.neonCyan : AppTheme.accentAmber;
    final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(initial,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(member.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          branchName.isNotEmpty ? branchName : '—',
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPlayer ? 'Player' : 'Coach',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(_timeAgo(member.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSubtle)),
          ],
        ),
      ),
    );
  }
}

// ── Get Started Card ─────────────────────────────────────

class _SetupStep {
  final String label;
  final String description;
  final bool isDone;
  final VoidCallback? onTap;
  const _SetupStep({
    required this.label,
    required this.description,
    required this.isDone,
    this.onTap,
  });
}

class _GetStartedCard extends StatelessWidget {
  final List<_SetupStep> steps;
  const _GetStartedCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isLast = i == steps.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: step.onTap,
                borderRadius: BorderRadius.only(
                  topLeft: i == 0 ? const Radius.circular(14) : Radius.zero,
                  topRight: i == 0 ? const Radius.circular(14) : Radius.zero,
                  bottomLeft: isLast ? const Radius.circular(14) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(14) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Step indicator
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isDone
                              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                              : AppTheme.textSubtle.withValues(alpha: 0.12),
                          border: Border.all(
                            color: step.isDone
                                ? AppTheme.primaryGreen
                                : AppTheme.borderDark,
                          ),
                        ),
                        child: step.isDone
                            ? const Icon(Icons.check,
                                size: 16, color: AppTheme.primaryGreen)
                            : Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSubtle))),
                      ),
                      const SizedBox(width: 14),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.label,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: step.isDone
                                      ? AppTheme.textGrey
                                      : AppTheme.textDark,
                                  decoration: step.isDone
                                      ? TextDecoration.lineThrough
                                      : null),
                            ),
                            if (!step.isDone) ...[
                              const SizedBox(height: 2),
                              Text(step.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGrey)),
                            ],
                          ],
                        ),
                      ),
                      // Arrow if actionable
                      if (step.onTap != null)
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppTheme.primaryGreen),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.borderDark,
                    indent: 62),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Recent Member data class ─────────────────────────────

class _RecentMember {
  final String uid;
  final String name;
  final String branchId;
  final DateTime createdAt;
  final bool isPlayer;
  const _RecentMember({
    required this.uid,
    required this.name,
    required this.branchId,
    required this.createdAt,
    required this.isPlayer,
  });
}

// ── Sport Chip ───────────────────────────────────────────

class _SportChip extends StatelessWidget {
  final String sport;
  final int count;
  const _SportChip({required this.sport, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sport[0].toUpperCase() + sport.substring(1),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Chip ───────────────────────────────────────────

class _AlertChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AlertChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.errorRed),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 14, color: AppTheme.errorRed),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ────────────────────────────────────────

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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
