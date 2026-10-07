import 'package:supabase_flutter/supabase_flutter.dart';

class Group {
  final String id;
  final String? name, avatarUrl;
  final int memberCount;
  final String? myRole;
  const Group({required this.id, this.name, this.avatarUrl,
      this.memberCount = 0, this.myRole});

  factory Group.fromMap(Map<String, dynamic> m) => Group(
        id: m['id'], name: m['name'], avatarUrl: m['avatar_url'],
        memberCount: m['member_count'] ?? 0, myRole: m['my_role'],
      );
}

class GroupMember {
  final String userId, name, role;
  final String? avatar;
  const GroupMember({required this.userId, required this.name,
      required this.role, this.avatar});
}

class GroupRepository {
  GroupRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Create group + conversation + members (creator = admin)
  static Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final conv = await _db.from('conversations').insert({
      'is_group': true, 'name': name, 'avatar_url': avatarUrl,
      'created_by': _myId,
    }).select().single();
    final convId = conv['id'] as String;

    final members = [
      {'conversation_id': convId, 'user_id': _myId, 'role': 'admin'},
      ...memberIds.map((id) =>
          {'conversation_id': convId, 'user_id': id, 'role': 'member'}),
    ];
    await _db.from('conversation_members').insert(members);
    return convId;
  }

  static Future<List<Group>> myGroups() async {
    final rows = await _db.from('conversation_members')
        .select('conversations!inner(id, name, avatar_url, is_group), role')
        .eq('user_id', _myId).eq('conversations.is_group', true);
    final groups = <Group>[];
    for (final r in (rows as List)) {
      final conv = r['conversations'] as Map<String, dynamic>;
      final count = await _db.from('conversation_members')
          .select('user_id').eq('conversation_id', conv['id']);
      groups.add(Group.fromMap({
        ...conv, 'my_role': r['role'],
        'member_count': (count as List).length,
      }));
    }
    return groups;
  }

  static Future<String?> conversationIdOf(String groupId) async {
    // group id IS conversation id in this schema
    return groupId;
  }

  static Future<List<GroupMember>> membersOf(String convId) async {
    final rows = await _db.from('conversation_members')
        .select('user_id, role, profiles(full_name, avatar_url)')
        .eq('conversation_id', convId);
    return (rows as List).map((m) {
      final p = m['profiles'] as Map<String, dynamic>?;
      return GroupMember(
        userId: m['user_id'], name: p?['full_name'] ?? '',
        role: m['role'], avatar: p?['avatar_url'],
      );
    }).toList();
  }

  /// Promote to moderator/admin, remove member (admin only, enforced by RLS + check)
  static Future<void> changeRole(String convId, String userId, String role) async {
    final my = await _db.from('conversation_members').select('role')
        .eq('conversation_id', convId).eq('user_id', _myId).single();
    if (my['role'] != 'admin') throw Exception('শুধু অ্যাডমিন এটা করতে পারেন');
    await _db.from('conversation_members')
        .update({'role': role})
        .eq('conversation_id', convId).eq('user_id', userId);
  }

  static Future<void> removeMember(String convId, String userId) async {
    await _db.from('conversation_members').delete()
        .eq('conversation_id', convId).eq('user_id', userId);
  }
}