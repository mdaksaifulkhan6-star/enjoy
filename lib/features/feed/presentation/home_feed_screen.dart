import 'package:flutter/material.dart';
import '../../../core/widgets/state_views.dart';
import '../data/post_repository.dart';
import 'create_post_screen.dart';
import 'post_card.dart';

/// Home Feed: For You (latest) • Trending • Hashtag search
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'আপনার জন্য'), Tab(text: '🔥 ট্রেন্ডিং')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            // Personalized Feed (latest, realtime)
            StreamBuilder<List<Post>>(
              stream: PostRepository.feedStream(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(
                      title: 'এখনো কোনো পোস্ট নেই',
                      subtitle: 'প্রথম পোস্টটি করুন!',
                      icon: Icons.dynamic_feed_outlined);
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) => PostCard(post: snap.data![i]),
                  ),
                );
              },
            ),
            // Trending
            FutureBuilder<List<Post>>(
              future: PostRepository.trending(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(title: 'কোনো ট্রেন্ডিং নেই');
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) => PostCard(post: snap.data![i]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('পোস্ট'),
      ),
    );
  }
}