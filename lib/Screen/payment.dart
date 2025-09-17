import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:uuid/uuid.dart';
import '../Repository/payment_repo.dart';
import '../Models/Payment.dart';
import '../authencation/auth_service.dart';
import '../Screen/invoice.dart'; // Import invoice screen

class PaymentPage extends StatefulWidget {
  final String caseId;
  final String bookingId;
  final String amount;
  final String currency;
  final String? description;

  const PaymentPage({
    Key? key,
    required this.caseId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    this.description,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final AuthService _authService = AuthService();

  bool _isInitializing = true;
  String? _errorMessage;
  Payment? _currentPayment;
  bool _isProcessingSuccess = false; // Add flag to prevent double navigation

  // PayPal Sandbox Credentials - Replace with your actual credentials
  final String _clientId = "AdyO0rKYJjK1nVnIBlx5EnCz0vc-8a1xWOH9yDca_sY2jVGaENS3-YGL3CiiEtfbJPSpGNzmRfr12pxy";
  final String _secretKey = "EBqc8Bmcz2KHLCB2NpDoesmTXiU3mp3e-X-2LZ5BuQOBPDiymla6l_mHaHVwHNPc5VZmagW4hs2rGkAs";
  final bool _sandboxMode = true;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      log('Initializing payment for case: ${widget.caseId}');

      // Validate amount
      final amountValue = double.tryParse(widget.amount);
      if (amountValue == null || amountValue <= 0) {
        throw Exception('Invalid payment amount: ${widget.amount}');
      }

      // Check if user is authenticated
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      log('User authenticated: $userId');

      // Check if payment already exists for this case
      final existingPayment = await _paymentRepo.getPaymentByCaseId(widget.caseId);

      if (existingPayment != null && existingPayment.isCompleted) {
        log('Payment already completed, navigating to invoice');
        // Navigate directly to invoice if payment is already completed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceScreen(paymentId: existingPayment.id),
            ),
          );
        });
        return;
      }

      // Create or get existing payment record
      if (existingPayment != null && existingPayment.isPending) {
        _currentPayment = existingPayment;
        log('Using existing payment: ${existingPayment.id}');
      } else {
        log('Creating new payment record');
        _currentPayment = await _paymentRepo.createPayment(
          caseId: widget.caseId,
          bookingId: widget.bookingId,
          amount: amountValue,
          currency: widget.currency,
          userId: userId,
          status: 'pending',
        );
        log('Created payment: ${_currentPayment!.id}');
      }

      setState(() {
        _isInitializing = false;
      });

      // Small delay to ensure UI is built before starting PayPal
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_isProcessingSuccess) {
        _startPayPalPayment();
      }

    } catch (e) {
      log('Error initializing payment: $e');
      setState(() {
        _errorMessage = e.toString();
        _isInitializing = false;
      });
    }
  }

  void _startPayPalPayment() {
    if (_currentPayment == null || _isProcessingSuccess) return;

    log('Starting PayPal payment');

    final transactions = [
      {
        "amount": {
          "total": widget.amount,
          "currency": widget.currency.toUpperCase(),
          "details": {
            "subtotal": widget.amount,
            "shipping": '0',
            "shipping_discount": 0
          }
        },
        "description": widget.description ?? "Payment for Case ID: ${widget.caseId}",
      }
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaypalCheckoutView(
          sandboxMode: _sandboxMode,
          clientId: _clientId,
          secretKey: _secretKey,
          transactions: transactions,
          note: "Case: ${widget.caseId}. Booking: ${widget.bookingId}",
          onSuccess: _handlePaymentSuccess,
          onError: _handlePaymentError,
          onCancel: _handlePaymentCancel,
        ),
      ),
    );
  }

  Future<void> _handlePaymentSuccess(Map params) async {
    if (_isProcessingSuccess) return; // Prevent double processing
    _isProcessingSuccess = true;

    log("PayPal onSuccess: $params");

    try {
      if (_currentPayment == null) throw Exception('Payment record not found');

      // Extract PayPal response data
      final paypalOrderId = params['orderID']?.toString() ?? params['token']?.toString();
      final transactionId = params['paymentId']?.toString() ?? params['id']?.toString() ?? paypalOrderId;

      log('Updating payment status to completed');

      // Update payment status in database
      final updatedPayment = await _paymentRepo.updatePaymentStatus(
        paymentId: _currentPayment!.id,
        status: 'completed',
        paypalOrderId: paypalOrderId,
        transactionId: transactionId,
        additionalData: Map<String, dynamic>.from(params),
      );

      log('Payment updated successfully, navigating to invoice');

      // Navigate directly to invoice screen with the payment ID
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceScreen(paymentId: updatedPayment.id),
          ),
        );
      }

    } catch (e) {
      log("Error handling payment success: $e");
      _isProcessingSuccess = false; // Reset flag on error
      _handlePaymentError("Error processing successful payment: $e");
    }
  }

  Future<void> _handlePaymentError(dynamic error) async {
    if (_isProcessingSuccess) return;

    log("PayPal onError: $error");

    try {
      if (_currentPayment != null) {
        await _paymentRepo.markPaymentFailed(
          paymentId: _currentPayment!.id,
          reason: error.toString(),
        );
      }
    } catch (e) {
      log("Error updating payment failure status: $e");
    }

    if (mounted) {
      Navigator.pop(context, {
        'status': 'error',
        'message': error.toString(),
        'caseId': widget.caseId,
        'bookingId': widget.bookingId,
      });
    }
  }

  Future<void> _handlePaymentCancel() async {
    if (_isProcessingSuccess) return;

    log('PayPal onCancel');

    try {
      if (_currentPayment != null) {
        await _paymentRepo.markPaymentCancelled(_currentPayment!.id);
      }
    } catch (e) {
      log("Error updating payment cancel status: $e");
    }

    if (mounted) {
      Navigator.pop(context, {
        'status': 'cancelled_by_user',
        'caseId': widget.caseId,
        'bookingId': widget.bookingId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: const Text("Initializing Payment", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF111827),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF9333EA)),
              SizedBox(height: 20),
              Text(
                "Setting up your payment...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: const Text("Payment Error", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF111827),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "Payment Error",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop({
                        'status': 'error',
                        'message': _errorMessage,
                        'caseId': widget.caseId,
                      }),
                      child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isInitializing = true;
                          _isProcessingSuccess = false;
                        });
                        _initializePayment();
                      },
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Payment summary screen (shown while processing)
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text("Payment Summary", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Prevent going back during processing
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PaymentDetailRow(label: "Case ID", value: widget.caseId),
                  _PaymentDetailRow(label: "Booking ID", value: widget.bookingId),
                  _PaymentDetailRow(label: "Amount", value: "${widget.currency} ${widget.amount}"),
                  _PaymentDetailRow(label: "Payment Method", value: "PayPal"),
                  _PaymentDetailRow(label: "Status", value: "Processing..."),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF9333EA)),
                  SizedBox(height: 20),
                  Text(
                    "Redirecting to PayPal...",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.security, color: Color(0xFF9333EA), size: 24),
                  SizedBox(height: 8),
                  Text(
                    "Your payment is secured by PayPal",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}