// lib/Repository/payment_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Payment.dart';

class PaymentRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'payments';

  // Columns for consistent selection
  static const _selectCols = '''
    id, case_id, booking_id, amount, currency, status, 
    paypal_order_id, transaction_id, payment_method, 
    created_at, updated_at, user_id
  ''';

  /// Create a new payment record
  Future<Payment> createPayment({
    required String caseId,
    required String bookingId,
    required double amount,
    required String currency,
    required String userId,
    String paymentMethod = 'paypal',
    String status = 'pending',
    String? paypalOrderId,
    String? transactionId,
  }) async {
    final now = DateTime.now();

    final paymentData = {
      'case_id': caseId,
      'booking_id': bookingId,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'status': status,
      'payment_method': paymentMethod,
      'user_id': userId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      if (paypalOrderId != null) 'paypal_order_id': paypalOrderId,
      if (transactionId != null) 'transaction_id': transactionId,
    };

    final row = await _client
        .from(_table)
        .insert(paymentData)
        .select(_selectCols)
        .single();

    return Payment.fromMap(row as Map<String, dynamic>);
  }

  /// Update payment status after PayPal response
  Future<Payment> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? paypalOrderId,
    String? transactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    final updateData = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
      if (paypalOrderId != null) 'paypal_order_id': paypalOrderId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (additionalData != null) 'additional_data': additionalData,
    };

    final row = await _client
        .from(_table)
        .update(updateData)
        .eq('id', paymentId)
        .select(_selectCols)
        .single();

    return Payment.fromMap(row as Map<String, dynamic>);
  }

  /// Get payment by case ID
  Future<Payment?> getPaymentByCaseId(String caseId) async {
    final data = await _client
        .from(_table)
        .select(_selectCols)
        .eq('case_id', caseId)
        .maybeSingle();

    if (data == null) return null;
    return Payment.fromMap(data as Map<String, dynamic>);
  }

  /// Get payment by booking ID
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    final data = await _client
        .from(_table)
        .select(_selectCols)
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (data == null) return null;
    return Payment.fromMap(data as Map<String, dynamic>);
  }

  /// Get all payments for a user
  Future<List<Payment>> getPaymentsByUserId(String userId) async {
    final data = await _client
        .from(_table)
        .select(_selectCols)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (data is! List) return [];
    return data
        .map((e) => Payment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mark payment as successful and update case status
  Future<bool> markPaymentSuccessful({
    required String paymentId,
    required String transactionId,
    String? paypalOrderId,
  }) async {
    try {
      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'completed',
        transactionId: transactionId,
        paypalOrderId: paypalOrderId,
      );
      return true;
    } catch (e) {
      print('Error marking payment as successful: $e');
      return false;
    }
  }

  /// Mark payment as failed
  Future<bool> markPaymentFailed({
    required String paymentId,
    String? reason,
  }) async {
    try {
      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'failed',
        additionalData: reason != null ? {'failure_reason': reason} : null,
      );
      return true;
    } catch (e) {
      print('Error marking payment as failed: $e');
      return false;
    }
  }

  /// Mark payment as cancelled
  Future<bool> markPaymentCancelled(String paymentId) async {
    try {
      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'cancelled',
      );
      return true;
    } catch (e) {
      print('Error marking payment as cancelled: $e');
      return false;
    }
  }}