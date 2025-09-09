import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/UserDevice.dart';


class UserDevicesRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'user_devices';

  Future<UserDevice> upsertToken({
    required String userProfileId,
    required String deviceToken,
    required String platform, // 'android' | 'ios' | 'web'
  }) async {
    final row = await _client
        .from(_table)
        .upsert({
      'user_id': userProfileId,
      'platform': platform,
      'token': deviceToken,                         // <- token
      'updated_at': DateTime.now().toIso8601String()
    }, onConflict: 'user_id,platform')
        .select()
        .single();

    return UserDevice.fromMap(row as Map<String, dynamic>);
  }

  Future<List<UserDevice>> fetchForUser(String userProfileId) async {
    final data = await _client
        .from(_table)
        .select('id,user_id,platform,token,updated_at') // <- no created_at
        .eq('user_id', userProfileId);

    if (data is! List) return [];
    return data.map((e) => UserDevice.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteToken({
    required String userProfileId,
    required String platform,
  }) async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', userProfileId)
        .eq('platform', platform);
  }
}
