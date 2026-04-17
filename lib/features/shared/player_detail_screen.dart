import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/badge_model.dart';
import '../../models/player_model.dart';
import '../../models/stats_history_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/firestore_service.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String playerId;
  final String backRoute;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    this.backRoute = '/org/players',
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context
        .watch<PlayerProvider>()
        .players
        .where((p) => p.uid == widget.playerId)
        .firstOrNull;

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Player not found')),
      );
    }

    final role = context.read<AuthProvider>().userModel?.role;
    final canEdit = role == AppConstants.roleOrgAdmin || role == AppConstants.roleCoach;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(widget.backRoute),
            ),
            actions: canEdit
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => context.push(
                          '${widget.backRoute}/edit/${player.uid}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, player),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _PlayerHeader(player: player),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Badges'),
                Tab(text: 'Info'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _OverviewTab(player: player),
            _HistoryTab(player: player, fs: _fs, canEdit: canEdit),
            _BadgesTab(player: player, fs: _fs, canEdit: canEdit),
            _InfoTab(player: player),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PlayerModel player) async {
    final provider = context.read<PlayerProvider>();
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text(
            'Permanently delete ${player.name}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await provider.deletePlayer(player.uid);
      if (mounted) router.go(widget.backRoute);
    }
  }
}

// ── Player Header ───────────────────────────────────────

