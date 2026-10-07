import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/wallet_repository.dart';
import '../data/payment_gateway.dart';

class PaymentScreen extends StatefulWidget {
  final CoinPackage package;
  final String purpose;   // coin_purchase | vip_subscription
  const PaymentScreen({super.key, required this.package,
      this.purpose = 'coin_purchase'});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'bkash';
  bool _processing = false;
  String? _status;

  static const _methods = [
    ('bkash', 'bKash', Icons.account_balance_wallet, Color(0xFFE2136E)),
    ('nagad', 'Nagad', Icons.account_balance, Color(0xFFF6921E)),
    ('card', 'Card', Icons.credit_card, Color(0xFF2D3E8F)),
  ];

  Future<void> _pay() async {
    setState(() { _processing = true; _status = null; });
    try {
      final paymentId = await WalletRepository.initiatePayment(
        gateway: _method,
        purpose: widget.purpose,
        amountBdt: widget.package.priceBdt,
        coins: widget.package.coins,
      );
      final gateway = DemoGateway();
      final result = await gateway.pay(
        paymentId: paymentId,
        method: _method,
        amountBdt: widget.package.priceBdt,
        purpose: widget.purpose,
      );
      await WalletRepository.demoVerify(paymentId, success: result.success);

      if (!mounted) return;
      if (result.success) {
        setState(() => _status = '✅ পেমেন্ট সফল! Coin ক্রেডিট হয়েছে।');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _status = '❌ পেমেন্ট ব্যর্থ: ${result.error}');
      }
    } catch (e) {
      if (mounted) setState(() => _status = '❌ ত্রুটি: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পেমেন্ট')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(widget.purpose == 'vip_subscription'
                  ? 'VIP Subscription' : widget.package.label),
              Text('৳${widget.package.priceBdt}',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        const Text('পেমেন্ট মেথড বাছুন',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _method,
          onChanged: (v) => setState(() => _method = v!),
          child: Column(children: [
            for (final (id, name, icon, color) in _methods)
              Card(
                color: _method == id
                    ? color.withValues(alpha: 0.08) : null,
                child: RadioListTile<String>(
                  value: id,
                  secondary: Icon(icon, color: color),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_status!, textAlign: TextAlign.center),
          ),
        FilledButton.icon(
          onPressed: _processing ? null : _pay,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
          icon: _processing
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_outline),
          label: Text(_processing
              ? 'পেমেন্ট হচ্ছে…'
              : 'নিরাপদে পেমেন্ট করুন — ৳${widget.package.priceBdt}'),
        ),
        const SizedBox(height: 8),
        const Text(
          '🔒 আপনার পেমেন্ট সুরক্ষিত gateway দিয়ে প্রসেস হয়।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ]),
    );
  }
}