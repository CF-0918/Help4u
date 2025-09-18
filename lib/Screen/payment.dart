import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:workshop_assignment/Models/Case.dart';
import 'package:workshop_assignment/Repository/case_repo.dart';
import '../Repository/payment_repo.dart';
import '../Models/Payment.dart';
import '../authencation/auth_service.dart';
import '../Screen/invoice.dart';
import 'Progress.dart';

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
  bool _isProcessingSuccess = false;

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

      final amountValue = double.tryParse(widget.amount);
      if (amountValue == null || amountValue <= 0) {
        throw Exception('Invalid payment amount: ${widget.amount}');
      }

      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      log('User authenticated: $userId');

      final existingPayment = await _paymentRepo.getPaymentByCaseId(widget.caseId);

      if (existingPayment != null && existingPayment.isCompleted) {
        log('Payment already completed, redirecting to invoice');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => InvoiceScreen(paymentId: existingPayment.id)),
          );
        });
        return;
      }

      if (existingPayment != null && existingPayment.isPending) {
        _currentPayment = existingPayment;
      } else {
        _currentPayment = await _paymentRepo.createPayment(
          caseId: widget.caseId,
          bookingId: widget.bookingId,
          amount: amountValue,
          currency: widget.currency,
          userId: userId,
          status: 'pending',
        );
      }

      setState(() => _isInitializing = false);

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

    final transactions = [
      {
        "amount": {
          "total": widget.amount,
          "currency": widget.currency.toUpperCase(),
          "details": {"subtotal": widget.amount, "shipping": '0', "shipping_discount": 0}
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
          note: "Case: ${widget.caseId}, Booking: ${widget.bookingId}",
          onSuccess: _handlePaymentSuccess,
          onError: _handlePaymentError,
          onCancel: _handlePaymentCancel,
        ),
      ),
    ).then((result) {
      // 👇 This runs when user comes back from PayPal screen
      log("Returned from PayPal page: $result");

      setState(() {
        if (!_isProcessingSuccess) {
          _isInitializing = false;
          _errorMessage = "Payment was not completed.";
        }
      });
    });

  }

  Future<void> _handlePaymentSuccess(Map params) async {
    if (_isProcessingSuccess) return;
    _isProcessingSuccess = true;

    log("PayPal success: $params");

    try {
      if (_currentPayment == null) throw Exception('Payment record not found');

      final paypalOrderId = params['orderID']?.toString() ?? params['token']?.toString();
      final transactionId =
          params['paymentId']?.toString() ?? params['id']?.toString() ?? paypalOrderId;

      final updatedPayment = await _paymentRepo.updatePaymentStatus(
        paymentId: _currentPayment!.id,
        status: 'completed',
        paypalOrderId: paypalOrderId,
        transactionId: transactionId,
        additionalData: Map<String, dynamic>.from(params),
      );

      //yijun u forget to update case status to done
      try {
        await CasesRepo().updateCaseStatus(widget.caseId, CaseStatus.done);
      } catch (e, stack) {
        // Log the error
        debugPrint("Error updating case status: $e");
        debugPrintStack(stackTrace: stack);

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Failed to update case status ❌',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_)=> InvoiceScreen(paymentId: updatedPayment.id)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green, // 🟢 Green background
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white), // ✅ White icon
                SizedBox(width: 8),
                Text(
                  'Payment completed successfully',
                  style: TextStyle(color: Colors.white), // ⚪ White text
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 3), // auto dismiss after 3s
          ),
        );
      }
    } catch (e) {
      log("Error on success flow: $e");
      _isProcessingSuccess = false;
      _handlePaymentError("Error processing payment: $e");
    }
  }

  Future<void> _handlePaymentError(dynamic error) async {
    if (_isProcessingSuccess) return;

    log("PayPal error: $error");

    try {
      if (_currentPayment != null) {
        await _paymentRepo.markPaymentFailed(
          paymentId: _currentPayment!.id,
          reason: error.toString(),
        );
      }
    } catch (e) {
      log("Error marking payment failed: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Progress(bookingId: widget.bookingId)),
      );
    }
  }

  Future<void> _handlePaymentCancel() async {
    if (_isProcessingSuccess) return;

    log("PayPal cancelled");

    try {
      if (_currentPayment != null) {
        await _paymentRepo.markPaymentCancelled(_currentPayment!.id);
      }
    } catch (e) {
      log("Error marking payment cancelled: $e");
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _isProcessingSuccess = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Progress(bookingId: widget.bookingId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoading("Initializing Payment", "Setting up your payment...");
    }
    if (_errorMessage != null) {
      return _buildError();
    }
    return _buildSummary();
  }

  Widget _buildLoading(String title, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => Progress(bookingId: widget.bookingId)));
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               backgroundColor: Colors.red, // 🔴 red background
               content: Row(
                 children: const [
                   Icon(Icons.error, color: Colors.white), // ⚠️ icon
                   SizedBox(width: 8),
                   Text(
                     'Payment process cancelled',
                     style: TextStyle(color: Colors.white), // ⚪ white text
                   ),
                 ],
               ),
               behavior: SnackBarBehavior.floating,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             ),
           );

          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF9333EA)),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => Progress(bookingId: widget.bookingId)));

          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Payment Summary", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
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
                  const Text("Payment Details",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _PaymentDetailRow(label: "Case ID", value: widget.caseId),
                  _PaymentDetailRow(label: "Booking ID", value: widget.bookingId),
                  _PaymentDetailRow(label: "Amount", value: "${widget.currency} ${widget.amount}"),
                  const _PaymentDetailRow(label: "Payment Method", value: "PayPal"),
                  const _PaymentDetailRow(label: "Status", value: "Processing..."),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF9333EA)),
                  SizedBox(height: 20),
                  Text("Redirecting to PayPal...",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
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
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Flexible(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
