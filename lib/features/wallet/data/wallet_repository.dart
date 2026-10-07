import 'package:supabase_flutter/supabase_flutter.dart';

class CoinPackage {
  final int coins, priceBdt;
  final String label;
  final String? bonus;
  const CoinPackage(this.coins, this.priceBdt, this.label, [this.bonus]);
}

class LedgerEntry {
  final String direction, reason;
  final int amount, balanceAfter;
  final DateTime createdAt;
  const LedgerEntry({required this.direction, required this.reason,
      required this.amount, required this.balanceAfter, required this.createdAt});
  factory LedgerEntry.fromMap(Map<String, dynamic> m) => LedgerEntry(
        direction: m['direction'], reason: m['reason'], amount: m['amount'],
        balanceAfter: m['balance_after'],
        createdAt: DateTime.parse(m['created_at']),
      );
  bool get isCredit => direction == 'credit';
}

/// Phase 05 — Borrow Coin, Wallet, Ledger
class WalletRepository {
  WalletRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Coin Store packages (10 Coin = ৳10)
  static const packages = [
    CoinPackage(10, 10, '১০ Coin'),
    CoinPackage(50, 50, '৫০ Coin'),
    CoinPackage(120, 100, '১২০ Coin', '২০% বোনাস 🎁'),
    CoinPackage(550, 500, '৫৫০ Coin', '১০% বোনাস 🎁'),
  ];

  /// Realtime balance
  static Stream<int> balanceStream() {
    return _db.from('wallets').stream(primaryKey: ['user_id'])
        .eq('user_id', _myId)
        .map((r) => r.isEmpty ? 0 : r.first['coin_balance'] as int);
  }

  /// Transaction ledger (history)
  static Future<List<LedgerEntry>> ledger() async {
    final rows = await _db.from('coin_transactions')
        .select().eq('user_id', _myId)
        .order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((r) => LedgerEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// VIP status (realtime)
  static Stream<bool> vipStream() {
    return _db.from('vip_subscriptions').stream(primaryKey: ['id'])
        .eq('user_id', _myId)
        .map((rows) => rows.any((r) =>
            r['status'] == 'active' &&
            DateTime.parse(r['expires_at']).isAfter(DateTime.now())));
  }

  /// Payment row তৈরি (initiated) — verification server-এ হয়
  static Future<String> initiatePayment({
    required String gateway,           // bkash | nagad | card
    required String purpose,           // coin_purchase | vip_subscription
    required int amountBdt,
    int coins = 0,
  }) async {
    final row = await _db.from('payments').insert({
      'user_id': _myId,
      'gateway': gateway,
      'purpose': purpose,
      'amount_bdt': amountBdt,
      'coins': coins,
      'idempotency_key': '${_myId}_${DateTime.now().millisecondsSinceEpoch}',
    }).select().single();
    return row['id'] as String;
  }

  /// ⚠️ DEMO-এর জন্য — production-এ gateway callback (Edge Function) করে
  static Future<void> demoVerify(String paymentId, {bool success = true}) async {
    await _db.rpc('verify_payment', params: {
      'p_payment_id': paymentId,
      'p_gateway_trx_id': 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
      'p_success': success,
      'p_raw': {'amount': null, 'demo': true},
    });
  }

  static String reasonBn(String r) => {
        'purchase_credit': 'Coin কেনা ✅',
        'borrow_debit': 'Borrow খরচ 🔄',
        'borrow_refund': 'Borrow Refund 💸',
        'boost_debit': 'Boost খরচ 🚀',
        'vip_purchase': 'VIP সাবস্ক্রিপশন 🌟',
        'adjustment': 'অ্যাডজাস্টমেন্ট',
      }[r] ?? r;
}