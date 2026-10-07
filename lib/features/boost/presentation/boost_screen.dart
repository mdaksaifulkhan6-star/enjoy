// ── presentation/boost_screen.dart ──
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../video/data/video_repository.dart';
import '../data/boost_repository.dart';

/// Borrow Short Boost — নিজের short-কে feed-এ উপরে তোলে
class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  Video? _selected;
  int _days = 3;
  bool _boosting = false;

  int get _cost => _days * BoostRepository.coinsPerDay;

  Future<void> _boost() async {
    if (_selected == null) return;
    setState(() => _boosting = true);
    try {
      final res = await BoostRepository.boost(_selected!.id, _days);
      if (!mounted) return;
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🚀 Boost সক্রিয়! $_cost Coin খরচ')));
        setState(() => _selected = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['error'] == 'insufficient_coins'
                ? 'Coin নেই — আগে Wallet থেকে কিনুন'
                : '❌ ${res['error']}')));
      }
    } finally {
      if (mounted) setState(() => _boosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Short Boost 🚀')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('ভিডিও বাছুন (নিজের shorts)',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<List<Video>>(
          future: () async {
            // আমার shorts-গুলো (stream থেকে প্রথম snapshot)
            final completer = await _dbMyShorts();
            return completer;
          }(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            final shorts = snap.data!.where((v) => v.isShort).toList();
            if (shorts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('আপনার কোনো short নেই'));
            }
            return RadioGroup<Video>(
              groupValue: _selected,
              onChanged: (x) => setState(() => _selected = x),
              child: Column(children: [
                for (final v in shorts)
                  RadioListTile<Video>(
                    value: v,
                    title: Text(v.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${v.views} views'),
                  ),
              ]),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text('সময়কাল',
            style: TextStyle(fontWeight: FontWeight.w800)),
        Wrap(spacing: 8, children: [
          for (final d in [1, 3, 7])
            ChoiceChip(
              label: Text('$d দিন'),
              selected: _days == d,
              onSelected: (_) => setState(() => _days = d),
            ),
        ]),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.monetization_on,
                color: AppColors.secondary),
            title: const Text('মোট খরচ'),
            trailing: Text('$_cost Coin',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: (_selected == null || _boosting) ? null : _boost,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
          icon: const Icon(Icons.rocket_launch),
          label: Text(_boosting ? 'হচ্ছে…' : 'Boost করুন 🚀'),
        ),
        const SizedBox(height: 20),
        const Text('📊 আমার Boosts',
            style: TextStyle(fontWeight: FontWeight.w800)),
        FutureBuilder<List<Boost>>(
          future: BoostRepository.myBoosts(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            if (snap.data!.isEmpty) return const Text('কোনো boost নেই');
            return Column(children: [
              for (final b in snap.data!)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.rocket_launch,
                      color: b.isActive ? AppColors.online : Colors.grey),
                  title: Text('${b.coinsSpent} Coin • ${b.durationDays} দিন'),
                  subtitle: Text(b.isActive
                      ? 'চলমান — শেষ: ${b.endsAt.toLocal().toString().substring(0, 10)}'
                      : 'শেষ'),
                  trailing: Text('${b.viewsGained} views',
                      style: const TextStyle(fontSize: 12)),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  Future<List<Video>> _dbMyShorts() async {
    // VideoRepository.myVideos() stream — প্রথম value নিচ্ছি
    return VideoRepository.myVideos().first;
  }
}