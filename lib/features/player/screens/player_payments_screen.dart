import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/payment_model.dart';

class PlayerPaymentsScreen extends StatefulWidget {
  const PlayerPaymentsScreen({super.key});

  @override
  State<PlayerPaymentsScreen> createState() => _PlayerPaymentsScreenState();
}

class _PlayerPaymentsScreenState extends State<PlayerPaymentsScreen> {
  bool _showPending = true;

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>();
    final user = context.read<AuthProvider>().userModel;

    final displayed =
        _showPending ? payments.pendingPayments : payments.paidPayments;

    // Show success/error snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<PaymentProvider>();
      if (p.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.successMessage!),
          backgroundColor: AppTheme.successGreen,
        ));
        p.clearMessages();
      } else if (p.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.error!),
          backgroundColor: AppTheme.errorRed,
        ));
        p.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          // Summary banner
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _SummaryTile(
                  label: 'Pending',
                  count: payments.pendingPayments.length,
                  amount: payments.pendingPayments
                      .fold(0.0, (sum, p) => sum + p.amount),
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 12),
                _SummaryTile(
                  label: 'Paid',
                  count: payments.paidPayments.length,
                  amount: payments.paidPayments
                      .fold(0.0, (sum, p) => sum + p.amount),
                  color: AppTheme.successGreen,
                ),
              ],
            ),
          ),
          // Filter tabs
          Container(
            color: AppTheme.cardDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _Tab(
                  label: 'Pending (${payments.pendingPayments.length})',
                  selected: _showPending,
                  onTap: () => setState(() => _showPending = true),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: 'Paid (${payments.paidPayments.length})',
                  selected: !_showPending,
                  onTap: () => setState(() => _showPending = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_outlined,
                            size: 72,
                            color: AppTheme.textSubtle),
                        const SizedBox(height: 12),
                        Text(
                          _showPending
                              ? 'No pending payments'
                              : 'No payment history',
                          style:
                              const TextStyle(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: displayed.length,
                    itemBuilder: (ctx, i) => _PaymentCard(
                      payment: displayed[i],
                      isLoading: payments.isLoading,
                      onPay: displayed[i].isPending || displayed[i].isOverdue
                          ? () {
                              if (user == null) return;
                              context
                                  .read<PaymentProvider>()
                                  .setCurrentPaymentDocId(displayed[i].id);
                              context.read<PaymentProvider>().initiatePayment(
                                    payment: displayed[i],
                                    playerName: user.name,
                                    playerEmail: user.email,
                                  );
                            }
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(fmt.format(amount),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text('$count invoice${count != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? AppTheme.primaryGreen
                    : AppTheme.textGrey)),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isLoading;
  final VoidCallback? onPay;

  const _PaymentCard({
    required this.payment,
    required this.isLoading,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isOverdue = payment.isOverdue ||
        (payment.isPending &&
            payment.dueDate.isBefore(DateTime.now()));

    final (statusColor, statusLabel) = switch (payment.status) {
      AppConstants.paymentPaid => (AppTheme.successGreen, 'Paid'),
      AppConstants.paymentOverdue => (AppTheme.errorRed, 'Overdue'),
      _ => isOverdue
          ? (AppTheme.errorRed, 'Overdue')
          : (AppTheme.warningOrange, 'Pending'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fmt.format(payment.amount),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(
                  payment.isPaid
                      ? 'Paid on ${DateFormat('d MMM yyyy').format(payment.paidAt!)}'
                      : 'Due: ${DateFormat('d MMM yyyy').format(payment.dueDate)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isOverdue && !payment.isPaid
                          ? AppTheme.errorRed
                          : AppTheme.textGrey),
                ),
              ],
            ),
            if (onPay != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onPay,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.payment, size: 18),
                  label: Text(isLoading ? 'Processing...' : 'Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue
                        ? AppTheme.errorRed
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
