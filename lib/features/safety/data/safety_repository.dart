import 'package:supabase_flutter/supabase_flutter.dart';

/// Safety: Block / Mute / Report
class SafetyRepository {
  SafetyRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static Future<void> blockUser(String userId) async =>
      _db.from('blocks').insert({'blocker_id': _myId, 'blocked_id': userId});

  static Future<void> unblockUser(String userId) async =>
      _db.from('blocks').delete()
          .eq('blocker_id', _myId).eq('blocked_id', userId);

  static Future<bool> isBlocked(String userId) async =>
      (await _db.from('blocks').select()
          .eq('blocker_id', _myId).eq('blocked_id', userId)).isNotEmpty;

  static Future<void> muteUser(String userId) async =>
      _db.from('mutes').insert({'user_id': _myId, 'muted_id': userId});

  static Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async =>
      _db.from('reports').insert({
        'reporter_id': _myId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'details': details,
      });
}