import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/post_repository.dart';

void showCommentsSheet(BuildContext context, String postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CommentsSheet(postId: postId),
  );
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text('কমেন্ট',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: PostRepository.commentsStream(widget.postId),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  if (snap.data!.isEmpty) {
                    return const Center(child: Text('প্রথম কমেন্ট করুন 👇'));
                  }
                  return ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final c = snap.data![i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: c.userAvatar != null
                              ? NetworkImage(c.userAvatar!) : null,
                          child: c.userAvatar == null
                              ? const Icon(Icons.person, size: 16) : null,
                        ),
                        title: Text(c.userName ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text(c.text),
                        trailing: Text(timeago.format(c.createdAt),
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                          hintText: 'কমেন্ট লিখুন…'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: () async {
                      if (_ctrl.text.trim().isEmpty) return;
                      await PostRepository.addComment(
                          widget.postId, _ctrl.text.trim());
                      _ctrl.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}