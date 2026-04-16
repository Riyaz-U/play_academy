import 'package:flutter/material.dart';
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
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allPlayers = context.watch<PlayerProvider>().players;
    final filtered = _selectedCategory == null
        ? allPlayers
        : allPlayers.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Players (${filtered.length})')),
      body: Column(
        children: [
          // Category filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...AppConstants.categories.map((c) => _Chip(
                        label: c,
                        selected: _selectedCategory == c,
                        onTap: () =>
                            setState(() => _selectedCategory = c),
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
                            color: Colors.grey.withValues(alpha: 0.4)),
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
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.1),
                            child: Text('#${p.jerseyNumber}',
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${p.position} • Age ${p.age}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGrey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(p.category,
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
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
