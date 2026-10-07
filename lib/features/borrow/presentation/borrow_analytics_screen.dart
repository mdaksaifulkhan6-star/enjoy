import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/borrow_repository.dart';

class BorrowAnalyticsScreen extends StatelessWidget {
  const BorrowAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Analytics')),
      body: FutureBuilder(
        future: Future.wait([
          BorrowRepository.myStats(),
          BorrowRepository.myTopContent(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final stats = snap.data![0] as Map<String, dynamic>?;
          final top = snap.data![1] as List<Map<String, dynamic>>;
          if (stats == null) {
            return AppStates.empty(
                title: 'এখনো কেউ Borrow করেনি', icon: Icons.bar_chart);
          }
          final total = stats['total_requests'] as int? ?? 0;
          final accepts = (stats['active'] as int? ?? 0) +
              (stats['returned'] as int? ?? 0);
          final rate = total > 0 ? (accepts / total * 100).round() : 0;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              _statCard(context, 'মোট রিকোয়েস্ট', '$total', Icons.autorenew),
              _statCard(context, 'Acceptance', '$rate%', Icons.check_circle),
              _statCard(context, 'Coins সংগৃহীত',
                  '${stats['coins_collected'] ?? 0}', Icons.monetization_on),
            ]),
            const SizedBox(height: 20),
            const Text('🏆 সবচেয়ে বেশি Borrow হওয়া কনটেন্ট',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            if (top.isEmpty)
              const Text('এখনো নেই')
            else
              for (final t in top)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t['content_type'] == 'post' ? Icons.article : Icons.video_library,
                    color: AppColors.primary),
                  title: Text('${t['content_type']} — '
                      '${(t['content_id'] as String).substring(0, 8)}…'),
                  trailing: Chip(
                    label: Text('${t['borrows']} বার',
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
          ]);
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon) =>
      Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
        ),
      );
}