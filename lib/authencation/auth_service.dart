import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
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


  Future<String> uploadFile({
    required String folder,        // "user", "car", or "invoice"
    required Uint8List fileData,
    required String fileName,      // e.g. "profile.png" or "invoice.pdf"
    bool forcePng = false,         // 👈 new param
    bool upsert = true,
  }) async {
    final bucket = 'Help4uBucket';

    // Force PNG only if requested
    String finalName = fileName;
    String contentType = lookupMimeType(fileName) ?? 'application/octet-stream';

    if (forcePng) {
      finalName = '${fileName.split('.').first}.png';
      contentType = 'image/png';
    }

    final path = '$folder/$finalName';

    try {
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
        path,
        fileData,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: upsert,
        ),
      );

      return _supabase.storage.from(bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw Exception('File upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> deleteFile({
    required String folder,
    required String fileName,
  }) async {
    final bucket = 'Help4uBucket';
    final path= '$folder/$fileName';
    try {
      final deleted = await _supabase.storage.from(bucket).remove([path]);

      if (deleted.isEmpty) {
        // Nothing was deleted
        throw Exception('File deletion failed: file not found or already removed.');
      }
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
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

  Future<void>logOut() async {
    await _supabase.auth.signOut();
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

    String accStatus =await _userRepo.getAccStatus(phoneNo);
    print("Account status: $accStatus");
    if(accStatus!="active"){
      throw Exception('Account is $accStatus. Please contact support.');
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
