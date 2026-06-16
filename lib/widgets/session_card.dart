import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../core/theme/app_theme.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool showHighlights;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.actions,
    this.showHighlights = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTraining = session.isTraining;
    final color = isTraining ? AppTheme.primaryGreen : AppTheme.accentAmber;
    final icon = isTraining ? Icons.fitness_center : Icons.emoji_events;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(session.dateTime);
    final timeStr = DateFormat('h:mm a').format(session.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          isTraining ? 'Training' : 'Match',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.sport != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryGreen
                                .withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        session.sport![0].toUpperCase() +
                            session.sport!.substring(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (session.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (session.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(timeStr,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 13)),
                ],
              ),
              if (session.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textGrey),
                    const SizedBox(width: 4),
                    Text(
                      session.location,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
              if (showHighlights &&
                  session.highlights != null &&
                  session.highlights!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_outline,
                        size: 14, color: AppTheme.accentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session.highlights!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
