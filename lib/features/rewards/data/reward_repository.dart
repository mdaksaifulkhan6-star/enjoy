// ── data/reward_repository.dart ──
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardStatus {
  final int points, fnf, thresholdPoints, thresholdFnf;
  final double bdt;
  final bool eligible, windowActive;
  final DateTime? windowEndsAt;
  const RewardStatus({required this.points, required this.bdt,
      required this.fnf, required this.eligible, required this.windowActive,
      this.windowEndsAt, required this.thresholdPoints,
      required this.thresholdFnf});
  factory RewardStatus.fromJson(Map<String, dynamic> j) => RewardStatus(
      points: (j['points'] as num?)?.toInt() ?? 0,
      bdt: (j['bdt'] as num?)?.toDouble() ?? 0,
      fnf: (j['fnf'] as num?)?.toInt() ?? 0,
      eligible: j['eligible'] == true,
      windowActive: j['window_active'] == true,
      windowEndsAt: DateTime.tryParse(j['window_ends_at']?.toString() ?? ''),
      thresholdPoints: (j['threshold_points'] as num?)?.toInt() ?? 100000,
      thresholdFnf: (j['threshold_fnf'] as num?)?.toInt() ?? 1000);
}

class RewardRepository {
  RewardRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static Future<RewardStatus> status() async {
    final res = await _db.rpc('reward_status');
    return RewardStatus.fromJson(Map<String, dynamic>.from(res as Map));
  }

  static Future<Map<String, dynamic>> requestCashout(
          String method, String account) async {
    final res = await _db.rpc('request_reward_cashout',
        params: {'p_method': method, 'p_account': account});
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> cashoutHistory() async {
    final rows = await _db.from('reward_cashouts').select()
        .eq('user_id', _myId).order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}