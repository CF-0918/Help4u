import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all invoice-related data for a paymentId
  Future<Map<String, dynamic>> fetchInvoice(String paymentId) async {
    try {
      // 1️⃣ Get payment row
      final payment = await _client
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();

      if (payment == null) {
        throw Exception('Payment not found');
      }

      final caseId = payment['case_id'] as String?;
      final bookingId = payment['booking_id'] as String?;
      final userId = payment['user_id'] as String?;

      // 2️⃣ Get related case
      Map<String, dynamic>? caseRow;
      if (caseId != null) {
        caseRow = await _client
            .from('cases')
            .select()
            .eq('caseid', caseId)
            .maybeSingle();
      }

      // 3️⃣ Get booking
      Map<String, dynamic>? bookingRow;
      if (bookingId != null) {
        bookingRow = await _client
            .from('bookings')
            .select()
            .eq('booking_id', bookingId)
            .maybeSingle();
      }

      // 4️⃣ Get user profile
      Map<String, dynamic>? userRow;
      if (userId != null) {
        userRow = await _client
            .from('user_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      }

      // 5️⃣ Get vehicle (by user or booking)
      Map<String, dynamic>? vehicleRow;
      if (userId != null) {
        vehicleRow = await _client
            .from('vehicle')
            .select()
            .eq('userid', userId)
            .limit(1)
            .maybeSingle();
      }

      // 6 Get service type (by booking)
      Map<String, dynamic>? serviceRow;
      if (bookingRow != null && bookingRow['service_type_id'] != null) {
        serviceRow = await _client
            .from('service_type')
            .select()
            .eq('id', bookingRow['service_type_id'])
            .maybeSingle();
      }

      // 7️ Get outlet
      Map<String, dynamic>? outletRow;
      if (bookingRow != null && bookingRow['outletid'] != null) {
        outletRow = await _client
            .from('outlets')
            .select()
            .eq('outletid', bookingRow['outletid'])
            .maybeSingle();
      }

      return {
        'payment': payment,
        'case': caseRow,
        'booking': bookingRow,
        'user': userRow,
        'vehicle': vehicleRow,
        'service': serviceRow,
        'outlet': outletRow,
      };
    } catch (e) {
      print('Error fetching invoice: $e');
      rethrow;
    }
  }
}
