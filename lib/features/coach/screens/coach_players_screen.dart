import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CoachPlayersScreen extends StatefulWidget {
  const CoachPlayersScreen({super.key});

  @override
  State<CoachPlayersScreen> createState() => _CoachPlayersScreenState();
}

class _CoachPlayersScreenState extends State<CoachPlayersScreen> {
  String? _selectedSport;

  @override
  Widget build(BuildContext context) {
    final allPlayers = context.watch<PlayerProvider>().players;
    final filtered = allPlayers;

    return Scaffold(
      appBar: AppBar(title: Text('Players (${filtered.length})')),
      body: Column(
        children: [
          // Sport filter
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
                        onTap: () =>
                            setState(() => _selectedSport = s),
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
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text('No players found',
                            style: TextStyle(color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => context.push('/coach/players/${p.uid}'),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.1),
                            child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Age ${p.age}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGrey),
                          ),
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
