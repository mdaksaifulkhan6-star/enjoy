import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class Video {
  final String id, authorId, title, videoUrl;
  final String? authorName, authorAvatar, description, thumbnailUrl, category;
  final List<String> tags;
  final String privacy;
  final bool isShort, allowDownload, copyrightProtected, borrowEligible;
  final int durationSeconds, views, watchSeconds, likeCount, commentCount;
  final DateTime createdAt;
  final String? myReaction;
  final bool isSaved;

  const Video({
    required this.id,
    required this.authorId,
    required this.title,
    required this.videoUrl,
    this.authorName,
    this.authorAvatar,
    this.description,
    this.thumbnailUrl,
    this.category,
    this.tags = const [],
    this.privacy = 'public',
    this.isShort = false,
    this.allowDownload = false,
    this.copyrightProtected = false,
    this.borrowEligible = false,
    this.durationSeconds = 0,
    this.views = 0,
    this.watchSeconds = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.myReaction,
    this.isSaved = false,
  });

  factory Video.fromMap(Map<String, dynamic> m) {
    final a = m['profiles'] as Map<String, dynamic>?;
    final likes = (m['video_likes'] as List?) ?? [];
    final saves = (m['video_saves'] as List?) ?? [];
    final myId = Supabase.instance.client.auth.currentUser?.id;
    String? myReaction;
    if (myId != null) {
      for (final l in likes) {
        if (l is Map && l['user_id'] == myId) {
          myReaction = l['reaction'] as String?;
          break;
        }
      }
    }
    return Video(
      id: m['id'] as String,
      authorId: m['author_id'] as String,
      title: m['title'] as String,
      videoUrl: m['video_url'] as String,
      authorName: a?['full_name'] as String?,
      authorAvatar: a?['avatar_url'] as String?,
      description: m['description'] as String?,
      thumbnailUrl: m['thumbnail_url'] as String?,
      category: m['category'] as String?,
      tags: (m['tags'] as List?)?.cast<String>() ?? [],
      privacy: m['privacy'] as String? ?? 'public',
      isShort: m['is_short'] as bool? ?? false,
      allowDownload: m['allow_download'] as bool? ?? false,
      copyrightProtected: m['copyright_protected'] as bool? ?? false,
      borrowEligible: m['borrow_eligible'] as bool? ?? false,
      durationSeconds: m['duration_seconds'] as int? ?? 0,
      views: m['views'] as int? ?? 0,
      watchSeconds: m['watch_seconds'] as int? ?? 0,
      likeCount: m['like_count'] as int? ?? 0,
      commentCount: m['comment_count'] as int? ?? 0,
      createdAt: DateTime.parse(m['created_at'] as String),
      myReaction: myReaction,
      isSaved: myId != null &&
          saves.any((s) => s is Map && s['user_id'] == myId),
    );
  }
}

class VideoRepository {
  VideoRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  // ════════ UPLOAD & PUBLISH ════════

