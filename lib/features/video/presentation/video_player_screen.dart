import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/video_repository.dart';
import 'video_action_bar.dart';

/// Full video player + views + watch time tracking + action bar
class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _ctrl;
  int _watched = 0; // seconds tracked this session
  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _ctrl.play();
      });
    _lastTick = DateTime.now();
  }

  @override
  void dispose() {
    _flushWatchTime();
    _ctrl.dispose();
    super.dispose();
  }

  void _flushWatchTime() {
    final now = DateTime.now();
    if (_lastTick != null && _ctrl.value.isPlaying) {
      _watched += now.difference(_lastTick!).inSeconds;
      VideoRepository.reportWatchTime(widget.video.id, _watched);
    }
    _lastTick = now;
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _ctrl.value.isInitialized
                ? _ctrl.value.aspectRatio : 16 / 9,
            child: _ctrl.value.isInitialized
                ? VideoPlayer(_ctrl)
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_ctrl.value.isInitialized)
            VideoProgressIndicator(_ctrl, allowScrubbing: true),
          if (_ctrl.value.isInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text('${_fmt(_ctrl.value.position)} / ${_fmt(_ctrl.value.duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_ctrl.value.isPlaying
                        ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      setState(() => _ctrl.value.isPlaying
                          ? _ctrl.pause() : _ctrl.play());
                      _flushWatchTime();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: v.authorAvatar != null
                            ? NetworkImage(v.authorAvatar!) : null,
                        child: v.authorAvatar == null
                            ? const Icon(Icons.person, size: 18) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.authorName ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                                '${v.views} ভিউ • ${_fmt(Duration(seconds: v.watchSeconds))} ওয়াচ টাইম',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (v.description != null) ...[
                    const SizedBox(height: 12),
                    Text(v.description!),
                  ],
                  if (v.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: [
                      for (final t in v.tags)
                        Chip(label: Text('#$t'), visualDensity: VisualDensity.compact),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  VideoActionBar(video: v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}