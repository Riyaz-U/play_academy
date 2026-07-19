import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../models/invitation_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invitations'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Builder(builder: (ctx) {
              final provider = ctx.watch<InvitationProvider>();
              final pendingCount = provider.pendingInvitations.length;
              return TabBar(tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Accepted'),
                const Tab(text: 'Revoked'),
              ]);
            }),
          ),
        ),
        body: const TabBarView(children: [
          _InviteTab(type: _TabType.pending),
          _InviteTab(type: _TabType.accepted),
          _InviteTab(type: _TabType.revoked),
        ]),
      ),
    );
  }
}

enum _TabType { pending, accepted, revoked }

class _InviteTab extends StatelessWidget {
  final _TabType type;
  const _InviteTab({required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvitationProvider>();
    final branches = context.watch<BranchProvider>().branches;

    final List<InvitationModel> items = switch (type) {
      _TabType.pending => provider.pendingInvitations,
      _TabType.accepted => provider.acceptedInvitations,
      _TabType.revoked => provider.revokedOrExpiredInvitations,
    };

    final emptyLabel = switch (type) {
      _TabType.pending => 'No pending invitations',
      _TabType.accepted => 'No accepted invitations yet',
      _TabType.revoked => 'No revoked invitations',
    };

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 64, color: AppTheme.textSubtle),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: const TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final invite = items[i];
        final branch = branches
            .where((b) => b.id == invite.branchId)
            .firstOrNull;
        return _InviteTile(
          invite: invite,
          branchName: branch?.name,
          showActions: type == _TabType.pending,
        );
      },
    );
  }
}

class _InviteTile extends StatelessWidget {
  final InvitationModel invite;
  final String? branchName;
  final bool showActions;

  const _InviteTile({
    required this.invite,
    this.branchName,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final (roleLabel, roleColor) = _roleStyle(invite.role);
    final isExpired = invite.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Icon(_roleIcon(invite.role),
                      size: 18, color: roleColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.email,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark),
                      ),
                      if (invite.name != null && invite.name!.isNotEmpty)
                        Text(
                          invite.name!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textGrey),
                        ),
                    ],
                  ),
                ),
                // Role chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Meta row ────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (branchName != null)
                  _MetaChip(
                      icon: Icons.account_tree_outlined, label: branchName!),
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label:
                      'Sent ${DateFormat('d MMM').format(invite.invitedAt)}',
                ),
                if (invite.isPending && !isExpired)
                  _MetaChip(
                    icon: Icons.hourglass_bottom_outlined,
                    label:
                        'Expires ${DateFormat('d MMM').format(invite.expiresAt)}',
                    color: _daysLeft(invite.expiresAt) <= 2
                        ? AppTheme.warningOrange
                        : AppTheme.textGrey,
                  ),
                if (isExpired)
                  const _MetaChip(
                    icon: Icons.timer_off_outlined,
                    label: 'Expired',
                    color: AppTheme.errorRed,
                  ),
              ],
            ),

            // ── Actions ─────────────────────────────────
            if (showActions && !isExpired) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionButton(
                    label: 'Resend',
                    icon: Icons.send_outlined,
                    color: AppTheme.primaryGreen,
                    onTap: () async {
                      final ok = await context
                          .read<InvitationProvider>()
                          .resendInvite(invite);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Invitation resent to ${invite.email}'),
                          backgroundColor: AppTheme.successGreen,
                        ));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Revoke',
                    icon: Icons.block_outlined,
                    color: AppTheme.errorRed,
                    onTap: () async {
                      final confirmed = await _confirmRevoke(context);
                      if (confirmed && context.mounted) {
                        context
                            .read<InvitationProvider>()
                            .revokeInvite(invite.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _daysLeft(DateTime expiresAt) =>
      expiresAt.difference(DateTime.now()).inDays;

  (String, Color) _roleStyle(String role) => switch (role) {
        AppConstants.roleCoach => ('Coach', AppTheme.accentAmber),
        AppConstants.roleGuardian => ('Guardian', const Color(0xFF6366F1)),
        _ => ('Player', AppTheme.primaryGreen),
      };

  IconData _roleIcon(String role) => switch (role) {
        AppConstants.roleCoach => Icons.sports,
        AppConstants.roleGuardian => Icons.shield_outlined,
        _ => Icons.person_outlined,
      };

  Future<bool> _confirmRevoke(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Revoke Invitation'),
            content: Text(
                'Revoke the invitation sent to ${invite.email}? They will no longer be able to use the link.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Revoke'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
