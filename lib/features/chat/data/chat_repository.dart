import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSummary {
  final String conversationId;
  final String? name;
  final String? avatar;
  final bool isGroup;
  final String? lastMessage;
  final String? lastType;
  final DateTime? lastAt;

  const ChatSummary({
    required this.conversationId,
    this.name,
    this.avatar,
    this.isGroup = false,
    this.lastMessage,
    this.lastType,
    this.lastAt,
  });

  factory ChatSummary.fromMap(Map<String, dynamic> m) => ChatSummary(
        conversationId: m['conversation_id'],
        name: m['conversations']?['name'],
        avatar: m['conversations']?['avatar_url'],
        isGroup: m['conversations']?['is_group'] ?? false,
        lastMessage: m['content'] ?? m['type'],
        lastType: m['type'],
        lastAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'])
            : null,
      );
}

class Message {
  final String id, senderId, type;
  final String? content, mediaUrl, replyToId;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.replyToId,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        id: m['id'],
        senderId: m['sender_id'],
        type: m['type'],
        content: m['content'],
        mediaUrl: m['media_url'],
        replyToId: m['reply_to_id'],
        createdAt: DateTime.parse(m['created_at']),
      );
}

/// Chat: 1-to-1 + Group, text/image/video/voice/file, reply, mention, reaction
class ChatRepository {
  ChatRepository._();

  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Chat list (latest message per conversation)
  static Future<List<ChatSummary>> chatList() async {
    final rows = await _db
        .from('conversation_members')
        .select(
            'conversation_id, conversations(name, avatar_url, is_group)')
        .eq('user_id', _myId);

    final list = <ChatSummary>[];
    for (final r in (rows as List)) {
      final msgs = await _db
          .from('messages')
          .select('content, type, created_at')
          .eq('conversation_id', r['conversation_id'])
          .order('created_at', ascending: false)
          .limit(1);
      list.add(ChatSummary.fromMap({
        'conversation_id': r['conversation_id'],
        'conversations': r['conversations'],
        'content':
            msgs.isNotEmpty ? msgs.first['content'] : null,
        'type': msgs.isNotEmpty ? msgs.first['type'] : null,
        'created_at':
            msgs.isNotEmpty ? msgs.first['created_at'] : null,
      }));
    }
    list.sort((a, b) => (b.lastAt ?? DateTime(2000))
        .compareTo(a.lastAt ?? DateTime(2000)));
    return list;
  }

  /// Get or create 1-to-1 conversation
  static Future<String> getOrCreateDirect(String otherUserId) async {
    final mine = await _db
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', _myId);
    for (final row in (mine as List)) {
      final convId = row['conversation_id'] as String;
      final other = await _db
          .from('conversation_members')
          .select()
          .eq('conversation_id', convId)
          .eq('user_id', otherUserId);
      if ((other as List).isNotEmpty) return convId;
    }
    final conv = await _db
        .from('conversations')
        .insert({'is_group': false, 'created_by': _myId})
        .select()
        .single();
    final convId = conv['id'] as String;
    await _db.from('conversation_members').insert([
      {'conversation_id': convId, 'user_id': _myId, 'role': 'admin'},
      {'conversation_id': convId, 'user_id': otherUserId, 'role': 'member'},
    ]);
    return convId;
  }

  /// Realtime messages
  static Stream<List<Message>> messagesStream(String convId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', convId)
        .order('created_at')
        .map((rows) => rows
            .map((r) => Message.fromMap(r as Map<String, dynamic>))
            .toList());
  }

  /// Send: text / image / video / voice / file + reply
  static Future<void> sendMessage({
    required String convId,
    String type = 'text',
    String? content,
    String? mediaUrl,
    String? replyToId,
  }) async {
    await _db.from('messages').insert({
      'conversation_id': convId,
      'sender_id': _myId,
      'type': type,
      'content': content,
      'media_url': mediaUrl,
      'reply_to_id': replyToId,
    });
    final members = await _db
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', convId)
        .neq('user_id', _myId);
    for (final m in (members as List)) {
      await _db.from('notifications').insert({
        'user_id': m['user_id'],
        'actor_id': _myId,
        'type': 'message',
        'message': content ?? '[$type]',
      });
    }
  }

  /// bytes দিয়ে আপলোড (image)
  static Future<String> uploadChatMediaBytes(
      Uint8List bytes, String fileName) async {
    final path = 'chat/$_myId/$fileName';
    await _db.storage.from('media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _db.storage.from('media').getPublicUrl(path);
  }

  /// bytes + contentType দিয়ে আপলোড (video / voice / file)
  static Future<String> uploadChatMediaTyped(
      Uint8List bytes, String fileName, String contentType) async {
    final path = 'chat/$_myId/$fileName';
    await _db.storage.from('media').uploadBinary(path, bytes,
        fileOptions:
            FileOptions(upsert: true, contentType: contentType));
    return _db.storage.from('media').getPublicUrl(path);
  }

  /// Reaction toggle (message_reactions)
  static Future<void> toggleReaction(
      String messageId, String emoji) async {
    final ex = await _db
        .from('message_reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', _myId)
        .maybeSingle();
    if (ex != null) {
      await _db
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', _myId);
    } else {
      await _db.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': _myId,
        'emoji': emoji
      });
    }
  }

  /// Group members (mention-এর জন্য)
  static Future<List<Map<String, dynamic>>> membersOf(
      String convId) async {
    final rows = await _db
        .from('conversation_members')
        .select('user_id, role, profiles(username, full_name)')
        .eq('conversation_id', convId);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}