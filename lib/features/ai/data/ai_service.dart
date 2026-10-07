import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Ecosystem gateway — App Doctor + AI Chat + Search + Recommendation
class AiService {
  AiService._();
  static final _db = Supabase.instance.client;

  // ═══ AI CHAT ═══
  static Future<String> chat(String message) async {
    try {
      final res = await _db.rpc('ai_chat', params: {'p_message': message});
      return Map<String, dynamic>.from(res as Map)['reply'] ?? '…';
    } catch (_) {
      return 'AI এখন ব্যস্ত 😅 — একটু পরে চেষ্টা করুন।';
    }
  }

  // ═══ AI MEMORY ═══
  static Future<void> remember(String key, Map<String, dynamic> value) async {
    final myId = _db.auth.currentUser?.id;
    if (myId == null) return;
    await _db.from('ai_memories').upsert({
      'user_id': myId,
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> memory(String key) async {
    final myId = _db.auth.currentUser?.id;
    if (myId == null) return null;
    final row = await _db
        .from('ai_memories')
        .select('value')
        .eq('user_id', myId)
        .eq('key', key)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row['value'] as Map);
  }

  // ═══ AI SEARCH / RECOMMENDATION / TRANSLATION ═══
  static Future<Map<String, dynamic>> search(String query) async {
    final res = await _db.rpc('unified_search', params: {'p_query': query});
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> recommendations() async {
    final res = await _db.rpc('ai_recommendations');
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<String> translate(String text, String target) async {
    final res = await _db
        .rpc('ai_translate', params: {'p_text': text, 'p_target': target});
    return Map<String, dynamic>.from(res as Map)['text'] ?? text;
  }

  // ═══ APP DOCTOR / ERROR & PERFORMANCE INTELLIGENCE ═══
  static Future<void> reportError(
      String screen, String message, String? stack) async {
    await _db.from('app_errors').insert({
      'user_id': _db.auth.currentUser?.id,
      'screen': screen,
      'message': message,
      'stack': stack,
      'app_version': '1.0.0',
    }).catchError((_) {});
  }

  static Future<void> reportPerformance(String screen, int loadMs) async {
    await _db.from('performance_metrics').insert({
      'user_id': _db.auth.currentUser?.id,
      'screen': screen,
      'load_ms': loadMs,
    }).catchError((_) {});
  }

  static Future<Map<String, dynamic>> doctorReport() async {
    final myId = _db.auth.currentUser?.id ?? '';
    var errorCount = 0;
    var avgLoad = 0;
    try {
      final rows = await _db
          .from('app_errors')
          .select('id')
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(50);
      errorCount = rows.length;
    } catch (_) {}
    try {
      final rows = await _db
          .from('performance_metrics')
          .select('load_ms')
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(20);
      if (rows.isNotEmpty) {
        final sum = rows
            .map((e) => (e['load_ms'] as num).toInt())
            .reduce((a, b) => a + b);
        avgLoad = sum ~/ rows.length;
      }
    } catch (_) {}
    return {
      'platform': kIsWeb ? 'Web' : defaultTargetPlatform.name,
      'errorCount': errorCount,
      'avgLoadMs': avgLoad,
      'status': avgLoad < 300
          ? '✅ ভালো'
          : avgLoad < 800
              ? '⚠️ মাঝারি'
              : '🔴 ধীর',
    };
  }
}