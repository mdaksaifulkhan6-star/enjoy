import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../ai/data/ai_service.dart';
import '../../fnf/data/fnf_repository.dart';
import '../../fnf/presentation/user_profile_screen.dart';
import '../../channel/data/channel_repository.dart';
import '../../channel/presentation/channel_profile_screen.dart';
import '../../video/data/video_repository.dart';
import '../../video/presentation/video_player_screen.dart';
import '../../borrow/presentation/borrow_history_screen.dart';
import '../../fnf/presentation/fnf_screen.dart';
import '../../games/presentation/games_hub_screen.dart';
import '../../learning/presentation/courses_screen.dart';
import '../../live/presentation/live_watch_screen.dart';
import '../../tv/presentation/tv_player_screen.dart';

/// Unified Search: People/Videos/Shorts/Posts/Channels/Groups/Games/Courses/Live/TV/Borrow
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  Map<String, dynamic>? _results;
  bool _loading = false;
  String _filter = 'all';

  static const _filters = {
    'all': 'সব', 'people': 'মানুষ', 'videos': 'ভিডিও', 'shorts': 'শর্টস',
    'posts': 'পোস্ট', 'channels': 'চ্যানেল', 'groups': 'গ্রুপ',
    'games': 'গেম', 'courses': 'কোর্স', 'live': 'লাইভ', 'tv': 'TV',
    'borrow': 'বরো',
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final r = await AiService.search(q);
    if (mounted) setState(() { _results = r; _loading = false; });
  }

  Future<void> _askAi() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    final ans = await AiService.chat('Search: $q');
    if (mounted) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('✨ AI উত্তর'),
                content: Text(ans),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ঠিক আছে'))
                ],
              ));
    }
  }

  void _openItem(String type, Map<String, dynamic> item) {
    switch (type) {
      case 'people':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                    user: FnfUser(
                        id: item['id'] as String,
                        name: item['title']?.toString() ?? '',
                        avatar: (item['image'] ?? '').toString().isEmpty
                            ? null
                            : item['image'] as String))));
      case 'videos':
      case 'shorts':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                    video: Video(
                        id: item['id'] as String,
                        authorId: item['author_id']?.toString() ?? '',
                        title: item['title']?.toString() ?? '',
                        videoUrl: item['video_url']?.toString() ?? '',
                        thumbnailUrl:
                            (item['image'] ?? '').toString().isEmpty
                                ? null
                                : item['image'] as String,
                        isShort: type == 'shorts',
                        createdAt: DateTime.tryParse(
                                item['created_at']?.toString() ?? '') ??
                            DateTime.now()))));
      case 'channels':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChannelProfileScreen(
                    channel: Channel(
                        id: item['id'] as String,
                        ownerId: '',
                        name: item['title']?.toString() ?? '',
                        handle: (item['subtitle'] ?? '')
                            .toString()
                            .replaceFirst('@', '')))));
      case 'live':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LiveWatchScreen(room: item)));
      case 'tv':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TvPlayerScreen(channel: item)));
      case 'games':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GamesHubScreen()));
      case 'courses':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CoursesScreen()));
      case 'groups':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FnfScreen()));
      case 'borrow':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BorrowHistoryScreen()));
      default:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('এই টাইপের ডিটেইল শীঘ্রই আসছে')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'ENJOY-এ সব খুঁজুন…', border: InputBorder.none),
            onChanged: _onChanged,
          ),
          actions: [
            IconButton(
                tooltip: 'AI সার্চ',
                icon: const Icon(Icons.auto_awesome,
                    color: AppColors.accent),
                onPressed: _askAi),
          ],
        ),
        body: Column(children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final e in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _filter == e.key,
                      onSelected: (_) => setState(() => _filter = e.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? AppStates.loading(message: 'AI Search হচ্ছে…')
                : _results == null
                    ? AppStates.empty(
                        title: 'কী খুঁজতে চান?',
                        subtitle:
                            'মানুষ, ভিডিও, চ্যানেল, গেম, কোর্স, লাইভ, TV — সব একসাথে',
                        icon: Icons.search)
                    : _buildResults(),
          ),
        ]),
      );

  Widget _buildResults() {
    final sections = _filter == 'all'
        ? _filters.keys.where((k) => k != 'all').toList()
        : [_filter];
    var total = 0;
    for (final v in _results!.values) {
      if (v is List) total += v.length;
    }
    return ListView(children: [
      for (final key in sections)
        ..._section(key, (_results![key] as List?) ?? const []),
      if (total == 0)
        const Padding(
            padding: EdgeInsets.all(32),
            child: Text('কিছু পাওয়া যায়নি 😅', textAlign: TextAlign.center)),
    ]);
  }

  List<Widget> _section(String key, List items) {
    if (items.isEmpty) return const [];
    final icon = {
      'people': Icons.person, 'videos': Icons.play_circle,
      'shorts': Icons.short_text, 'posts': Icons.article,
      'channels': Icons.tv, 'groups': Icons.groups,
      'games': Icons.sports_esports, 'courses': Icons.school,
      'live': Icons.podcasts, 'tv': Icons.live_tv, 'borrow': Icons.autorenew,
    }[key]!;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(_filters[key]!,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      for (final item in items.cast<Map<String, dynamic>>())
        ListTile(
          leading: CircleAvatar(
              radius: 18,
              backgroundImage:
                  (item['image'] ?? '').toString().isNotEmpty
                      ? NetworkImage('${item['image']}')
                      : null,
              child: (item['image'] ?? '').toString().isEmpty
                  ? Icon(icon, size: 18)
                  : null),
          title: Text(item['title']?.toString() ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: item['subtitle'] != null
              ? Text('${item['subtitle']}')
              : (key == 'borrow'
                  ? Text('${item['borrows']} বার Borrow হয়েছে')
                  : null),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openItem(key, item),
        ),
    ];
  }
}