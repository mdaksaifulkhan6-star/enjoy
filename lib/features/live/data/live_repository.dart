import 'package:supabase_flutter/supabase_flutter.dart';

class LiveRepository {
  LiveRepository._();
  static final _db = Supabase.instance.client;

  static Future<String> goLive({
    required String title,
    required String streamUrl,
    String category = 'জেনারেল',
    String? thumbnailUrl,
  }) async {
    final res = await _db.rpc('go_live', params: {
      'p_title': title,
      'p_stream_url': streamUrl,
      'p_category': category,
      'p_thumbnail': thumbnailUrl,
    });
    return res as String;
  }

  static Future<Map<String, dynamic>> endLive(String roomId) async {
    final res = await _db.rpc('end_live', params: {'p_room_id': roomId});
    return Map<String, dynamic>.from(res as Map);
  }

  static Stream<List<Map<String, dynamic>>> liveRooms() {
    return _db
        .from('live_rooms')
        .stream(primaryKey: ['id'])
        .eq('status', 'live')
        .order('started_at')
        .map((r) => r.reversed
            .map((x) => Map<String, dynamic>.from(x as Map))
            .toList());
  }

  static Stream<List<Map<String, dynamic>>> chatStream(String roomId) {
    return _db
        .from('live_chat')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((r) =>
            r.map((x) => Map<String, dynamic>.from(x as Map)).toList());
  }

  static Future<void> sendChat(String roomId, String text) async {
    await _db.from('live_chat').insert({
      'room_id': roomId,
      'user_id': _db.auth.currentUser?.id,
      'text': text,
    });
  }

  static Future<int> react(String roomId, String reaction) async {
    final res = await _db.rpc('live_react',
        params: {'p_room_id': roomId, 'p_reaction': reaction});
    return (Map<String, dynamic>.from(res as Map)['like_count'] as num?)
            ?.toInt() ??
        0;
  }
}