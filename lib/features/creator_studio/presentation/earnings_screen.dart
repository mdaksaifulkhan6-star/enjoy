import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/monetization_repository.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Future<void> _payout(double payable) async {
    final amountCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    String method = 'bkash';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: const Text('Payout রিকোয়েস্ট'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('উত্তোলনযোগ্য: ৳$payable (ন্যূনতম ৳200)'),
          TextField(controller: amountCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'পরিমাণ (৳)')),
          TextField(controller: accountCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'bKash/Nagad নম্বর')),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'মেথড'),
            items: const [
              DropdownMenuItem(value: 'bkash', child: Text('bKash')),
              DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
            ],
            onChanged: (v) => setD(() => method = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('রিকোয়েস্ট')),
        ],
      )),
    );
    if (ok == true && amountCtrl.text.isNotEmpty) {
      final res = await MonetizationRepository.requestPayout(
          double.tryParse(amountCtrl.text) ?? 0, method, accountCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['ok'] == true
                ? '✅ Payout রিকোয়েস্ট পাঠানো হয়েছে'
                : '❌ ${res['error']}')));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আয় ও Payout')),
      body: FutureBuilder(
        future: Future.wait([
          MonetizationRepository.balance(),
          MonetizationRepository.earnings(),
          MonetizationRepository.payouts(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final bal = snap.data![0] as Map<String, dynamic>;
          final earnings = snap.data![1] as List<Map<String, dynamic>>;
          final payouts = snap.data![2] as List<Map<String, dynamic>>;
          final payable = (bal['payable_bdt'] as num).toDouble();

          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text('৳$payable',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 40, fontWeight: FontWeight.w900)),
                const Text('উত্তোলনযোগ্য', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('মোট আয়: ৳${bal['lifetime_bdt']} • উত্তোলিত: ৳${bal['paid_bdt']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary),
                  onPressed: payable >= 200 ? () => _payout(payable) : null,
                  child: const Text('Payout রিকোয়েস্ট করুন')),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('💰 Earnings Ledger',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (earnings.isEmpty)
              const Padding(padding: EdgeInsets.all(16),
                  child: Text('এখনো কোনো আয় নেই',
                      textAlign: TextAlign.center))
            else
              for (final e in earnings)
                ListTile(dense: true, contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.south_west, size: 18,
                      color: AppColors.online),
                  title: Text(MonetizationRepository.sourceBn(e['source_type'])),
                  subtitle: Text(
                      'গ্রস ৳${e['gross_bdt']} • Creator ${e['creator_share_pct']}%'),
                  trailing: Text('৳${e['creator_amount']}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            const Divider(height: 32),
            const Text('🏦 Payout History',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (payouts.isEmpty)
              const Padding(padding: EdgeInsets.all(16),
                  child: Text('কোনো payout নেই', textAlign: TextAlign.center))
            else
              for (final p in payouts)
                ListTile(dense: true, contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined, size: 18),
                  title: Text('৳${p['amount_bdt']} → ${p['method']}'),
                  subtitle: Text('${p['account_number']} • ${p['status']}'),
                ),
          ]);
        },
      ),
    );
  }
}