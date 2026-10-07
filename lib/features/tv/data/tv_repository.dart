import 'package:supabase_flutter/supabase_flutter.dart';

class TvRepository {
  TvRepository._();
  static final _db = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> channels() async {
    final rows = await _db.from('tv_channels').select().order('category').order('name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> shows(String channelId) async {
    final rows = await _db
        .from('tv_shows')
        .select()
        .eq('channel_id', channelId)
        .order('starts_at', ascending: false)
        .limit(20);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}