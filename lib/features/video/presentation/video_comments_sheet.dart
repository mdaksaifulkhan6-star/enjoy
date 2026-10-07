import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/video_repository.dart';

void showVideoCommentsSheet(BuildContext context, String videoId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VideoCommentsSheet(videoId: videoId),
  );
}

class _VideoCommentsSheet extends StatefulWidget {
  final String videoId;
  const _VideoCommentsSheet({required this.videoId});

  @override
  State<_VideoCommentsSheet> createState() => _VideoCommentsSheetState();
}

class _VideoCommentsSheetState extends State<_VideoCommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          const Text('কমেন্ট',
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: VideoRepository.commentsStream(widget.videoId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return const Center(
                      child: Text('প্রথম কমেন্ট করুন 👇'));
                }
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final c = rows[i];
                    return ListTile(
                      leading: const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 16)),
                      title: Text(c['text']?.toString() ?? ''),
                      trailing:
                          Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            timeago.format(
                                DateTime.parse('${c['created_at']}')),
                            style: const TextStyle(fontSize: 10)),
                        if (c['user_id'] == myId)
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18),
                              onPressed: () => VideoRepository
                                  .deleteComment('${c['id']}')),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(children: [
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                          hintText: 'কমেন্ট লিখুন…'))),
              IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: () async {
                    if (_ctrl.text.trim().isEmpty) return;
                    await VideoRepository.addComment(
                        widget.videoId, _ctrl.text.trim());
                    _ctrl.clear();
                  }),
            ]),
          ),
        ]),
      ),
    );
  }
}