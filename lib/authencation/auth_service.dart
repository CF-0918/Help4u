import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Repository/user_repo.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email + password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data, // optional metadata
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }


  Future<void> sendPasswordResetEmail({required String email}) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'help4u://reset-password',
    );
  }

  Future<UserResponse> updatePassword({required String password}) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  /// Sign in using phone + password (maps phone → email via UserRepository)
  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    final p = phone.trim();
    final pw = password.trim();

    if (p.isEmpty || pw.isEmpty) {
      throw ArgumentError('Phone and password are required.');
    }

    // ✅ Normalize phone number (always +60…)
    final phoneNo = p.startsWith('+60') ? p : '+60${p.replaceAll(RegExp(r'^\+?60?'), '')}';

    UserRepository _userRepo = UserRepository();
    // Lookup email by phone
    final email = await _userRepo.getEmailByPhone(phoneNo);
    if (email == null || email.isEmpty) {
      throw Exception('No user found with this phone number.');
    }

    // Supabase v2 login
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: pw,
    );
  }
  /// User deletes their own account (reauthenticate first)
  Future<bool> deleteUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Reauthenticate user
      final authRes = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authRes.user == null) {
        throw Exception("Reauthentication failed");
      }

      final uid = authRes.user!.id;

      // Step 2: Call admin delete (requires service key -> run in Edge Function / backend)
      // ⚠️ This part cannot run directly in Flutter without exposing service key.
      // So usually you call a Supabase Edge Function here.
      await _supabase.functions.invoke('delete-user', body: {'uid': uid});

      // Step 3: Sign out locally
      await _supabase.auth.signOut();

      return true;
    } catch (e) {
      print("Delete user failed: $e");
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Helpers
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
