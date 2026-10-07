// ── presentation/rewards_screen.dart ──
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/reward_repository.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  Future<void> _cashout(RewardStatus s) async {
    final accountCtrl = TextEditingController();
    String method = 'bkash';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Reward Cash-Out 🎁'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('৳${s.bdt} (${s.points} points) উত্তোলন করবেন?'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'মেথড'),
              items: const [
                DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
              ],
              onChanged: (v) => setD(() => method = v!),
            ),
            TextField(
                controller: accountCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'অ্যাকাউন্ট নম্বর')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('বাতিল')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('রিকোয়েস্ট')),
          ],
        ),
      ),
    );
    if (ok == true && accountCtrl.text.trim().isNotEmpty) {
      final res = await RewardRepository.requestCashout(
          method, accountCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['ok'] == true
                ? '✅ রিকোয়েস্ট পাঠানো হয়েছে — Verification-এর পর payout'
                : '❌ ${res['error']}')));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('FNF Rewards 🎁')),
        body: FutureBuilder<RewardStatus>(
          future: RewardRepository.status(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            final s = snap.data!;
            final pct = (s.points / s.thresholdPoints).clamp(0.0, 1.0);
            return ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Text('${s.points} Points',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900)),
                  Text('= ৳${s.bdt}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                      s.windowActive
                          ? 'Reward window চলমান (৩ মাস)'
                          : 'Reward window শেষ — নতুন points হবে না',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        Text('${s.fnf}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('FNF (লক্ষ্য ১,০০০)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        Text('${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('Eligibility (লক্ষ্য ১,০০,০০০)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
              const SizedBox(height: 16),
              const Card(
                color: Color(0xFFFFF8E1),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                      '📋 নিয়ম: ১ Genuine FNF = ১০ Points (৩ মাসের window-এ)। '
                      '১০০ Points = ৳0.25। ১,০০,০০০ Points + ১,০০০ FNF হলে Cash-Out '
                      '(Verification সাপেক্ষে)। Fake points বাদ যায়। '
                      'Ad view/click-এর উপর reward নয়।',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: s.eligible ? () => _cashout(s) : null,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                icon: const Icon(Icons.redeem),
                label: Text(s.eligible
                    ? 'Cash-Out করুন — ৳${s.bdt}'
                    : 'Eligible নয় (১,০০,০০০ points + ১,০০০ FNF লাগবে)'),
              ),
              const SizedBox(height: 20),
              const Text('💸 Cash-Out History',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: RewardRepository.cashoutHistory(),
                builder: (context, hSnap) {
                  final h = hSnap.data ?? [];
                  if (h.isEmpty) return const Text('কোনো cash-out নেই');
                  return Column(children: [
                    for (final c in h)
                      ListTile(dense: true, contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.payments_outlined),
                        title: Text('৳${c['amount_bdt']} (${c['points']} pts)'),
                        subtitle:
                            Text('${c['method']} • ${c['status']}'),
                      ),
                  ]);
                },
              ),
            ]);
          },
        ),
      );
}