import 'package:supabase_flutter/supabase_flutter.dart';

class BorrowStatusInfo {
  final int freeUsedToday, freeLimit, coinsPerBorrow, balance;
  final bool vip;
  const BorrowStatusInfo({
    required this.freeUsedToday, required this.freeLimit,
    required this.coinsPerBorrow, required this.balance, required this.vip,
  });
  bool get freeAvailable => freeUsedToday < freeLimit;
  int get costForNextBorrow => (freeAvailable || vip) ? 0 : coinsPerBorrow;
  factory BorrowStatusInfo.fromJson(Map<String, dynamic> j) => BorrowStatusInfo(
    freeUsedToday: j['free_used_today'] ?? 0, freeLimit: j['free_limit'] ?? 1,
    coinsPerBorrow: j['coins_per_borrow'] ?? 10, balance: j['balance'] ?? 0,
    vip: j['vip'] ?? false,
  );
}

class BorrowResult {
  final bool ok;
  final String? requestId, error, costType;
  final int coinsSpent;
  final bool vip;
  const BorrowResult({required this.ok, this.requestId, this.error,
      this.costType, this.coinsSpent = 0, this.vip = false});
  factory BorrowResult.fromJson(Map<String, dynamic> j) => BorrowResult(
    ok: j['ok'] ?? false, requestId: j['request_id'], error: j['error'],
    costType: j['cost_type'], coinsSpent: j['coins_spent'] ?? 0,
    vip: j['vip'] ?? false,
  );
}

class BorrowRequestItem {
  final String id, contentId, contentType, ownerId, borrowerId, status, costType;
  final int coinsSpent;
  final DateTime? expiresAt, createdAt;
  const BorrowRequestItem({required this.id, required this.contentId,
      required this.contentType, required this.ownerId, required this.borrowerId,
      required this.status, required this.costType, required this.coinsSpent,
      this.expiresAt, this.createdAt});
  factory BorrowRequestItem.fromMap(Map<String, dynamic> m) => BorrowRequestItem(
    id: m['id'], contentId: m['content_id'], contentType: m['content_type'],
    ownerId: m['owner_id'], borrowerId: m['borrower_id'], status: m['status'],
    costType: m['cost_type'], coinsSpent: m['coins_spent'] ?? 0,
    expiresAt: m['expires_at'] != null ? DateTime.tryParse(m['expires_at']) : null,
    createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at']) : null,
  );
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
}

/// Phase 04 — Life-Borrow Ecosystem (Engine client)
class BorrowRepository {
  BorrowRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Engine-এর বর্তমান অবস্থা (free used today / VIP / balance)
  static Future<BorrowStatusInfo> status() async {
    final res = await _db.rpc('borrow_status');
    return BorrowStatusInfo.fromJson(Map<String, dynamic>.from(res));
  }

  /// 🤖 AI Transaction Engine call — সব check server-এ হয়
  static Future<BorrowResult> requestBorrow({
    required String contentId, String contentType = 'video',
  }) async {
    final res = await _db.rpc('request_borrow', params: {
      'p_content_id': contentId, 'p_content_type': contentType,
    });
    return BorrowResult.fromJson(Map<String, dynamic>.from(res));
  }

  /// Owner consent: Accept / Reject
  static Future<Map<String, dynamic>> respond(String requestId, bool accept) async {
    final res = await _db.rpc('respond_borrow',
        params: {'p_request_id': requestId, 'p_accept': accept});
    return Map<String, dynamic>.from(res);
  }

  /// Borrow শেষ করা (return)
  static Future<void> complete(String requestId) async =>
      _db.rpc('complete_borrow', params: {'p_request_id': requestId});

  /// আমার পাঠানো requests (status সহ)
  static Future<List<BorrowRequestItem>> sentRequests() async {
    final rows = await _db.from('borrow_requests')
        .select().eq('borrower_id', _myId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => BorrowRequestItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// আমাকে আসা requests (consent করার জন্য)
  static Future<List<BorrowRequestItem>> receivedRequests() async {
    final rows = await _db.from('borrow_requests')
        .select().eq('owner_id', _myId)
        .order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((r) => BorrowRequestItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Borrow History (সব status)
  static Future<List<BorrowRequestItem>> history() async {
    final rows = await _db.from('borrow_requests')
        .select().eq('borrower_id', _myId)
        .order('created_at', ascending: false).limit(200);
    return (rows as List)
        .map((r) => BorrowRequestItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Auto Short-এর জন্য video borrows-এর URL map
  static Future<Map<String, String>> videoUrlsFor(
      List<BorrowRequestItem> items) async {
    final ids = items
        .where((i) => i.contentType == 'video')
        .map((i) => i.contentId)
        .toList();
    if (ids.isEmpty) return {};
    final rows = await _db
        .from('videos').select('id, video_url').inFilter('id', ids);
    return {
      for (final r in (rows as List))
        r['id'] as String: r['video_url'] as String
    };
  }

  /// Recommendation: সবচেয়ে বেশি borrow হওয়া content ids
  static Future<List<Map<String, dynamic>>> trending() async {
    final rows = await _db.from('borrow_trending').select().limit(15);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Creator analytics
  static Future<Map<String, dynamic>?> myStats() async {
    final rows = await _db.from('creator_borrow_stats')
        .select().eq('owner_id', _myId).maybeSingle();
    return rows == null ? null : Map<String, dynamic>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> myTopContent() async {
    final rows = await _db.from('creator_borrow_top_content')
        .select().eq('owner_id', _myId).limit(10);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Event tracking (view)
  static Future<void> track(
      String contentId, String contentType, String event) async {
    await _db.from('borrow_events').insert({
      'content_id': contentId, 'content_type': contentType,
      'actor_id': _myId, 'event': event,
    });
  }
}