class _PlayerHeader extends StatelessWidget {
  final PlayerModel player;
  const _PlayerHeader({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Center(
              child: Text(
                '#${player.jerseyNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(player.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${player.position} • ${player.category} • Age ${player.age}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
                const SizedBox(height: 8),
                _OverallChip(overall: player.stats.overall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallChip extends StatelessWidget {
  final double overall;
  const _OverallChip({required this.overall});

  @override
  Widget build(BuildContext context) {
    final color = overall >= 70
        ? Colors.greenAccent
        : overall >= 50
            ? AppTheme.accentAmber
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'OVR ${overall.toStringAsFixed(0)}',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PlayerModel player;
  const _OverviewTab({required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = player.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar chart card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Performance Radar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        tickCount: 4,
                        gridBorderData: BorderSide(
                            color: Colors.grey.shade300, width: 0.5),
                        tickBorderData: BorderSide(
                            color: Colors.grey.shade200, width: 0.5),
                        radarBorderData: BorderSide(
                            color: Colors.grey.shade400, width: 1),
                        titlePositionPercentageOffset: 0.15,
                        titleTextStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark),
                        getTitle: (index, angle) {
                          const labels = [
                            'PAC',
                            'SHO',
                            'PAS',
                            'DRI',
                            'DEF',
                            'PHY'
                          ];
                          return RadarChartTitle(
                              text: labels[index], angle: angle);
                        },
                        dataSets: [
                          RadarDataSet(
                            dataEntries: [
                              RadarEntry(value: stats.pace.toDouble()),
                              RadarEntry(value: stats.shooting.toDouble()),
                              RadarEntry(value: stats.passing.toDouble()),
                              RadarEntry(value: stats.dribbling.toDouble()),
                              RadarEntry(value: stats.defending.toDouble()),
                              RadarEntry(value: stats.physical.toDouble()),
                            ],
                            fillColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderColor: AppTheme.primaryGreen,
                            borderWidth: 2,
                            entryRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stat bars card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Attributes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                  ),
                  const SizedBox(height: 16),
                  _StatBar(label: 'Pace', value: stats.pace, color: Colors.blue.shade600),
                  _StatBar(label: 'Shooting', value: stats.shooting, color: Colors.orange.shade600),
                  _StatBar(label: 'Passing', value: stats.passing, color: AppTheme.primaryGreen),
                  _StatBar(label: 'Dribbling', value: stats.dribbling, color: Colors.purple.shade600),
                  _StatBar(label: 'Defending', value: stats.defending, color: AppTheme.accentAmber),
                  _StatBar(label: 'Physical', value: stats.physical, color: Colors.red.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textDark)),
              Text('$value',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Tab ─────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final PlayerModel player;
  final FirestoreService fs;
  final bool canEdit;
  const _HistoryTab(
      {required this.player, required this.fs, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StatsHistoryModel>>(
      stream: fs.streamStatsHistory(player.uid),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddHistorySheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                )
              : null,
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
                  ? _EmptyState(
                      icon: Icons.history,
                      message: canEdit
                          ? 'No history yet. Add the first entry.'
                          : 'No stats history yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final e = entries[i];
                        return _HistoryCard(
                          entry: e,
                          canDelete: canEdit,
                          onDelete: () => fs.deleteStatsHistory(player.uid, e.id),
                        );
                      },
                    ),
        );
      },
    );
  }

  void _showAddHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddHistorySheet(player: player, fs: fs),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StatsHistoryModel entry;
  final bool canDelete;
  final VoidCallback onDelete;

  const _HistoryCard(
      {required this.entry,
      required this.canDelete,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = entry.stats;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(entry.recordedAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'OVR ${s.overall.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppTheme.errorRed),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _MiniStat(label: 'PAC', value: s.pace),
                _MiniStat(label: 'SHO', value: s.shooting),
                _MiniStat(label: 'PAS', value: s.passing),
                _MiniStat(label: 'DRI', value: s.dribbling),
                _MiniStat(label: 'DEF', value: s.defending),
                _MiniStat(label: 'PHY', value: s.physical),
              ],
            ),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note!,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text('$label $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)),
    );
  }
}

// ── Add History Sheet ───────────────────────────────────

class _AddHistorySheet extends StatefulWidget {
  final PlayerModel player;
  final FirestoreService fs;
  const _AddHistorySheet({required this.player, required this.fs});

  @override
  State<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends State<_AddHistorySheet> {
  late PlayerStats _stats;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stats = widget.player.stats;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add Stats Entry',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 16),
          _SliderRow(
              label: 'Pace', value: _stats.pace,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(pace: v))),
          _SliderRow(
              label: 'Shooting', value: _stats.shooting,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(shooting: v))),
          _SliderRow(
              label: 'Passing', value: _stats.passing,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(passing: v))),
          _SliderRow(
              label: 'Dribbling', value: _stats.dribbling,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(dribbling: v))),
          _SliderRow(
              label: 'Defending', value: _stats.defending,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(defending: v))),
          _SliderRow(
              label: 'Physical', value: _stats.physical,
              onChanged: (v) => setState(() => _stats = _stats.copyWith(physical: v))),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. After camp assessment'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final entry = StatsHistoryModel(
      id: '',
      playerId: widget.player.uid,
      stats: _stats,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      recordedAt: DateTime.now(),
    );
    await widget.fs.addStatsHistory(widget.player.uid, entry.toMap());
    // Also update the player's current stats
    await widget.fs.updatePlayerDoc(widget.player.uid, {'stats': _stats.toMap()});
    if (mounted) Navigator.pop(context);
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _SliderRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppTheme.primaryGreen,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}

// ── Badges Tab ──────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final PlayerModel player;
  final FirestoreService fs;
  final bool canEdit;
  const _BadgesTab(
      {required this.player, required this.fs, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BadgeModel>>(
      stream: fs.streamBadges(player.uid),
      builder: (context, snap) {
        final badges = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  onPressed: () => _showAwardBadgeSheet(context),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Award Badge'),
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.white,
                )
              : null,
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : badges.isEmpty
                  ? _EmptyState(
                      icon: Icons.emoji_events_outlined,
                      message: canEdit
                          ? 'No badges yet. Award the first one!'
                          : 'No badges earned yet.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (ctx, i) {
                        final b = badges[i];
                        return _BadgeCard(
                          badge: b,
                          canDelete: canEdit,
                          onDelete: () => fs.deleteBadge(player.uid, b.id),
                        );
                      },
                    ),
        );
      },
    );
  }

  void _showAwardBadgeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AwardBadgeSheet(player: player, fs: fs),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool canDelete;
  final VoidCallback onDelete;

  const _BadgeCard(
      {required this.badge, required this.canDelete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(badge.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(badge.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppTheme.textDark),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d').format(badge.awardedAt),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          if (canDelete)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: AppTheme.errorRed, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Award Badge Sheet ───────────────────────────────────

class _AwardBadgeSheet extends StatefulWidget {
  final PlayerModel player;
  final FirestoreService fs;
  const _AwardBadgeSheet({required this.player, required this.fs});

  @override
  State<_AwardBadgeSheet> createState() => _AwardBadgeSheetState();
}

class _AwardBadgeSheetState extends State<_AwardBadgeSheet> {
  BadgeType? _selected;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Award Badge',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BadgeType.all.map((bt) {
              final isSelected = _selected?.name == bt.name;
              return GestureDetector(
                onTap: () => setState(() => _selected = bt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentAmber.withValues(alpha: 0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.accentAmber
                            : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(bt.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(bt.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.textDark
                                  : AppTheme.textGrey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Exceptional performance in last match'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_saving || _selected == null) ? null : () => _award(auth),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Award Badge',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _award(AuthProvider auth) async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final badge = BadgeModel(
      id: '',
      playerId: widget.player.uid,
      name: _selected!.name,
      emoji: _selected!.emoji,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      awardedBy: auth.userModel!.uid,
      awardedByName: auth.userModel!.name,
      awardedAt: DateTime.now(),
    );
    await widget.fs.awardBadge(widget.player.uid, badge.toMap());
    if (mounted) Navigator.pop(context);
  }
}

// ── Info Tab ────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final PlayerModel player;
  const _InfoTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Parent contact
          _InfoSection(
            title: 'Parent / Guardian',
            icon: Icons.family_restroom,
            children: [
              _InfoRow(
                  label: 'Name',
                  value: player.parentName,
                  fallback: 'Not provided'),
              _InfoRow(
                  label: 'Phone',
                  value: player.parentPhone,
                  fallback: 'Not provided'),
              _InfoRow(
                  label: 'Email',
                  value: player.parentEmail,
                  fallback: 'Not provided'),
            ],
          ),
          const SizedBox(height: 12),

          // Health info
          _InfoSection(
            title: 'Health Info',
            icon: Icons.health_and_safety_outlined,
            children: [
              _InfoRow(label: 'Height', value: player.health.height),
              _InfoRow(label: 'Weight', value: player.health.weight),
              _InfoRow(
                  label: 'Blood Group', value: player.health.bloodGroup),
              _InfoRow(
                  label: 'Allergies', value: player.health.allergies),
              _InfoRow(
                  label: 'Medications', value: player.health.medications),
            ],
          ),
          const SizedBox(height: 12),

          // Bio
          if (player.bio != null && player.bio!.isNotEmpty)
            _InfoSection(
              title: 'Coaching Notes',
              icon: Icons.notes_outlined,
              children: [
                Text(player.bio!,
                    style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          const SizedBox(height: 12),

          // Contact
          _InfoSection(
            title: 'Contact',
            icon: Icons.contact_page_outlined,
            children: [
              _InfoRow(label: 'Phone', value: player.phone),
              _InfoRow(label: 'Email', value: player.email),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoSection(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? fallback;
  const _InfoRow({required this.label, this.value, this.fallback});

  @override
  Widget build(BuildContext context) {
    final display = (value != null && value!.isNotEmpty)
        ? value!
        : (fallback ?? 'Not provided');
    final isNull = (value == null || value!.isEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey)),
          ),
          Expanded(
            child: Text(display,
                style: TextStyle(
                    fontSize: 13,
                    color: isNull ? AppTheme.textGrey : AppTheme.textDark,
                    fontStyle:
                        isNull ? FontStyle.italic : FontStyle.normal)),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
