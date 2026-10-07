import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../video/data/video_repository.dart';
import '../../video/presentation/video_player_screen.dart';
import '../../fnf/data/fnf_repository.dart';
import '../../fnf/presentation/user_profile_screen.dart';
import '../../feed/data/post_repository.dart';
import '../../feed/presentation/post_card.dart';
import '../data/channel_repository.dart';

class ChannelProfileScreen extends StatefulWidget {
  final Channel channel;
  const ChannelProfileScreen({super.key, required this.channel});

  @override
  State<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends State<ChannelProfileScreen> {
  String _relation = 'none';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await FnfRepository.relationshipWith(widget.channel.ownerId);
    if (mounted) setState(() => _relation = r);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.channel;
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: c.bannerUrl != null
                    ? Image.network(c.bannerUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.brandGradient)),
              ),
              title: Row(children: [
                Flexible(
                    child: Text(c.name,
                        overflow: TextOverflow.ellipsis)),
                if (c.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified,
                      size: 18, color: Colors.white),
                ],
              ]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${c.handle}',
                        style: TextStyle(color: Colors.grey.shade600)),
                    if (c.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(c.description!),
                      ),
                    const SizedBox(height: 12),
                    // ⚠️ Master Plan: No subscribe — Channel Relationship = FNF
                    _relation == 'accepted'
                        ? FilledButton.tonalIcon(
                            onPressed: () async {
                              await FnfRepository.removeFriend(c.ownerId);
                              _load();
                            },
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('FNF ✓ (চ্যানেল রিলেশন)'))
                        : FilledButton.icon(
                            onPressed: _relation.startsWith('pending')
                                ? null
                                : () async {
                                    await FnfRepository.sendRequest(
                                        c.ownerId);
                                    _load();
                                  },
                            icon: const Icon(Icons.person_add_alt),
                            label: Text(_relation == 'pending_sent'
                                ? 'রিকোয়েস্ট পাঠানো হয়েছে'
                                : 'FNF করুন')),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                  user: FnfUser(
                                      id: c.ownerId,
                                      name: c.name,
                                      avatar: c.avatarUrl)))),
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('মালিকের প্রোফাইল'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: TabBar(tabs: [
                Tab(text: 'ভিডিও'),
                Tab(text: 'পোস্ট'),
                Tab(text: 'প্লেলিস্ট')
              ]),
            ),
          ],
          body: TabBarView(children: [
            StreamBuilder<List<Video>>(
              stream: VideoRepository.videoFeed(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                final mine = (snap.data!)
                    .where((v) => v.authorId == c.ownerId)
                    .toList();
                if (mine.isEmpty) {
                  return AppStates.empty(title: 'কোনো ভিডিও নেই');
                }
                return ListView(children: [
                  for (final v in mine)
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(v.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${v.views} ভিউ • ${v.likeCount} লাইক'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  VideoPlayerScreen(video: v))),
                    ),
                ]);
              },
            ),
            StreamBuilder<List<Post>>(
              stream: PostRepository.feedStream(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                final mine = (snap.data!)
                    .where((p) => p.authorId == c.ownerId)
                    .toList();
                if (mine.isEmpty) {
                  return AppStates.empty(title: 'কোনো পোস্ট নেই');
                }
                return ListView.builder(
                    itemCount: mine.length,
                    itemBuilder: (_, i) => PostCard(post: mine[i]));
              },
            ),
            FutureBuilder<List<Playlist>>(
              future: ChannelRepository.playlists(c.id),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(
                      title: 'কোনো প্লেলিস্ট নেই',
                      icon: Icons.playlist_play);
                }
                return ListView(children: [
                  for (final p in snap.data!)
                    ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(p.title),
                      subtitle: p.description != null
                          ? Text(p.description!)
                          : null,
                    ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }
}