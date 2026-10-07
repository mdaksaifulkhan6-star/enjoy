// ── data/boost_repository.dart ──
import 'package:supabase_flutter/supabase_flutter.dart';

class Boost {
  final String id, videoId;
  final int coinsSpent, durationDays, viewsGained;
  final DateTime endsAt;
  const Boost({required this.id, required this.videoId,
      required this.coinsSpent, required this.durationDays,
      required this.viewsGained, required this.endsAt});
  factory Boost.fromMap(Map<String, dynamic> m) => Boost(
        id: m['id'], videoId: m['video_id'], coinsSpent: m['coins_spent'],
        durationDays: m['duration_days'], viewsGained: m['views_gained'],
        endsAt: DateTime.parse(m['ends_at']),
      );
  bool get isActive => endsAt.isAfter(DateTime.now());
}

class BoostRepository {
  BoostRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static const coinsPerDay = 50;

  /// Boost create — server-এ atomic coin debit
  static Future<Map<String, dynamic>> boost(String videoId, int days) async {
    final res = await _db.rpc('create_boost',
        params: {'p_video_id': videoId, 'p_days': days});
    return Map<String, dynamic>.from(res);
  }

  /// আমার boosts (analytics সহ)
  static Future<List<Boost>> myBoosts() async {
    final rows = await _db.from('boosts').select()
        .eq('user_id', _myId).order('starts_at', ascending: false);
    return (rows as List)
        .map((r) => Boost.fromMap(r as Map<String, dynamic>)).toList();
  }
}