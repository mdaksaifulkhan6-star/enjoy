import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/state_views.dart';
import '../../video/data/video_repository.dart';
import '../data/shorts_repository.dart';
import '../../video/presentation/video_action_bar.dart';

/// Shorts — vertical swipe feed (PageView)
class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Video>>(
        stream: ShortsRepository.shortsFeed(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          if (snap.data!.isEmpty) {
            return AppStates.empty(
                title: 'কোনো শর্ট নেই',
                subtitle: 'প্রথম শর্ট তৈরি করুন!',
                icon: Icons.play_circle_outline);
          }
          return PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: snap.data!.length,
            itemBuilder: (_, i) => _ShortPlayer(video: snap.data![i]),
          );
        },
      ),
    );
  }
}

class _ShortPlayer extends StatefulWidget {
  final Video video;
  const _ShortPlayer({required this.video});

  @override
  State<_ShortPlayer> createState() => _ShortPlayerState();
}

class _ShortPlayerState extends State<_ShortPlayer> {
  late VideoPlayerController _ctrl;
  int _watched = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _ctrl.setLooping(true);
          _ctrl.play();
        }
      });
  }

  @override
  void dispose() {
    if (_ctrl.value.isInitialized) {
      _watched = _ctrl.value.position.inSeconds;
      VideoRepository.reportWatchTime(widget.video.id, _watched);
    }
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return GestureDetector(
      onTap: () => setState(() =>
          _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ctrl.value.isInitialized
              ? Center(child: AspectRatio(
                  aspectRatio: _ctrl.value.aspectRatio,
                  child: VideoPlayer(_ctrl)))
              : const Center(child: CircularProgressIndicator()),
          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black38, Colors.transparent, Colors.black54]),
            ),
          ),
          // Right action rail
          Positioned(
            right: 8, bottom: 80,
            child: VideoActionBar(video: v),
          ),
          // Bottom info
          Positioned(
            left: 12, right: 90, bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${v.authorName ?? ''}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Text(v.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white)),
                if (v.tags.isNotEmpty)
                  Text(v.tags.map((t) => '#$t').join(' '),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (_ctrl.value.isInitialized && !_ctrl.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 72, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}