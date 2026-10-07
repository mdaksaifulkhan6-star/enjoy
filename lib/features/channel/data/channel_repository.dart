import 'package:supabase_flutter/supabase_flutter.dart';

class Channel {
  final String id, ownerId, handle, name;
  final String? description, avatarUrl, bannerUrl;
  final bool verified, isBrand;
  const Channel({required this.id, required this.ownerId, required this.handle,
      required this.name, this.description, this.avatarUrl, this.bannerUrl,
      this.verified = false, this.isBrand = false});
  factory Channel.fromMap(Map<String, dynamic> m) => Channel(
        id: m['id'], ownerId: m['owner_id'], handle: m['handle'], name: m['name'],
        description: m['description'], avatarUrl: m['avatar_url'],
        bannerUrl: m['banner_url'], verified: m['verified'] ?? false,
        isBrand: m['is_brand'] ?? false);
}

class Playlist {
  final String id, channelId, title;
  final String? description;
  const Playlist({required this.id, required this.channelId,
      required this.title, this.description});
  factory Playlist.fromMap(Map<String, dynamic> m) => Playlist(
      id: m['id'], channelId: m['channel_id'], title: m['title'],
      description: m['description']);
}

class ChannelRepository {
  ChannelRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static Future<List<Channel>> myChannels() async {
    final rows = await _db.from('channels')
        .select().eq('owner_id', _myId).order('created_at');
    return (rows as List)
        .map((r) => Channel.fromMap(r as Map<String, dynamic>)).toList();
  }

  static Future<Channel> createChannel(String name, String handle,
      {String? description, bool isBrand = false}) async {
    final clean = handle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.length < 3) throw Exception('Handle কমপক্ষে ৩ অক্ষর');
    final row = await _db.from('channels').insert({
      'owner_id': _myId, 'name': name, 'handle': clean,
      'description': description, 'is_brand': isBrand,
    }).select().single();
    return Channel.fromMap(row);
  }

  static Future<Channel?> byHandle(String handle) async {
    final row = await _db.from('channels')
        .select().eq('handle', handle.toLowerCase()).maybeSingle();
    return row == null ? null : Channel.fromMap(row);
  }

  static Future<Channel?> byOwnerId(String ownerId) async {
    final row = await _db.from('channels')
        .select().eq('owner_id', ownerId).order('created_at').limit(1)
        .maybeSingle();
    return row == null ? null : Channel.fromMap(row);
  }

  static Future<Channel> updateChannel(String id,
      {String? name, String? description, String? avatarUrl, String? bannerUrl}) async {
    final row = await _db.from('channels').update({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
    }).eq('id', id).select().single();
    return Channel.fromMap(row);
  }

  static Future<void> deleteChannel(String id) async =>
      _db.from('channels').delete().eq('id', id);

  /// Moderation: moderator যোগ (শুধু owner — RLS enforce করে)
  static Future<void> addModerator(String channelId, String userId) async =>
      _db.from('channel_moderators')
          .insert({'channel_id': channelId, 'user_id': userId});

  static Future<List<Playlist>> playlists(String channelId) async {
    final rows = await _db.from('playlists')
        .select().eq('channel_id', channelId).order('created_at');
    return (rows as List)
        .map((r) => Playlist.fromMap(r as Map<String, dynamic>)).toList();
  }

  static Future<void> createPlaylist(String channelId, String title) async =>
      _db.from('playlists').insert({'channel_id': channelId, 'title': title});
}