import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Models/UserProfile.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;
  AuthService _authService = AuthService();

  /// Check if user exists in phone_to_email
  /// - if verified → return false (cannot reuse)
  /// - if not verified → delete old record (allow override)
  /// - if not exists → allow register
  Future<bool> checkHalfWaySignUp(String email, String phoneNo) async {
    try {
      final existing = await _client
          .from('phone_to_email')
          .select()
          .or('phone.eq.$phoneNo,email.eq.$email')
          .maybeSingle();

      if (existing != null) {
        if (existing['is_verified'] == true) {
          // Already verified → block re-registration
          return false;
        } else {
          // Exists but not verified → clean old record (allow new one
          await _client.from('phone_to_email').delete().eq('id', existing['id']);

          return true;
        }
      }

      // No record found → safe to register
      return true;
    } catch (e) {
      print("verifyUserAcc error: $e");
      return false; // in error case, safer to block
    }
  }

  Future<bool>verifyPhoneEmailMatch({required String email, required String phoneNo}) async {
    try {
      final existing = await _client
          .from('phone_to_email')
          .select()
          .eq('phone', phoneNo)
          .maybeSingle();

      if (existing != null && existing['email'] == email) {
        return true; // match
      }

      return false; // no match or not found
    } catch (e) {
      print("verifyPhoneEmailMatch error: $e");
      return false; // in error case, safer to say no match
    }
  }

Future<String?> getEmailByPhone(String phoneNo) async {
    try {
      final existing = await _client
          .from('phone_to_email')
          .select()
          .eq('phone', phoneNo)
          .maybeSingle();

      if (existing != null) {
        return existing['email'] as String?;
      }

      return null;
    } catch (e) {
      print("getEmailByPhone error: $e");
      return null; // in error case, return null
    }
  }

  /// Insert or update user profile for the current auth.uid
  Future<UserProfile?> insertUser({required UserProfile user}) async {
    // make sure we attach id = auth.uid()
    final data = user.toInsertMap()..['id'] = user.uid;

    final response = await _client
        .from('user_profiles')
        .upsert(data, onConflict: 'id') // safer than insert
        .select()
        .single();

    return UserProfile.fromMap(response);
  }

  Future<UserProfile?> fetchUserDetails(String uid) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromMap(response);
      }
      return null;
    } catch (e) {
      print("fetchUserDetails error: $e");
      return null;
    }
  }
}
