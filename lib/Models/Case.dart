import 'package:uuid/uuid.dart';
import 'package:workshop_assignment/Models/Appointment.dart';
import 'package:workshop_assignment/Models/UserProfile.dart';

/// Enum for case status (keep in sync with Supabase `case_status` enum)
enum CaseStatus {
  checkIn,
  inspection,
  prepareSparePart,
  repair,
  qc,
  payment,
  done,
}

extension CaseStatusX on CaseStatus {
  String get dbValue {
    switch (this) {
      case CaseStatus.checkIn:
        return "CHECK_IN";
      case CaseStatus.inspection:
        return "INSPECTION";
      case CaseStatus.prepareSparePart:
        return "PREPARE_SPARE_PART";
      case CaseStatus.repair:
        return "REPAIR";
      case CaseStatus.qc:
        return "QC";
      case CaseStatus.payment:
        return "PAYMENT";
      case CaseStatus.done:
        return "DONE";
    }
  }

  static CaseStatus fromDb(String value) {
    switch (value) {
      case "CHECK_IN":
        return CaseStatus.checkIn;
      case "INSPECTION":
        return CaseStatus.inspection;
      case "PREPARE_SPARE_PART":
        return CaseStatus.prepareSparePart;
      case "REPAIR":
        return CaseStatus.repair;
      case "QC":
        return CaseStatus.qc;
      case "PAYMENT":
        return CaseStatus.payment;
      case "DONE":
        return CaseStatus.done;
      default:
        throw Exception("Unknown case_status: $value");
    }
  }
}

// case_model.dart (only showing the changed parts)
const uuid = Uuid();

class CaseModel {
  final String caseId;
  final String? bookingId;
  final String userId;

  // ✅ keep this field and wire it in
  final Appointment? appointment;

  final CaseStatus caseStatus;
  final bool caseClosed;
  final String? workerComments;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseModel({
    required this.caseId,
    this.bookingId,
    required this.userId,
    // ✅ add this param
    this.appointment,
    required this.caseStatus,
    this.caseClosed = false,
    this.workerComments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    return CaseModel(
      caseId: map['caseid'] as String,
      bookingId: map['booking_id'] as String?,
      userId: map['userid'] as String,
      // ✅ If join provided, build Appointment; else null
      appointment: map['bookings'] != null
          ? Appointment.fromJson(map['bookings'] as Map<String, dynamic>)
          : null,
      caseStatus: CaseStatusX.fromDb(map['case_status'] as String),
      caseClosed: map['case_closed'] as bool? ?? false,
      workerComments: map['workercomments'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caseid': caseId,
      'booking_id': bookingId,
      'userid': userId,
      'case_status': caseStatus.dbValue,
      'case_closed': caseClosed,
      'workercomments': workerComments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // ⚠️ Do NOT include `appointment` in inserts/updates (it’s from a join)
    };
  }
}
