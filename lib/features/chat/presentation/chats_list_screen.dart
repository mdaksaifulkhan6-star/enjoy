import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/widgets/state_views.dart';
import '../data/chat_repository.dart';
import 'chat_room_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('চ্যাট')),
        body: FutureBuilder<List<ChatSummary>>(
          future: ChatRepository.chatList(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return AppStates.empty(
                  title: 'কোনো চ্যাট নেই',
                  subtitle: 'FNF তালিকা থেকে বন্ধুকে মেসেজ দিন',
                  icon: Icons.chat_bubble_outline);
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final c = snap.data![i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(c.isGroup ? Icons.groups : Icons.person)),
                  title: Text(c.isGroup
                      ? (c.name ?? 'গ্রুপ') : (c.name ?? 'চ্যাট')),
                  subtitle: Text(
                    c.lastType == 'text'
                        ? (c.lastMessage ?? '')
                        : '[${c.lastType ?? ''}]',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: c.lastAt != null
                      ? Text(timeago.format(c.lastAt!), style: const TextStyle(fontSize: 11))
                      : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                          conversationId: c.conversationId,
                          title: c.name ?? 'চ্যাট',
                          isGroup: c.isGroup))),
                );
              },
            );
          },
        ),
      );
}