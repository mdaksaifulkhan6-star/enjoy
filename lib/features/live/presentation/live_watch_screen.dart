import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/live_repository.dart';

class LiveWatchScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  const LiveWatchScreen({super.key, required this.room});

  @override
  State<LiveWatchScreen> createState() => _LiveWatchScreenState();
}

class _LiveWatchScreenState extends State<LiveWatchScreen> {
  VideoPlayerController? _ctrl;
  RealtimeChannel? _presence;
  final _chatCtrl = TextEditingController();
  int _viewers = 1;
  bool _ended = false;

  String get _roomId => widget.room['id'] as String;
  bool get _isHost =>
      widget.room['is_host'] == true ||
      widget.room['host_id'] ==
          Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.room['stream_url']?.toString();
    if (url != null && url.isNotEmpty) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _ctrl!.play();
          }
        }).catchError((_) {});
    }
    _presence =
        Supabase.instance.client.channel('live-room-$_roomId')
          ..onPresenceSync((_) {
            // ✅ Version-safe: supabase_flutter 2.17+ presenceState()
            //    typing ভেদে Map / List / nullable হতে পারে — dynamic + is-check
            final dynamic s = _presence?.presenceState();
            final int n = s is Map
                ? s.length
                : s is List
                    ? s.length
                    : 1;
            if (mounted) setState(() => _viewers = n);
          })
          ..subscribe((st, [_]) async {
            if (st == RealtimeSubscribeStatus.subscribed) {
              await _presence?.track({'watching': true});
            }
          });
  }

  Future<void> _end() async {
    final res = await LiveRepository.endLive(_roomId);
    await _presence?.unsubscribe();
    if (mounted) {
      setState(() => _ended = true);
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('📊 Live Analytics'),
                content: res['ok'] == true
                    ? Text('⏱ ${res['duration_min']} মিনিট\n'
                        '👁 Peak Viewer: ${res['viewer_peak']}\n'
                        '❤️ Likes: ${res['likes']}\n'
                        '↗ Shares: ${res['shares']}')
                    : const Text('শেষ করা যায়নি'),
                actions: [
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('ঠিক আছে'))
                ],
              ));
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _presence?.unsubscribe();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await LiveRepository.sendChat(_roomId, text.trim());
      _chatCtrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🛡️ Moderation: মেসেজ ব্লক হয়েছে')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${widget.room['title'] ?? 'Live'}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Center(
                child: Text('👁 $_viewers',
                    style: const TextStyle(color: Colors.white))),
            IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => Share.share(
                    '🔴 "${widget.room['title']}" লাইভ দেখুন ENJOY-এ!')),
            if (_isHost && !_ended)
              IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red),
                  onPressed: _end),
          ],
        ),
        body: Column(children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _ended
                ? const Center(
                    child: Text('🔴 লাইভ শেষ হয়েছে',
                        style: TextStyle(color: Colors.white)))
                : (_ctrl != null && _ctrl!.value.isInitialized
                    ? VideoPlayer(_ctrl!)
                    : AppStates.loading(
                        message: 'স্ট্রিম লোড হচ্ছে…')),
          ),
          if (!_ended) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final r in ['❤️', '😂', '🔥', '👏', '😮'])
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      child: ActionChip(
                          label: Text(r),
                          onPressed: () =>
                              LiveRepository.react(_roomId, r)),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_alt,
                        size: 18, color: Colors.white),
                    label: const Text('FNF-কে ইনভাইট',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => Share.share(
                        '🔴 "${widget.room['title']}" লাইভ — ENJOY-এ দেখুন!'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color:
                    Theme.of(context).scaffoldBackgroundColor,
                child: StreamBuilder<
                    List<Map<String, dynamic>>>(
                  stream: LiveRepository.chatStream(_roomId),
                  builder: (context, snap) {
                    final msgs = snap.data ?? [];
                    return ListView.builder(
                      itemCount: msgs.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Text('💬 ${msgs[i]['text']}',
                            style: const TextStyle(
                                fontSize: 13)),
                      ),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Row(children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    decoration: const InputDecoration(
                        hintText:
                            'লাইভ চ্যাট… (AI moderation সক্রিয়)'),
                    onSubmitted: _sendChat,
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send,
                        color: AppColors.primary),
                    onPressed: () => _sendChat(_chatCtrl.text)),
              ]),
            ),
          ],
        ]),
      );
}