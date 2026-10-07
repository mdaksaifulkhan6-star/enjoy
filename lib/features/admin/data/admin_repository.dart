// ── data/admin_repository.dart ──
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  AdminRepository._();
  static final _db = Supabase.instance.client;

  static Future<bool> isAdmin() async {
    try {
      final res = await _db.rpc('is_admin');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> overview() async {
    final res = await _db.rpc('admin_overview');
    final m = Map<String, dynamic>.from(res as Map);
    return m['ok'] == true ? m : null;
  }

  static Future<List<Map<String, dynamic>>> pendingCashouts() async =>
      (await _db.from('reward_cashouts').select(
              '*, profiles(full_name)')
          .eq('status', 'pending')
          .order('created_at') as List)
          .cast<Map<String, dynamic>>();

  static Future<List<Map<String, dynamic>>> pendingPayouts() async =>
      (await _db.from('payouts').select('*, profiles(full_name)')
          .eq('status', 'requested')
          .order('created_at') as List)
          .cast<Map<String, dynamic>>();

  static Future<List<Map<String, dynamic>>> fraudSignals() async =>
      (await _db.from('fraud_signals').select('*, profiles(full_name)')
          .eq('resolved', false)
          .order('created_at', ascending: false)
          .limit(50) as List)
          .cast<Map<String, dynamic>>();

  static Future<List<Map<String, dynamic>>> openReports() async =>
      (await _db.from('reports').select()
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(50) as List)
          .cast<Map<String, dynamic>>();

  static Future<List<Map<String, dynamic>>> searchUsers(String q) async =>
      (await _db.from('profiles').select('id, full_name, username, is_online')
          .or('full_name.ilike.%$q%,username.ilike.%$q%')
          .limit(20) as List)
          .cast<Map<String, dynamic>>();

  static Future<Map<String, dynamic>> processCashout(
          String id, bool approve) async =>
      Map<String, dynamic>.from(
          (await _db.rpc('process_cashout',
              params: {'p_id': id, 'p_approve': approve})) as Map);

  static Future<Map<String, dynamic>> processPayout(
          String id, bool approve) async =>
      Map<String, dynamic>.from(
          (await _db.rpc('process_payout',
              params: {'p_id': id, 'p_approve': approve})) as Map);
}