import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/badge_model.dart';
import '../../models/player_model.dart';
import '../../models/sport_profile_model.dart';
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

  List<SportProfileModel> _profiles = [];
  String? _selectedSport;
  StreamSubscription<List<SportProfileModel>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _profileSub = _fs
        .streamSportProfiles(widget.playerId)
        .listen((profiles) => setState(() {
              _profiles = profiles;
              _selectedSport ??=
                  profiles.isNotEmpty ? profiles.first.sport : null;
            }));
  }

  @override
  void dispose() {
    _tab.dispose();
    _profileSub?.cancel();
    super.dispose();
  }

  SportProfileModel? get _selectedProfile =>
      _profiles.where((p) => p.sport == _selectedSport).firstOrNull;

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
    final canEdit = role == AppConstants.roleOrgAdmin ||
        role == AppConstants.roleCoach;
    final profile = _selectedProfile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: _profiles.length > 1 ? 230 : 200,
            pinned: true,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppTheme.onPrimary),
              onPressed: () => context.go(widget.backRoute),
            ),
            actions: canEdit
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.onPrimary),
                      tooltip: 'Edit',
                      onPressed: () => context
                          .push('${widget.backRoute}/edit/${player.uid}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.onPrimary),
                      tooltip: 'Delete',
                      onPressed: () =>
                          _confirmDelete(context, player),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _PlayerHeader(
                player: player,
                profile: profile,
                profiles: _profiles,
                selectedSport: _selectedSport,
                onSportChanged: (s) =>
                    setState(() => _selectedSport = s),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withAlpha(200),
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
            _OverviewTab(profile: profile, sport: _selectedSport),
            _HistoryTab(
                player: player,
                fs: _fs,
                canEdit: canEdit,
                sport: _selectedSport,
                profiles: _profiles),
            _BadgesTab(player: player, fs: _fs, canEdit: canEdit),
            _InfoTab(player: player),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PlayerModel player) async {
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10)),
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

// ── Player Header ─────────────────────────────────────────────────────────────

class _PlayerHeader extends StatelessWidget {
  final PlayerModel player;
  final SportProfileModel? profile;
  final List<SportProfileModel> profiles;
  final String? selectedSport;
  final ValueChanged<String> onSportChanged;

