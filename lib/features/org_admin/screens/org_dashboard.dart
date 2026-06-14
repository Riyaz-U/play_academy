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
    final players = context.watch<PlayerProvider>().players;
    final coaches = context.watch<CoachProvider>().coaches;
    final user = auth.userModel;

    // Players per branch
    final playersPerBranch = {
      for (final b in branches)
        b.id: players.where((p) => p.branchId == b.id).length,
    };

    // Players by category
    final categoryMap = <String, int>{};
    for (final p in players) {
      categoryMap[p.category] = (categoryMap[p.category] ?? 0) + 1;
    }
    final categories = categoryMap.entries.toList()
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
                            label: 'Categories',
                            value: '${categoryMap.length}',
                            icon: Icons.category,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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

              // Players by category pie chart
              if (categories.isNotEmpty) ...[
                _SectionHeader(title: 'Players by Category'),
                const SizedBox(height: 12),
                _CategoryPieChart(categories: categories),
                const SizedBox(height: 24),
              ],

              // Quick Actions
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
                    onTap: () => context.go('/org/branches'),
                  );
                }),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            size: 64, color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text('No branches yet',
                            style: TextStyle(color: AppTheme.textGrey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/org/branches/add'),
                          icon: const Icon(Icons.add),
                          label: const Padding(
                            padding: EdgeInsets.only(right: 16, top: 10, bottom: 10),
                            child: Text('Create First Branch', style: TextStyle(fontSize: 14, color: AppTheme.onPrimary)),
                          ),
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
          Text('Welcome back,',
              style: TextStyle(
                  color: AppTheme.onPrimary, fontSize: 14)),
          Text(
            name,
            style: const TextStyle(
                color: AppTheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
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
