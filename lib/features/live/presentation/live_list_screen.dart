import 'package:flutter/material.dart';
import '../../../core/widgets/state_views.dart';
import '../data/live_repository.dart';
import 'go_live_screen.dart';
import 'live_watch_screen.dart';

class LiveListScreen extends StatelessWidget {
  const LiveListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🔴 Live')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const GoLiveScreen())),
          icon: const Icon(Icons.podcasts),
          label: const Text('Go Live'),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: LiveRepository.liveRooms(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return AppStates.empty(
                  title: 'এখন কেউ লাইভে নেই',
                  subtitle: 'প্রথম লাইভটি আপনিই শুরু করুন!',
                  icon: Icons.podcasts);
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final r = snap.data![i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LiveWatchScreen(room: r))),
                    leading: Stack(children: [
                      CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              (r['thumbnail_url'] ?? '').toString().isNotEmpty
                                  ? NetworkImage('${r['thumbnail_url']}')
                                  : null,
                          child: (r['thumbnail_url'] ?? '').toString().isEmpty
                              ? const Icon(Icons.podcasts)
                              : null),
                      const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                              radius: 7,
                              backgroundColor: Colors.red,
                              child: Text('L',
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)))),
                    ]),
                    title: Text('${r['title']}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${r['category']} • 👁 ${r['viewer_peak']} • ❤️ ${r['like_count']}'),
                    trailing: const Icon(Icons.play_circle_outline),
                  ),
                );
              },
            );
          },
        ),
      );
}