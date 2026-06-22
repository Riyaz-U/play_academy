import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/coach_provider.dart';
import '../../../core/theme/app_theme.dart';

class BranchDetailScreen extends StatelessWidget {
  final String branchId;
  const BranchDetailScreen({super.key, required this.branchId});

  @override
  Widget build(BuildContext context) {
    final branch =
        context.watch<BranchProvider>().getBranchById(branchId);

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Branch')),
        body: const Center(child: Text('Branch not found')),
      );
    }

    final players = context
        .watch<PlayerProvider>()
        .players
        .where((p) => p.branchId == branchId)
        .toList();
    final coaches = context
        .watch<CoachProvider>()
        .coaches
        .where((c) => c.branchId == branchId)
        .toList();

    final hasLocation = branch.latitude != null && branch.longitude != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: hasLocation ? 240 : 120,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppTheme.onPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppTheme.onPrimary),
                tooltip: 'Edit',
                onPressed: () =>
                    context.push('/org/branches/edit/$branchId'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                branch.name,
                style: const TextStyle(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              background: hasLocation
                  ? _MapPreview(
                      lat: branch.latitude!,
                      lng: branch.longitude!,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.darkGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status badge ────────────────────────────
                  if (!branch.isActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                AppTheme.errorRed.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Inactive',
                          style: TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),

                  // ── Stats row ────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.people_outline,
                        label: 'Players',
                        value: '${players.length}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.sports_outlined,
                        label: 'Coaches',
                        value: '${coaches.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Location info ────────────────────────────
                  const Text('Location',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: branch.location),
                  if (branch.city.isNotEmpty)
                    _InfoRow(
                        icon: Icons.location_city, label: branch.city),
                  if (branch.country.isNotEmpty)
                    _InfoRow(icon: Icons.flag_outlined, label: branch.country),
                  if (hasLocation)
                    _InfoRow(
                      icon: Icons.my_location,
                      label:
                          '${branch.latitude!.toStringAsFixed(5)}, ${branch.longitude!.toStringAsFixed(5)}',
                    ),

                  // ── Coaches ──────────────────────────────────
                  if (coaches.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Coaches',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 10),
                    ...coaches.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accentAmber
                                  .withValues(alpha: 0.15),
                              child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                    color: AppTheme.accentAmber,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(c.phone,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGrey)),
                            trailing: !c.isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSubtle
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text('Inactive',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textGrey,
                                            fontWeight: FontWeight.w600)),
                                  )
                                : null,
                          ),
                        )),
                  ],

                  // ── Players summary ──────────────────────────
                  if (players.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Players',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark)),
                        TextButton(
                          onPressed: () => context.go('/org/players'),
                          child: const Text('View all',
                              style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: players.take(12).map((p) {
                        return GestureDetector(
                          onTap: () =>
                              context.push('/org/players/${p.uid}'),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen
                                  .withValues(alpha: 0.15),
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryGreen),
                              ),
                            ),
                            label: Text(p.name,
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppTheme.cardDark,
                          ),
                        );
                      }).toList(),
                    ),
                    if (players.length > 12)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${players.length - 12} more',
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map preview (non-interactive) ────────────────────────────────────────────

class _MapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  const _MapPreview({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 14,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.playacademy.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_pin,
                  color: AppTheme.errorRed, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppTheme.textDark)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSubtle),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }
}
