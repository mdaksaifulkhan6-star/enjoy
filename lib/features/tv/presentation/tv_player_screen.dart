import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/state_views.dart';
import '../data/tv_repository.dart';

class TvPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> channel;
  const TvPlayerScreen({super.key, required this.channel});

  @override
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel['stream_url'] as String))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _ctrl!.play();
        }
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.channel['name']}')),
        body: Column(children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: (_ctrl != null && _ctrl!.value.isInitialized)
                ? VideoPlayer(_ctrl!)
                : AppStates.loading(message: 'চ্যানেল লোড হচ্ছে…'),
          ),
          if (_ctrl != null && _ctrl!.value.isInitialized)
            IconButton(
              icon: Icon(_ctrl!.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => setState(() =>
                  _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play()),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('📅 শো সূচি',
                    style: TextStyle(fontWeight: FontWeight.w800))),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: TvRepository.shows(widget.channel['id'] as String),
              builder: (context, snap) {
                final shows = snap.data ?? [];
                if (shows.isEmpty) {
                  return const Center(
                      child: Text('কোনো শো নেই',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView(children: [
                  for (final s in shows)
                    ListTile(
                      leading: const Icon(Icons.tv),
                      title: Text('${s['title']}'),
                      subtitle:
                          Text('${s['starts_at'] ?? ''} — ${s['ends_at'] ?? ''}'),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}