import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/monetization_repository.dart';

class MonetizationScreen extends StatelessWidget {
  const MonetizationScreen({super.key});

  static const _metricLabels = {
    'fnf': 'FNF', 'watch_hours': 'Watch Time (ঘণ্টা)', 'views': 'Views',
    'likes': 'Likes', 'comments': 'Comments', 'shares': 'Shares',
    'original_content': 'Original Content',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('মনিটাইজেশন 💰')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: MonetizationRepository.progress(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final d = snap.data!;
          final metrics = Map<String, dynamic>.from(d['metrics']);
          final thresholds = Map<String, dynamic>.from(d['thresholds']);
          final stage = d['stage'] as String;
          final shares = Map<String, dynamic>.from(d['shares']);

          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: stage == 'none' ? null : AppColors.brandGradient,
                color: stage == 'none' ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(stage == 'none' ? 'এখনো eligible নয়' :
                    stage == 'limited' ? '🎉 LIMITED OFFER অ্যাক্টিভ (৩ মাস)!'
                    : stage == 'stage1' ? '🎉 STAGE 1 অ্যাক্টিভ!' : '🏆 STAGE 2!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18,
                    color: stage == 'none' ? Colors.black54 : Colors.white)),
                if (stage != 'none')
                  const Text('Revenue Share এখন থেকে কার্যকর',
                      style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 16),
            // ── প্রগ্রেস বার (Limited Offer thresholds-এর সাথে) ──
            const Text('অগ্রগতি (Limited Offer লক্ষ্য)',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final e in _metricLabels.entries) ...[
              Builder(builder: (_) {
                final cur = (metrics[e.key] as num).toDouble();
                final req = (Map<String, dynamic>.from(
                    thresholds['limited'])[e.key] as num).toDouble();
                final pct = (cur / req).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(e.value, style: const TextStyle(fontSize: 13)),
                      Text('${_fmt(cur)} / ${_fmt(req)}',
                          style: TextStyle(fontSize: 12,
                              color: cur >= req ? AppColors.online : Colors.grey)),
                    ]),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(
                          cur >= req ? AppColors.online : AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8),
                  ]),
                );
              }),
            ],
            const Divider(height: 32),
            const Text('💼 Revenue Share',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final e in shares.entries)
              ListTile(dense: true, contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.pie_chart_outline, size: 20,
                    color: AppColors.primary),
                title: Text(MonetizationRepository.sourceBn(e.key)),
                trailing: Text('Creator ${e.value}% / ENJOY ${100 - (e.value as num).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 8),
            const Card(
              color: Color(0xFFFFF8E1),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('🔄 Life-Borrow Revenue: Creator 10% (শুধু Borrow আয় থেকে)। '
                    'AdMob/VIP/Coin/Boost revenue-এর বাইরে।',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ]);
        },
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k'
      : v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
} 