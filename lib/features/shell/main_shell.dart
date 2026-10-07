import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';
import '../feed/presentation/home_feed_screen.dart';
import '../feed/presentation/create_post_screen.dart';
import '../feed/presentation/search_screen.dart';
import '../feed/presentation/notifications_screen.dart';
import '../fnf/presentation/fnf_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../shorts/presentation/shorts_screen.dart';
import '../shorts/presentation/create_short_screen.dart';
import '../video/presentation/upload_video_screen.dart';
import '../chat/presentation/chats_list_screen.dart';
import '../live/presentation/live_list_screen.dart';

/// Top Navigation + Bottom Navigation per Master Plan.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabItem('হোম', Icons.home_outlined, Icons.home),
    _TabItem('শর্টস', Icons.play_circle_outline, Icons.play_circle),
    _TabItem('তৈরি করুন', Icons.add_circle_outline, Icons.add_circle),
    _TabItem('FNF', Icons.group_outlined, Icons.group),
    _TabItem('প্রোফাইল', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo/enjoy_logo.png', height: 38),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.podcasts_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LiveListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChatsListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: ConnectivityService.onStatusChange,
            initialData: true,
            builder: (context, snap) {
              final online = snap.data ?? true;
              if (online) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  '⚠️ ইন্টারনেট সংযোগ নেই',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                HomeFeedScreen(),
                ShortsScreen(),
                CreateHub(),
                FnfScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

/// তৈরি করুন hub — ভিডিও / শর্ট / ফটো পোস্ট
class CreateHub extends StatelessWidget {
  const CreateHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UploadVideoScreen())),
            icon: const Icon(Icons.videocam),
            label: const Text('ভিডিও আপলোড'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateShortScreen())),
            icon: const Icon(Icons.play_circle),
            label: const Text('শর্ট তৈরি করুন'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreatePostScreen())),
            icon: const Icon(Icons.photo),
            label: const Text('ফটো পোস্ট'),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _TabItem(this.label, this.icon, this.selectedIcon);
}