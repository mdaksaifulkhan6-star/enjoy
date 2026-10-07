import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/fnf_repository.dart';
import 'user_profile_screen.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/presentation/chat_room_screen.dart';
import '../../groups/data/group_repository.dart';
import '../../chat/presentation/create_group_screen.dart';
import '../../chat/presentation/chats_list_screen.dart';

/// FNF tab: Search • Requests • Friends • Groups
class FnfScreen extends StatefulWidget {
  const FnfScreen({super.key});

  @override
  State<FnfScreen> createState() => _FnfScreenState();
}

class _FnfScreenState extends State<FnfScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FNF'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'বন্ধুরা'),
          Tab(text: 'রিকোয়েস্ট'),
          Tab(text: 'গ্রুপ'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatsListScreen())),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FriendsTab(),
          _RequestsTab(onChanged: () => setState(() {})),
          _GroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
        icon: const Icon(Icons.group_add),
        label: const Text('নতুন গ্রুপ'),
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<List<FnfUser>>(
        future: FnfRepository.myFriends(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          if (snap.data!.isEmpty) {
            return AppStates.empty(
                title: 'কোনো FNF নেই',
                subtitle: 'বন্ধু খুঁজে রিকোয়েস্ট পাঠান',
                icon: Icons.group_outlined);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('মোট FNF: ${snap.data!.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final u = snap.data![i];
                    return ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => UserProfileScreen(user: u))),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                u.avatar != null ? NetworkImage(u.avatar!) : null,
                            child: u.avatar == null
                                ? const Icon(Icons.person) : null,
                          ),
                          if (u.displayOnline)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.online,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(u.name),
                      subtitle: Text(u.displayOnline
                          ? '🟢 অনলাইন'
                          : 'সর্বশেষ: ${u.lastActive ?? '-'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () async {
                          final convId = await ChatRepository
                              .getOrCreateDirect(u.id);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                    conversationId: convId, title: u.name)));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}

class _RequestsTab extends StatelessWidget {
  final VoidCallback onChanged;
  const _RequestsTab({required this.onChanged});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FnfRequest>>(
        future: FnfRepository.incomingRequests(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          if (snap.data!.isEmpty) {
            return AppStates.empty(
                title: 'কোনো রিকোয়েস্ট নেই', icon: Icons.mail_outline);
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final r = snap.data![i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: r.senderAvatar != null
                      ? NetworkImage(r.senderAvatar!) : null,
                  child: r.senderAvatar == null
                      ? const Icon(Icons.person) : null,
                ),
                title: Text(r.senderName),
                subtitle: const Text('FNF রিকোয়েস্ট পাঠিয়েছে'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: AppColors.online),
                      onPressed: () async {
                        await FnfRepository.accept(r.id);
                        onChanged();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                      onPressed: () async {
                        await FnfRepository.reject(r.id);
                        onChanged();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
}

class _GroupsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Group>>(
        future: GroupRepository.myGroups(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          if (snap.data!.isEmpty) {
            return AppStates.empty(
                title: 'কোনো গ্রুপ নেই',
                subtitle: 'নতুন গ্রুপ তৈরি করুন',
                icon: Icons.groups_outlined);
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final g = snap.data![i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(g.name ?? 'গ্রুপ'),
                subtitle: Text('${g.memberCount} সদস্য'),
                onTap: () async {
                  final convId = await GroupRepository.conversationIdOf(g.id);
                  if (context.mounted && convId != null) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                            conversationId: convId,
                            title: g.name ?? 'গ্রুপ',
                            isGroup: true,
                            groupId: g.id)));
                  }
                },
              );
            },
          );
        },
      );
}