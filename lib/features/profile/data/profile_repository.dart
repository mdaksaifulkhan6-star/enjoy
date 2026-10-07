import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final bool showOnlineStatus;
  final DateTime? lastActive;

  const Profile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.showOnlineStatus = true,
    this.lastActive,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        username: m['username'] as String?,
        fullName: m['full_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        bio: m['bio'] as String?,
        isOnline: m['is_online'] ?? false,
        showOnlineStatus: m['show_online_status'] ?? true,
        lastActive: m['last_active'] != null
            ? DateTime.tryParse(m['last_active'])
            : null,
      );

  /// Display-safe online status (respects privacy setting)
  bool get displayOnline => isOnline && showOnlineStatus;
}

/// Profile & Account — Supabase backed.
class ProfileRepository {
  ProfileRepository._();

  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Creates profile row if missing (defense-in-depth; DB trigger also does it).
  static Future<Profile> ensureMyProfile() async {
    final existing = await _db
        .from('profiles')
        .select()
        .eq('id', _myId)
        .maybeSingle();

    if (existing != null) return Profile.fromMap(existing);

    final user = _db.auth.currentUser!;
    final inserted = await _db
        .from('profiles')
        .insert({
          'id': _myId,
          'full_name': user.userMetadata?['full_name'] ?? '',
          'avatar_url': user.userMetadata?['avatar_url'],
          'username':
              (user.email ?? 'user').split('@').first.toLowerCase(),
        })
        .select()
        .single();
    return Profile.fromMap(inserted);
  }

  static Future<Profile> getMyProfile() async {
    final data =
        await _db.from('profiles').select().eq('id', _myId).single();
    return Profile.fromMap(data);
  }

  static Future<Profile> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    bool? showOnlineStatus,
  }) async {
    final payload = <String, dynamic>{
      if (username != null) 'username': username,
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (showOnlineStatus != null) 'show_online_status': showOnlineStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final data = await _db
        .from('profiles')
        .update(payload)
        .eq('id', _myId)
        .select()
        .single();
    return Profile.fromMap(data);
  }

  /// Online / Offline / Last Active
  static Future<void> setOnlineStatus(bool online) async {
    await _db.from('profiles').update({
      'is_online': online,
      'last_active': DateTime.now().toIso8601String(),
    }).eq('id', _myId);
  }

  /// Realtime profile stream (own profile + others in later phases)
  static Stream<Profile> watchProfile(String userId) {
    return _db
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => Profile.fromMap(rows.first));
  }
}