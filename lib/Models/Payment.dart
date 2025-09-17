// lib/Models/Payment.dart - Fixed version
class Payment {
  final String id;
  final String caseId;
  final String bookingId;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, cancelled
  final String? paypalOrderId;
  final String? transactionId;
  final String paymentMethod;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalData;

  const Payment({
    required this.id,
    required this.caseId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.paypalOrderId,
    this.transactionId,
    this.additionalData,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    // Add null safety and type checking
    return Payment(
      id: map['id']?.toString() ?? '',
      caseId: map['case_id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      currency: map['currency']?.toString() ?? 'MYR',
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: map['payment_method']?.toString() ?? 'paypal',
      userId: map['user_id']?.toString() ?? '',
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
      paypalOrderId: map['paypal_order_id']?.toString(),
      transactionId: map['transaction_id']?.toString(),
      additionalData: map['additional_data'] as Map<String, dynamic>?,
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to safely parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_id': caseId,
      'booking_id': bookingId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (paypalOrderId != null) 'paypal_order_id': paypalOrderId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (additionalData != null) 'additional_data': additionalData,
    };
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
}