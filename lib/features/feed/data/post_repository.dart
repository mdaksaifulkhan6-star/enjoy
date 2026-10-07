import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class Post {
  final String id;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final String? text;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final String? myReaction;
  final bool isSaved;

  const Post({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    this.text,
    this.mediaUrls = const [],
    this.hashtags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    this.myReaction,
    this.isSaved = false,
  });

  factory Post.fromMap(Map<String, dynamic> m) {
    final author = m['profiles'] as Map<String, dynamic>?;
    final likes = (m['likes'] as List?) ?? [];
    final saves = (m['saves'] as List?) ?? [];
    final myId = Supabase.instance.client.auth.currentUser?.id;

    // ✅ শুধু আমার নিজের reaction (অন্যদের লাইকে আমার বাটন active হবে না)
    String? myReaction;
    if (myId != null) {
      for (final l in likes) {
        if (l is Map && l['user_id'] == myId) {
          myReaction = l['reaction'] as String?;
          break;
        }
      }
    }

    return Post(
      id: m['id'] as String,
      authorId: m['author_id'] as String,
      authorName: author?['full_name'] as String?,
      authorAvatar: author?['avatar_url'] as String?,
      text: m['text'] as String?,
      mediaUrls: (m['media_urls'] as List?)?.cast<String>() ?? [],
      hashtags: (m['hashtags'] as List?)?.cast<String>() ?? [],
      likeCount: m['like_count'] as int? ?? 0,
      commentCount: m['comment_count'] as int? ?? 0,
      shareCount: m['share_count'] as int? ?? 0,
      createdAt: DateTime.parse(m['created_at'] as String),
      myReaction: myReaction,
      isSaved: myId != null &&
          saves.any((s) => s is Map && s['user_id'] == myId),
    );
  }
}

class Comment {
  final String id, userId, text;
  final String? userName, userAvatar;
  final DateTime createdAt;
  const Comment({
    required this.id,
    required this.userId,
    required this.text,
    this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> m) {
    final p = m['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      text: m['text'] as String,
      userName: p?['full_name'] as String?,
      userAvatar: p?['avatar_url'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

class PostRepository {
  PostRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static List<String> extractHashtags(String text) {
    final matches = RegExp(r'#(\w+)').allMatches(text);
    return matches
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  /// Web + Mobile safe: bytes দিয়ে আপলোড
  static Future<String> uploadMediaBytes(
      Uint8List bytes, String fileName) async {
    final path = 'posts/$_myId/$fileName';
    await _db.storage.from('media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _db.storage.from('media').getPublicUrl(path);
  }

  static Future<void> createPost({
    required String text,
    List<String> mediaUrls = const [],
  }) async {
    await _db.from('posts').insert({
      'author_id': _myId,
      'text': text,
      'media_urls': mediaUrls,
      'hashtags': extractHashtags(text),
    });
  }

  static Stream<List<Post>> feedStream() {
    return _db
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) =>
            rows.map(Post.fromMap).toList().reversed.toList());
  }

  static Future<List<Post>> trending() async {
    final rows = await _db
        .from('posts')
        .select(
            '*, profiles(full_name, avatar_url), likes(user_id, reaction), saves(user_id)')
        .order('created_at', ascending: false)
        .limit(50);
    final posts = <Post>[
      for (final m in (rows as List)) Post.fromMap(m),
    ];
    posts.sort((a, b) =>
        (b.likeCount * 3 + b.commentCount * 2 + b.shareCount)
            .compareTo(a.likeCount * 3 + a.commentCount * 2 + a.shareCount));
    return posts;
  }

  static Future<List<Post>> searchByHashtag(String tag) async {
    final rows = await _db
        .from('posts')
        .select(
            '*, profiles(full_name, avatar_url), likes(user_id, reaction), saves(user_id)')
        .contains('hashtags', [tag.toLowerCase()]);
    return [for (final m in (rows as List)) Post.fromMap(m)];
  }

  static Future<void> toggleReaction(String postId,
      [String reaction = 'like']) async {
    final existing = await _db
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', _myId)
        .maybeSingle();
    if (existing != null) {
      await _db
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _myId);
    } else {
      await _db.from('likes').insert(
          {'post_id': postId, 'user_id': _myId, 'reaction': reaction});
    }
  }

  static Future<void> toggleSave(String postId) async {
    final existing = await _db
        .from('saves')
        .select()
        .eq('post_id', postId)
        .eq('user_id', _myId)
        .maybeSingle();
    if (existing != null) {
      await _db
          .from('saves')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _myId);
    } else {
      await _db
          .from('saves')
          .insert({'post_id': postId, 'user_id': _myId});
    }
  }

  static Future<void> incrementShare(String postId) async {
    await _db.rpc('increment', params: {
      'table_name': 'posts',
      'row_id': postId,
      'column_name': 'share_count'
    }).catchError((_) async {
      final p = await _db
          .from('posts')
          .select('share_count')
          .eq('id', postId)
          .single();
      await _db
          .from('posts')
          .update({'share_count': (p['share_count'] ?? 0) + 1})
          .eq('id', postId);
    });
  }

  static Future<void> addComment(String postId, String text) async {
    await _db.from('comments').insert(
        {'post_id': postId, 'user_id': _myId, 'text': text});
  }

  static Stream<List<Comment>> commentsStream(String postId) {
    return _db
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .map((rows) => rows.map(Comment.fromMap).toList());
  }

  static Future<void> deletePost(String postId) async {
    await _db.from('posts').delete().eq('id', postId);
  }
}