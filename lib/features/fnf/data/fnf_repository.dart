import 'package:supabase_flutter/supabase_flutter.dart';

class FnfUser {
  final String id, name;
  final String? avatar;
  final bool isOnline;
  final bool showOnlineStatus;
  final DateTime? lastActive;
  const FnfUser({required this.id, required this.name, this.avatar,
      this.isOnline = false, this.showOnlineStatus = true, this.lastActive});
  bool get displayOnline => isOnline && showOnlineStatus;
  factory FnfUser.fromMap(Map<String, dynamic> m) => FnfUser(
        id: m['id'], name: m['full_name'] ?? 'বেনামী',
        avatar: m['avatar_url'], isOnline: m['is_online'] ?? false,
        showOnlineStatus: m['show_online_status'] ?? true,
        lastActive: m['last_active'] != null
            ? DateTime.tryParse(m['last_active']) : null,
      );
}

class FnfRequest {
  final String id, senderId, senderName;
  final String? senderAvatar;
  const FnfRequest({required this.id, required this.senderId,
      required this.senderName, this.senderAvatar});
  factory FnfRequest.fromMap(Map<String, dynamic> m) {
    final p = m['profiles'] as Map<String, dynamic>?;
    return FnfRequest(
      id: m['id'], senderId: m['sender_id'],
      senderName: p?['full_name'] ?? 'বেনামী',
      senderAvatar: p?['avatar_url'],
    );
  }
}

/// FNF — Friend & Friend
class FnfRepository {
  FnfRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Send FNF request
  static Future<void> sendRequest(String userId) async {
    await _db.from('fnf_requests').insert(
        {'sender_id': _myId, 'receiver_id': userId});
  }

  static Future<void> accept(String requestId) async {
    await _db.from('fnf_requests')
        .update({'status': 'accepted'}).eq('id', requestId);
  }

  static Future<void> reject(String requestId) async {
    await _db.from('fnf_requests')
        .update({'status': 'rejected'}).eq('id', requestId);
  }

  /// Remove FNF (deletes the accepted row)
  static Future<void> removeFriend(String friendId) async {
    await _db.from('fnf_requests').delete().or(
        'and(sender_id.eq.$_myId,receiver_id.eq.$friendId),'
        'and(sender_id.eq.$friendId,receiver_id.eq.$_myId)')
        .eq('status', 'accepted');
  }

  /// Friends list + online status
  static Future<List<FnfUser>> myFriends() async {
    final rows = await _db.from('fnf_requests')
        .select('sender_id, receiver_id, profiles!fnf_requests_sender_id_fkey(id, full_name, avatar_url, is_online, show_online_status, last_active), profiles!fnf_requests_receiver_id_fkey(id, full_name, avatar_url, is_online, show_online_status, last_active)')
        .or('sender_id.eq.$_myId,receiver_id.eq.$_myId')
        .eq('status', 'accepted');

    return (rows as List).map((r) {
      final other = (r['sender_id'] == _myId)
          ? r['profiles!fnf_requests_receiver_id_fkey'] as Map<String, dynamic>
          : r['profiles!fnf_requests_sender_id_fkey'] as Map<String, dynamic>;
      return FnfUser.fromMap(other);
    }).toList();
  }

  /// FNF count
  static Future<int> friendCount() async => (await myFriends()).length;

  /// Incoming pending requests
  static Future<List<FnfRequest>> incomingRequests() async {
    final rows = await _db.from('fnf_requests')
        .select('*, profiles(full_name, avatar_url)')
        .eq('receiver_id', _myId).eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => FnfRequest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Profile relationship status
  static Future<String> relationshipWith(String userId) async {
    final row = await _db.from('fnf_requests').select('status')
        .or('and(sender_id.eq.$_myId,receiver_id.eq.$userId),'
            'and(sender_id.eq.$userId,receiver_id.eq.$_myId)')
        .maybeSingle();
    if (row == null) return 'none'; // none, pending_sent, pending_received, accepted
    if (row['status'] == 'accepted') return 'accepted';
    return row['sender_id'] == _myId ? 'pending_sent' : 'pending_received';
  }

  /// Search users (excluding self)
  static Future<List<FnfUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await _db.from('profiles')
        .select()
        .neq('id', _myId)
        .or('full_name.ilike.%$query%,username.ilike.%$query%')
        .limit(20);
    return (rows as List)
        .map((r) => FnfUser.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}