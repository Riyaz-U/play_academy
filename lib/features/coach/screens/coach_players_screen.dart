import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../models/sport_profile_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/firestore_service.dart';

class CoachPlayersScreen extends StatefulWidget {
  const CoachPlayersScreen({super.key});

  @override
  State<CoachPlayersScreen> createState() => _CoachPlayersScreenState();
}

class _CoachPlayersScreenState extends State<CoachPlayersScreen> {
  String? _selectedSport;

  // playerId → set of sports the player is enrolled in
  final Map<String, Set<String>> _sportsByPlayer = {};
  StreamSubscription<List<SportProfileModel>>? _profileSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId =
          context.read<AuthProvider>().userModel?.branchId ?? '';
      if (branchId.isEmpty) return;
      _profileSub = FirestoreService()
          .streamAllSportProfilesByBranch(branchId)
          .listen((profiles) {
        final map = <String, Set<String>>{};
        for (final p in profiles) {
          if (p.playerId.isNotEmpty) {
            map.putIfAbsent(p.playerId, () => {}).add(p.sport);
          }
        }
        setState(() {
          _sportsByPlayer
            ..clear()
            ..addAll(map);
        });
      });
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = context.watch<PlayerProvider>().players;

    final filtered = _selectedSport == null
        ? allPlayers
        : allPlayers
            .where((p) =>
                _sportsByPlayer[p.uid]?.contains(_selectedSport) == true)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Players (${filtered.length})')),
      body: Column(
        children: [
          // Sport filter chips
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    label: 'All',
                    selected: _selectedSport == null,
                    onTap: () => setState(() => _selectedSport = null),
                  ),
                  ...AppConstants.sports.map((s) => _Chip(
                        label: s[0].toUpperCase() + s.substring(1),
                        selected: _selectedSport == s,
                        onTap: () => setState(() => _selectedSport = s),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 72, color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        Text(
                          _selectedSport == null
                              ? 'No players found'
                              : 'No players enrolled in ${_selectedSport![0].toUpperCase()}${_selectedSport!.substring(1)}',
                          style: const TextStyle(color: AppTheme.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final sports =
                          (_sportsByPlayer[p.uid] ?? {}).toList()..sort();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () =>
                              context.push('/coach/players/${p.uid}'),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen
                                .withValues(alpha: 0.1),
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: sports.isNotEmpty
                              ? Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: sports
                                      .map((s) => _SportBadge(sport: s))
                                      .toList(),
                                )
                              : Text('Age ${p.age}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGrey)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SportBadge extends StatelessWidget {
  final String sport;
  const _SportBadge({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Text(
        sport[0].toUpperCase() + sport.substring(1),
        style: const TextStyle(
            fontSize: 10,
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
            color: selected ? AppTheme.primaryGreen : AppTheme.textGrey),
      ),
    );
  }
}
