import 'package:supabase_flutter/supabase_flutter.dart';

class MonetizationRepository {
  MonetizationRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Eligibility engine (stage + metrics + thresholds)
  static Future<Map<String, dynamic>> progress() async {
    final res = await _db.rpc('monetization_progress');
    return Map<String, dynamic>.from(res);
  }

  /// Earnings ledger
  static Future<List<Map<String, dynamic>>> earnings() async {
    final rows = await _db.from('earnings_ledger')
        .select().eq('user_id', _myId)
        .order('created_at', ascending: false).limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> balance() async {
    final row = await _db.from('creator_balances')
        .select().eq('user_id', _myId).maybeSingle();
    return row == null
        ? {'payable_bdt': 0, 'lifetime_bdt': 0, 'paid_bdt': 0}
        : Map<String, dynamic>.from(row);
  }

  static Future<List<Map<String, dynamic>>> payouts() async {
    final rows = await _db.from('payouts').select()
        .eq('user_id', _myId).order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> requestPayout(
          double amount, String method, String account) async {
    final res = await _db.rpc('request_payout', params: {
      'p_amount': amount, 'p_method': method, 'p_account': account,
    });
    return Map<String, dynamic>.from(res);
  }

  static String sourceBn(String s) => {
        'video_ad': 'ভিডিও অ্যাড 🎬', 'short_ad': 'শর্টস অ্যাড 📱',
        'live': 'লাইভ 🔴', 'course': 'কোর্স 📚', 'game': 'গেম 🎮',
        'market': 'ক্রিয়েটর মার্কেট 🛍️', 'borrow': 'Life-Borrow 🔄',
      }[s] ?? s;
}