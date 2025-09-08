// cases_repo.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Case.dart';

class CasesRepo {
  final supabase = Supabase.instance.client;

  Future<void> createCase(CaseModel c) async {
    await supabase.from('cases').insert(c.toMap());
  }

  Future<bool> hasCaseForBooking(String bookingId) async {
    final res = await supabase
        .from('cases')
        .select('caseid')
        .eq('booking_id', bookingId)
        .limit(1);
    return (res as List).isNotEmpty;
  }

  /// ✅ Fetch cases for a user with FULL join:
  /// cases + bookings (and inside bookings: user_profiles, outlets, vehicle, service_type)
  Future<List<CaseModel>> getUserCases(String userId) async {
    final res = await supabase
        .from('cases')
        .select('''
          caseid,
          booking_id,
          userid,
          case_status,
          case_closed,
          workercomments,
          created_at,
          updated_at,
          bookings!inner(
            booking_id,
            userid,
            outletid,
            vehicleplateno,
            servicetypeid,
            mileage,
            bookingstatus,
            bookingdate,
            bookingtime,
            createdat,
            user_profiles:userid(*),
            outlets:outletid(*),
            vehicle:vehicleplateno(*),
            service_type:servicetypeid(*)
          )
        ''')
        .eq('userid', userId)
        .order('created_at', ascending: false);

    final list = (res as List)
        .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
        .toList();

    return list.map((e) => CaseModel.fromMap(e)).toList();
  }

  Future<void> updateCaseStatus(String caseId, CaseStatus status) async {
    await supabase
        .from('cases')
        .update({'case_status': status.dbValue})
        .eq('caseid', caseId);
  }

// Fetch the case by booking_id (deep join like other methods)
  Future<CaseModel?> getOnGoingCaseByBookingId(String bookingId) async {
    final res = await supabase
        .from('cases')
        .select('''
        caseid, booking_id, userid, case_status, case_closed,
        workercomments, created_at, updated_at,
        bookings!inner(
          booking_id, userid, outletid, vehicleplateno, servicetypeid,
          mileage, bookingstatus, bookingdate, bookingtime, createdat,
          user_profiles:userid(*),
          outlets:outletid(*),
          vehicle:vehicleplateno(*),
          service_type:servicetypeid(*)
        )
      ''')
        .eq('booking_id', bookingId)
        .neq('case_status', 'DONE')
        .eq('case_closed', false)
        .maybeSingle();

    if (res == null) return null;
    return CaseModel.fromMap(res as Map<String, dynamic>);
  }


  Future<List<CaseModel>> getActiveCasesForUser(String userId) async {
    final res = await supabase
        .from('cases')
        .select('''
        caseid, booking_id, userid, case_status, case_closed,
        workercomments, created_at, updated_at,
        bookings!inner(
          booking_id, userid, outletid, vehicleplateno, servicetypeid,
          mileage, bookingstatus, bookingdate, bookingtime, createdat,
          user_profiles:userid(*),
          outlets:outletid(*),
          vehicle:vehicleplateno(*),
          service_type:servicetypeid(*)
        )
      ''')
        .eq('userid', userId)
        .eq('case_closed', false)
        .neq('case_status', 'DONE')
        .order('updated_at', ascending: false);

    return (res as List)
        .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
        .map((e) => CaseModel.fromMap(e))
        .toList();
  }

  Future<List<CaseModel>> getCompletedCasesForUser(String userId) async {
    final res = await supabase
        .from('cases')
        .select('''
        caseid, booking_id, userid, case_status, case_closed,
        workercomments, created_at, updated_at,
        bookings!inner(
          booking_id, userid, outletid, vehicleplateno, servicetypeid,
          mileage, bookingstatus, bookingdate, bookingtime, createdat,
          user_profiles:userid(*),
          outlets:outletid(*),
          vehicle:vehicleplateno(*),
          service_type:servicetypeid(*)
        )
      ''')
        .eq('userid', userId)
        .eq('case_status', 'DONE')
        .order('updated_at', ascending: false);

    return (res as List)
        .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
        .map((e) => CaseModel.fromMap(e))
        .toList();
  }
}
