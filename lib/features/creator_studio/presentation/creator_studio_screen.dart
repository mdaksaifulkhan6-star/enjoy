import 'package:flutter/material.dart';
import '../../channel/presentation/channels_screen.dart';
import '../../video/presentation/upload_video_screen.dart';
import '../../shorts/presentation/create_short_screen.dart';
import '../../feed/presentation/create_post_screen.dart';
import '../../boost/presentation/boost_screen.dart';
import '../../borrow/presentation/borrow_analytics_screen.dart';
import '../../games/presentation/games_hub_screen.dart';
import '../../learning/presentation/courses_screen.dart';
import '../../live/presentation/go_live_screen.dart';
import '../../tv/presentation/tv_screen.dart';
import '../../ai/presentation/ai_assistant_screen.dart';
import '../../editor/presentation/photo_editor_screen.dart';
import '../../editor/presentation/video_editor_screen.dart';
import 'monetization_screen.dart';
import 'earnings_screen.dart';

class CreatorStudioScreen extends StatelessWidget {
  const CreatorStudioScreen({super.key});

  static const _items = [
    ('ভিডিও', Icons.videocam, 'video'),
    ('শর্টস', Icons.play_circle, 'short'),
    ('ফটো/পোস্ট', Icons.photo, 'post'),
    ('ছবি এডিটর', Icons.photo_filter, 'photo_editor'),
    ('ভিডিও এডিটর', Icons.movie_edit, 'video_editor'),
    ('চ্যানেল', Icons.tv, 'channel'),
    ('লাইভ', Icons.podcasts, 'live'),
    ('ENJOY TV', Icons.live_tv, 'tv'),
    ('AI স্টুডিও', Icons.smart_toy, 'ai'),
    ('মনিটাইজেশন', Icons.monetization_on, 'monetization'),
    ('আয়', Icons.account_balance_wallet, 'earnings'),
    ('বুস্ট', Icons.rocket_launch, 'boost'),
    ('এনালিটিক্স', Icons.bar_chart, 'analytics'),
    ('কোর্স', Icons.school, 'courses'),
    ('গেমস', Icons.sports_esports, 'games'),
  ];

  void _open(BuildContext context, String key) {
    final routes = <String, Widget>{
      'video': const UploadVideoScreen(),
      'short': const CreateShortScreen(),
      'post': const CreatePostScreen(),
      'photo_editor': const PhotoEditorScreen(),
      'video_editor': const VideoEditorScreen(),
      'channel': const ChannelsScreen(),
      'live': const GoLiveScreen(),
      'tv': const TvScreen(),
      'ai': const AiAssistantScreen(),
      'monetization': const MonetizationScreen(),
      'earnings': const EarningsScreen(),
      'boost': const BoostScreen(),
      'analytics': const BorrowAnalyticsScreen(),
      'courses': const CoursesScreen(),
      'games': const GamesHubScreen(),
    };
    final w = routes[key];
    if (w != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('শীঘ্রই আসছে')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Creator Studio 🎬')),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12),
          itemCount: _items.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => _open(context, _items[i].$3),
            borderRadius: BorderRadius.circular(16),
            child: Card(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_items[i].$2, size: 32),
                    const SizedBox(height: 8),
                    Text(_items[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ]),
            ),
          ),
        ),
      );
}