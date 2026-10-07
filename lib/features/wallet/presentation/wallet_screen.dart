import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/wallet_repository.dart';
import 'payment_screen.dart';
import '../../vip/presentation/vip_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet 💰')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Coin ব্যালেন্স',
                style: TextStyle(color: Colors.white70)),
            StreamBuilder<int>(
              stream: WalletRepository.balanceStream(),
              initialData: 0,
              builder: (_, s) => Text('${s.data ?? 0}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            StreamBuilder<bool>(
              stream: WalletRepository.vipStream(),
              initialData: false,
              builder: (_, s) => s.data == true
                  ? const Chip(
                      label: Text('🌟 VIP — Unlimited Borrow'),
                      backgroundColor: Colors.white)
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // VIP upsell
        Card(
          child: ListTile(
            leading: const Icon(Icons.star, color: AppColors.accent),
            title: const Text('VIP — Unlimited Borrow'),
            subtitle: const Text('মাত্র ৳199/মাস • Free Borrow limit নেই'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VipScreen())),
          ),
        ),
        const SizedBox(height: 8),
        // 🎬 Rewarded Ad → ১০ Coin
        OutlinedButton.icon(
          icon: const Icon(Icons.ondemand_video),
          label: const Text('🎬 Ad দেখে ১০ Coin নিন'),
          onPressed: () async {
            if (kIsWeb) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('⚠️ Rewarded Ad শুধু Android/iOS অ্যাপে কাজ করে')));
              return;
            }
            final ok = await AdmobService.showRewardedForCoins();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? '✅ ১০ Coin যোগ হয়েছে!'
                      : '⚠️ আজকের limit শেষ বা ad unavailable')));
            }
          },
        ),
        const SizedBox(height: 12),
        const Text('🪙 Coin Store',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        for (final p in WalletRepository.packages)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.monetization_on,
                  color: AppColors.secondary),
              title: Text(p.label),
              subtitle: p.bonus != null
                  ? Text(p.bonus!)
                  : const Text('10 Coin = ৳10'),
              trailing: FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                            package: p, purpose: 'coin_purchase'))),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: Text('৳${p.priceBdt}'),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text('📜 Transaction History',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        FutureBuilder<List<LedgerEntry>>(
          future: WalletRepository.ledger(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('কোনো লেনদেন নেই', textAlign: TextAlign.center));
            }
            return Column(children: [
              for (final e in snap.data!)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      e.isCredit ? Icons.add_circle : Icons.remove_circle,
                      color: e.isCredit ? AppColors.online : Colors.red),
                  title: Text(WalletRepository.reasonBn(e.reason)),
                  subtitle: Text(DateFormat('d MMM, h:mm a')
                      .format(e.createdAt.toLocal())),
                  trailing: Text(
                    '${e.isCredit ? '+' : '-'}${e.amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: e.isCredit ? AppColors.online : Colors.red,
                    ),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}