  static Future<String> uploadVideoBytes(
      Uint8List bytes, String fileName) async {
    final path = 'videos/$_myId/$fileName';
    await _db.storage.from('media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
              upsert: true, contentType: 'video/mp4'),
        );
    return _db.storage.from('media').getPublicUrl(path);
  }

  static Future<String> uploadThumbnailBytes(
      Uint8List bytes, String fileName) async {
    final path = 'thumbs/$_myId/$fileName';
    await _db.storage.from('media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
              upsert: true, contentType: 'image/jpeg'),
        );
    return _db.storage.from('media').getPublicUrl(path);
  }

  static Future<void> publishVideo({
    required String title,
    required String videoUrl,
    String? description,
    String? thumbnailUrl,
    String? category,
    List<String> tags = const [],
    String privacy = 'public',
    bool allowDownload = false,
    bool copyrightProtected = false,
    bool borrowEligible = false,
    bool isShort = false,
    int durationSeconds = 0,
  }) async {
    _contentCheck(title, description);
    await _db.from('videos').insert({
      'author_id': _myId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'tags':
          tags.map((t) => t.toLowerCase().replaceAll('#', '')).toList(),
      'privacy': privacy,
      'allow_download': allowDownload,
      'copyright_protected': copyrightProtected,
      'borrow_eligible': borrowEligible,
      'is_short': isShort,
      'duration_seconds': durationSeconds,
    });
  }

  static void _contentCheck(String title, String? description) {
    const banned = ['violence-example', 'spam-word'];
    final text = '$title ${description ?? ''}'.toLowerCase();
    for (final w in banned) {
      if (text.contains(w)) {
        throw Exception('কনটেন্ট চেক ব্যর্থ: নিষিদ্ধ শব্দ পাওয়া গেছে');
      }
    }
  }

  // ════════ FEEDS ════════
  static Stream<List<Video>> videoFeed() {
    return _db
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('is_short', false)
        .eq('privacy', 'public')
        .order('created_at')
        .map((r) =>
            r.map(Video.fromMap).toList().reversed.toList());
  }

  static Stream<List<Video>> myVideos() {
    return _db
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('author_id', _myId)
        .order('created_at')
        .map((r) =>
            r.map(Video.fromMap).toList().reversed.toList());
  }

  // ════════ ENGAGEMENT ════════
  static Future<void> toggleReaction(String videoId,
      [String r = 'like']) async {
    final ex = await _db
        .from('video_likes')
        .select()
        .eq('video_id', videoId)
        .eq('user_id', _myId)
        .maybeSingle();
    if (ex != null) {
      await _db
          .from('video_likes')
          .delete()
          .eq('video_id', videoId)
          .eq('user_id', _myId);
    } else {
      await _db.from('video_likes').insert(
          {'video_id': videoId, 'user_id': _myId, 'reaction': r});
    }
  }

  static Future<void> toggleSave(String videoId) async {
    final ex = await _db
        .from('video_saves')
        .select()
        .eq('video_id', videoId)
        .eq('user_id', _myId)
        .maybeSingle();
    if (ex != null) {
      await _db
          .from('video_saves')
          .delete()
          .eq('video_id', videoId)
          .eq('user_id', _myId);
    } else {
      await _db
          .from('video_saves')
          .insert({'video_id': videoId, 'user_id': _myId});
    }
  }

  static Future<void> reportWatchTime(String videoId, int seconds) async {
    if (seconds <= 0) return;
    await _db.from('video_views').upsert({
      'video_id': videoId,
      'user_id': _myId,
      'watch_seconds': seconds,
      'last_watched': DateTime.now().toIso8601String(),
    }, onConflict: 'video_id,user_id');
    await _db
        .rpc('add_watch_seconds',
            params: {'v_id': videoId, 'secs': seconds})
        .catchError((_) async {
      final v = await _db
          .from('videos')
          .select('watch_seconds')
          .eq('id', videoId)
          .single();
      await _db.from('videos').update({
        'watch_seconds': (v['watch_seconds'] ?? 0) + seconds
      }).eq('id', videoId);
    });
  }

  // ════════ COMMENTS (video_comments টেবিল) ════════
  static Future<void> addComment(String videoId, String text) async {
    await _db.from('video_comments').insert(
        {'video_id': videoId, 'user_id': _myId, 'text': text});
  }

  static Stream<List<Map<String, dynamic>>> commentsStream(
      String videoId) {
    return _db
        .from('video_comments')
        .stream(primaryKey: ['id'])
        .eq('video_id', videoId)
        .order('created_at')
        .map((r) => r.reversed
            .map((x) => Map<String, dynamic>.from(x))
            .toList());
  }

  static Future<void> deleteComment(String commentId) async =>
      _db.from('video_comments').delete().eq('id', commentId);

  static Future<void> deleteVideo(String id) async =>
      _db.from('videos').delete().eq('id', id);
}