  const _PlayerHeader({
    required this.player,
    required this.profile,
    required this.profiles,
    required this.selectedSport,
    required this.onSportChanged,
  });

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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.onPrimary.withValues(alpha: 0.7),
                      width: 2),
                ),
                child: Center(
                  child: profile != null
                      ? Text(
                          '#${profile!.jerseyNumber}',
                          style: TextStyle(
                              color: AppTheme.onPrimary
                                  .withValues(alpha: 0.9),
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        )
                      : Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppTheme.onPrimary,
                              fontSize: 28,
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
                            color: AppTheme.onPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      profile != null
                          ? '${profile!.position} • ${profile!.category} • Age ${player.age}'
                          : 'Age ${player.age}',
                      style: TextStyle(
                          color: AppTheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                    if (profile != null) ...[
                      const SizedBox(height: 8),
                      _OverallChip(overall: profile!.overall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Sport selector chips
          if (profiles.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: profiles.map((p) {
                  final selected = p.sport == selectedSport;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSportChanged(p.sport),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.onPrimary.withValues(alpha: 0.25)
                              : AppTheme.onPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? AppTheme.onPrimary
                                  : AppTheme.onPrimary
                                      .withValues(alpha: 0.3),
                              width: selected ? 1.5 : 1),
                        ),
                        child: Text(
                          p.sport[0].toUpperCase() + p.sport.substring(1),
                          style: TextStyle(
                              color: AppTheme.onPrimary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
        color: AppTheme.onPrimary.withValues(alpha: 0.25),
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
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final SportProfileModel? profile;
  final String? sport;
  const _OverviewTab({required this.profile, required this.sport});

  static const List<Color> _statColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.amber,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    if (profile == null || sport == null) {
      return const Center(
        child: Text('No sport enrollment found',
            style: TextStyle(color: AppTheme.textGrey)),
      );
    }

    final statKeys = AppConstants.sportStats[sport] ?? [];
    final stats = profile!.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar chart card
          if (statKeys.length >= 3)
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
                            final label = index < statKeys.length
                                ? statKeys[index]
                                    .substring(0, 3)
                                    .toUpperCase()
                                : '';
                            return RadarChartTitle(
                                text: label, angle: angle);
                          },
                          dataSets: [
                            RadarDataSet(
                              dataEntries: statKeys
                                  .map((k) => RadarEntry(
                                      value:
                                          (stats[k] ?? 50).toDouble()))
                                  .toList(),
                              fillColor: AppTheme.primaryGreen
                                  .withValues(alpha: 0.2),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attributes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  ...statKeys.asMap().entries.map((e) => _StatBar(
                        label: e.value[0].toUpperCase() +
                            e.value.substring(1),
                        value: stats[e.value] ?? 50,
                        color: _statColors[
                            e.key % _statColors.length],
                      )),
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
  const _StatBar(
      {required this.label, required this.value, required this.color});

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

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final PlayerModel player;
  final FirestoreService fs;
  final bool canEdit;
  final String? sport;
  final List<SportProfileModel> profiles;

  const _HistoryTab({
    required this.player,
    required this.fs,
    required this.canEdit,
    required this.sport,
    required this.profiles,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StatsHistoryModel>>(
      stream: fs.streamStatsHistory(player.uid),
      builder: (context, snap) {
        final allEntries = snap.data ?? [];
        final entries = sport != null
            ? allEntries.where((e) => e.sport == sport).toList()
            : allEntries;
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          floatingActionButton: canEdit && sport != null
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddHistorySheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.onPrimary,
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
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final e = entries[i];
                        return _HistoryCard(
                          entry: e,
                          canDelete: canEdit,
                          onDelete: () =>
                              fs.deleteStatsHistory(player.uid, e.id),
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddHistorySheet(
        player: player,
        fs: fs,
        profiles: profiles,
        initialSport: sport!,
      ),
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
    final overall = s.isEmpty
        ? 0.0
        : s.values.reduce((a, b) => a + b) / s.length;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy').format(entry.recordedAt),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (entry.sport.isNotEmpty)
                      Text(
                        entry.sport[0].toUpperCase() +
                            entry.sport.substring(1),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textGrey),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'OVR ${overall.toStringAsFixed(0)}',
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
              children: s.entries
                  .map((e) => _MiniStat(
                        label: e.key
                            .substring(0, 3)
                            .toUpperCase(),
                        value: e.value,
                      ))
                  .toList(),
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
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Text('$label $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)),
    );
  }
}

// ── Add History Sheet ─────────────────────────────────────────────────────────

class _AddHistorySheet extends StatefulWidget {
  final PlayerModel player;
  final FirestoreService fs;
  final List<SportProfileModel> profiles;
  final String initialSport;

  const _AddHistorySheet({
    required this.player,
    required this.fs,
    required this.profiles,
    required this.initialSport,
  });

  @override
  State<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends State<_AddHistorySheet> {
  late String _selectedSport;
  late Map<String, int> _stats;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.initialSport;
    _stats = _loadStats(widget.initialSport);
  }

  Map<String, int> _loadStats(String sport) {
    final profile =
        widget.profiles.where((p) => p.sport == sport).firstOrNull;
    final existing = profile?.stats ?? {};
    return Map.from(
        existing.isEmpty ? SportProfileModel.defaultStats(sport) : existing);
  }

  void _switchSport(String sport) => setState(() {
        _selectedSport = sport;
        _stats = _loadStats(sport);
      });

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statKeys = AppConstants.sportStats[_selectedSport] ?? [];
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
          // Sport selector — only shown when player has multiple enrollments
          if (widget.profiles.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.profiles.map((p) {
                  final sel = p.sport == _selectedSport;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                          p.sport[0].toUpperCase() + p.sport.substring(1)),
                      selected: sel,
                      onSelected: (_) => _switchSport(p.sport),
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: sel
                            ? AppTheme.primaryGreen
                            : AppTheme.textGrey,
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedSport[0].toUpperCase() +
                    _selectedSport.substring(1),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.primaryGreen),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...statKeys.map((k) => _SliderRow(
                key: ValueKey('$_selectedSport-$k'),
                label: k[0].toUpperCase() + k.substring(1),
                value: _stats[k] ?? 50,
                onChanged: (v) => setState(() => _stats[k] = v),
              )),
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
      sport: _selectedSport,
      stats: Map.from(_stats),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      recordedAt: DateTime.now(),
    );
    await widget.fs.addStatsHistory(widget.player.uid, entry.toMap());
    await widget.fs.updateSportProfile(
        widget.player.uid, _selectedSport, {'stats': _stats});
    if (mounted) Navigator.pop(context);
  }
}

class _SliderRow extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _SliderRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Only overwrite the field if it doesn't already represent the new value
      // (avoids stomping mid-type when the text and value are already in sync)
      if (int.tryParse(_ctrl.text) != widget.value) {
        _ctrl.text = '${widget.value}';
        _ctrl.selection =
            TextSelection.collapsed(offset: _ctrl.text.length);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(widget.label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textDark)),
          ),
          Expanded(
            child: Slider(
              value: widget.value.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppTheme.primaryGreen,
              onChanged: (v) => widget.onChanged(v.toInt()),
            ),
          ),
          SizedBox(
            width: 48,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) widget.onChanged(n.clamp(0, 100));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badges Tab ────────────────────────────────────────────────────────────────

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
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                          onDelete: () =>
                              fs.deleteBadge(player.uid, b.id),
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AwardBadgeSheet(player: player, fs: fs),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool canDelete;
  final VoidCallback onDelete;

  const _BadgeCard(
      {required this.badge,
      required this.canDelete,
      required this.onDelete});

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
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Award Badge Sheet ─────────────────────────────────────────────────────────

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
                        : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.accentAmber
                            : AppTheme.borderDark,
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
            onPressed:
                (_saving || _selected == null) ? null : () => _award(auth),
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

// ── Info Tab ──────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final PlayerModel player;
  const _InfoTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          _InfoSection(
            title: 'Health Info',
            icon: Icons.health_and_safety_outlined,
            children: [
              _InfoRow(label: 'Height', value: player.health.height),
              _InfoRow(label: 'Weight', value: player.health.weight),
              _InfoRow(
                  label: 'Blood Group',
                  value: player.health.bloodGroup),
              _InfoRow(
                  label: 'Allergies', value: player.health.allergies),
              _InfoRow(
                  label: 'Medications',
                  value: player.health.medications),
            ],
          ),
          const SizedBox(height: 12),
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
                    fontSize: 12, color: AppTheme.textGrey)),
          ),
          Expanded(
            child: Text(display,
                style: TextStyle(
                    fontSize: 13,
                    color: isNull
                        ? AppTheme.textGrey
                        : AppTheme.textDark,
                    fontStyle: isNull
                        ? FontStyle.italic
                        : FontStyle.normal)),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
          Icon(icon, size: 64, color: AppTheme.textSubtle),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
