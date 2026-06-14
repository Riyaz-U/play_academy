import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/session_card.dart';

enum _Filter { upcoming, past, all }

class PlayerScheduleScreen extends StatefulWidget {
  const PlayerScheduleScreen({super.key});

  @override
  State<PlayerScheduleScreen> createState() => _PlayerScheduleScreenState();
}

class _PlayerScheduleScreenState extends State<PlayerScheduleScreen> {
  _Filter _filter = _Filter.upcoming;

  @override
  Widget build(BuildContext context) {
    final allSessions = context.watch<SessionProvider>().sessions;

    final filtered = switch (_filter) {
      _Filter.upcoming =>
        allSessions.where((s) => s.isUpcoming && !s.isCompleted).toList(),
      _Filter.past =>
        allSessions.where((s) => !s.isUpcoming || s.isCompleted).toList(),
      _Filter.all => allSessions,
    };

    // Sort: upcoming → ascending, past → descending
    if (_filter == _Filter.upcoming) {
      filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else {
      filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Schedule (${filtered.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/player/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: _Filter.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_label(f)),
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
                        Icon(Icons.calendar_month_outlined,
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        Text(
                          _filter == _Filter.upcoming
                              ? 'No upcoming sessions'
                              : 'No sessions found',
                          style:
                              const TextStyle(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      final showDateHeader = i == 0 ||
                          !_sameMonth(
                              filtered[i - 1].dateTime, s.dateTime);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                DateFormat('MMMM yyyy').format(s.dateTime),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textDark),
                              ),
                            ),
                          SessionCard(
                            session: s,
                            showHighlights: s.isCompleted &&
                                s.highlights != null &&
                                s.highlights!.isNotEmpty,
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

  String _label(_Filter f) => switch (f) {
        _Filter.upcoming => 'Upcoming',
        _Filter.past => 'Past',
        _Filter.all => 'All',
      };

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
