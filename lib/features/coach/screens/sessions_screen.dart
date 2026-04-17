import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/session_card.dart';

enum _Filter { all, upcoming, completed }

class CoachSessionsScreen extends StatefulWidget {
  const CoachSessionsScreen({super.key});

  @override
  State<CoachSessionsScreen> createState() => _CoachSessionsScreenState();
}

class _CoachSessionsScreenState extends State<CoachSessionsScreen> {
  _Filter _filter = _Filter.upcoming;

  @override
  Widget build(BuildContext context) {
    final allSessions = context.watch<SessionProvider>().sessions;

    final filtered = switch (_filter) {
      _Filter.upcoming =>
        allSessions.where((s) => s.isUpcoming && !s.isCompleted).toList(),
      _Filter.completed =>
        allSessions.where((s) => s.isCompleted).toList(),
      _Filter.all => allSessions,
    };

    return Scaffold(
      appBar: AppBar(title: Text('Sessions (${filtered.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coach/sessions/add'),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: _Filter.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filterLabel(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor:
                              AppTheme.primaryGreen.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: _filter == f
                                ? AppTheme.primaryGreen
                                : AppTheme.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        const Text('No sessions',
                            style: TextStyle(color: AppTheme.textGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      return SessionCard(
                        session: s,
                        actions: [
                          if (!s.isCompleted)
                            TextButton.icon(
                              onPressed: () => context
                                  .push('/coach/sessions/${s.id}/attendance'),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Attendance'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.errorRed, size: 20),
                            onPressed: () async {
                              final ok = await _confirmDelete(context);
                              if (ok && context.mounted) {
                                context
                                    .read<SessionProvider>()
                                    .deleteSession(s.id);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => 'All',
        _Filter.upcoming => 'Upcoming',
        _Filter.completed => 'Completed',
      };

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Session'),
            content: const Text('Delete this session and its attendance records?'),
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
