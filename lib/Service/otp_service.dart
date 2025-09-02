import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpService {
  // ⚠️ For demo/testing only. Do NOT ship secrets in production apps.
  static const _resendApiKey = 're_CYqhwQNv_9edoaVWhrmiQ9dGc9QQFkqpe';
  static const _fromEmail = 'onboarding@resend.dev'; // must be verified in Resend

  static String generate6() {
    final n = (DateTime.now().microsecondsSinceEpoch % 1000000).abs();
    return n.toString().padLeft(6, '0');
    // (Optional) Use a crypto RNG if you want stronger OTPs.
  }

  static Future<void> saveOtp({
    required String email,
    required String otp,
    required DateTime expiresAtUtc,
    SupabaseClient? supa,
  }) async {
    final _supa = supa ?? Supabase.instance.client;
    await _supa.from('user_otps').upsert({
      'email': email.trim(),
      'otp': otp,
      'expires_at': expiresAtUtc.toIso8601String(),
    }, onConflict: 'email');
  }

  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String text,
  }) async {
    final resp = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': _fromEmail, // must be a verified sender in Resend
        'to': to,
        'subject': subject,
        'text': text,
      }),
    );
    if (resp.statusCode >= 400) {
      throw 'Resend API failed: ${resp.statusCode} ${resp.body}';
    }
  }
}
