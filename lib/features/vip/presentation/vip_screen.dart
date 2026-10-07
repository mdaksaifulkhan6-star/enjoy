import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/presentation/payment_screen.dart';

class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  static const _benefits = [
    '♾️ Unlimited Borrow — দিনে যত খুশি',
    '🚫 Free Borrow limit নেই',
    '🚀 Boost-এ অগ্রাধিকার',
    '⭐ VIP badge প্রোফাইলে',
    '📛 Ads ছাড়া Borrow',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VIP 🌟')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.secondary]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(children: [
            Icon(Icons.star, size: 48, color: Colors.white),
            Text('ENJOY VIP',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28, fontWeight: FontWeight.w900)),
            Text('৳199/মাস',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 20),
        for (final b in _benefits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(b, style: const TextStyle(fontSize: 15)),
          ),
        const SizedBox(height: 12),
        StreamBuilder<bool>(
          stream: WalletRepository.vipStream(),
          initialData: false,
          builder: (_, s) => s.data == true
              ? const FilledButton.tonal(
                  onPressed: null,
                  child: Text('✅ আপনি VIP সদস্য'))
              : FilledButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentScreen(
                        package: CoinPackage(0, 199, 'VIP Subscription'),
                        purpose: 'vip_subscription',
                      ))),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('এখনই VIP হন — ৳199'),
                ),
        ),
        const SizedBox(height: 8),
        const Text('সাবস্ক্রিপশন অটো-রিনিউ হয় না; মেয়াদ শেষে আবার কিনুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}