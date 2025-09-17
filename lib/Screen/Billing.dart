import 'package:flutter/material.dart';
import '../Repository/payment_repo.dart';
import '../Models/Payment.dart';
import '../authencation/auth_service.dart';
import '../Screen/invoice.dart';

class Billing extends StatefulWidget {
  const Billing({super.key});

  @override
  State<Billing> createState() => _BillingState();
}

class _BillingState extends State<Billing> {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final AuthService _authService = AuthService();

  List<Payment> _payments = [];
  bool _loading = true;
  String? _error;

  // Statistics
  double _totalOutstanding = 0.0;
  double _paidThisMonth = 0.0;
  double _overdueAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final payments = await _paymentRepo.getPaymentsByUserId(userId);

      // Calculate statistics
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      double totalOutstanding = 0.0;
      double paidThisMonth = 0.0;
      double overdueAmount = 0.0;

      for (final payment in payments) {
        if (payment.status.toLowerCase() == 'pending') {
          totalOutstanding += payment.amount;

          // Check if overdue (more than 30 days old)
          final daysDiff = now.difference(payment.createdAt).inDays;
          if (daysDiff > 30) {
            overdueAmount += payment.amount;
          }
        } else if (payment.status.toLowerCase() == 'completed' &&
            payment.updatedAt.isAfter(thisMonth)) {
          paidThisMonth += payment.amount;
        }
      }

      setState(() {
        _payments = payments;
        _totalOutstanding = totalOutstanding;
        _paidThisMonth = paidThisMonth;
        _overdueAmount = overdueAmount;
        _loading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshPayments() async {
    await _loadPayments();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _navigateToInvoice(String paymentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(paymentId: paymentId),
      ),
    );
  }

  void _navigateToPayment(Payment payment) {
    if (payment.isPending) {
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'caseId': payment.caseId,
          'bookingId': payment.bookingId,
          'amount': payment.amount.toStringAsFixed(2),
          'currency': payment.currency,
          'description': 'Retry payment for Case: ${payment.caseId}',
        },
      ).then((_) => _refreshPayments()); // Refresh after payment
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.receipt_long, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Billing & Invoices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPayments,
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF9333EA)),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading payments',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshPayments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshPayments,
        color: const Color(0xFF9333EA),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              // _StatCard(
              //   title: "Total Outstanding",
              //   amount: "RM ${_totalOutstanding.toStringAsFixed(2)}",
              //   color: const Color(0xFF9333EA),
              //   icon: Icons.receipt_long,
              // ),
              // const SizedBox(height: 12),
              _StatCard(
                title: "Paid This Month",
                amount: "RM ${_paidThisMonth.toStringAsFixed(2)}",
                color: const Color(0xFF10B981),
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 12),
              // _StatCard(
              //   title: "Overdue",
              //   amount: "RM ${_overdueAmount.toStringAsFixed(2)}",
              //   color: Colors.red,
              //   icon: Icons.warning_amber_rounded,
              // ),
              // const SizedBox(height: 24),

              // Payment/Invoice List
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 22, color: Color(0xFF9333EA)),
                          SizedBox(width: 8),
                          Text(
                            "Payment History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),

                    if (_payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 64,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No payments found',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_payments.map((payment) => _PaymentCard(
                        payment: payment,
                        onViewInvoice: () => _navigateToInvoice(payment.id),
                        onRetryPayment: payment.isPending
                            ? () => _navigateToPayment(payment)
                            : null,
                        statusColor: _getStatusColor(payment.status),
                        statusIcon: _getStatusIcon(payment.status),
                      )).toList()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onViewInvoice;
  final VoidCallback? onRetryPayment;
  final Color statusColor;
  final IconData statusIcon;

  const _PaymentCard({
    required this.payment,
    required this.onViewInvoice,
    this.onRetryPayment,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, size: 16, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.formattedAmount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Case: ${payment.caseId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                _formatDate(payment.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (payment.isCompleted)
                TextButton.icon(
                  onPressed: onViewInvoice,
                  icon: const Icon(Icons.receipt, size: 16, color: Color(0xFF10B981)),
                  label: const Text(
                    'View Invoice',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (payment.isPending && onRetryPayment != null)
                TextButton.icon(
                  onPressed: onRetryPayment,
                  icon: const Icon(Icons.payment, size: 16, color: Color(0xFF9333EA)),
                  label: const Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Color(0xFF9333EA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}