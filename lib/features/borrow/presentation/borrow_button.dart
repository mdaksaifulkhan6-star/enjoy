import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../ads/data/ads_repository.dart';
import '../../ads/presentation/borrow_ad_overlay.dart';
import '../data/borrow_repository.dart';

/// Universal 🔄 Borrow Button — eligible content-এ দেখান
class BorrowButton extends StatelessWidget {
  final String contentId;      // video/post id, profile borrow-এ owner id
  final String contentType;    // 'video' | 'post' | 'profile'
  final String? ownerName;
  const BorrowButton({super.key, required this.contentId,
      this.contentType = 'video', this.ownerName});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showBorrowSheet(context,
            contentId: contentId, contentType: contentType, ownerName: ownerName),
        borderRadius: BorderRadius.circular(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.autorenew, size: 24, color: Colors.white),
            SizedBox(height: 3),
            Text('Borrow', style: TextStyle(color: Colors.white, fontSize: 11)),
          ]),
        ),
      );
}

void showBorrowSheet(BuildContext context,
    {required String contentId, String contentType = 'video', String? ownerName}) {
  showModalBottomSheet(
    context: context, showDragHandle: true,
    builder: (_) => _BorrowSheet(
        contentId: contentId, contentType: contentType, ownerName: ownerName),
  );
}

class _BorrowSheet extends StatefulWidget {
  final String contentId, contentType;
  final String? ownerName;
  const _BorrowSheet({required this.contentId,
      required this.contentType, this.ownerName});

  @override
  State<_BorrowSheet> createState() => _BorrowSheetState();
}

class _BorrowSheetState extends State<_BorrowSheet> {
  BorrowStatusInfo? _status;
  bool _submitting = false;
  String? _done;

  @override
  void initState() {
    super.initState();
    _load();
    BorrowRepository.track(widget.contentId, widget.contentType, 'view');
  }

  Future<void> _load() async {
    final s = await BorrowRepository.status();
    if (mounted) setState(() => _status = s);
  }

  Future<void> _confirm() async {
    setState(() { _submitting = true; _done = null; });
    try {
      final res = await BorrowRepository.requestBorrow(
          contentId: widget.contentId, contentType: widget.contentType);

      if (!mounted) return;
      if (!res.ok) {
        // Coin না থাকলে wallet-এ পাঠানোর অপশন
        if (res.error == 'insufficient_coins') {
          _showInsufficient();
        } else {
          setState(() => _done = '❌ ${_errorBn(res.error ?? 'unknown')}');
        }
        return;
      }

      // Free borrow-এ 5-second fullscreen ad (applicable ad)
      if (res.costType == 'free' && mounted) {
        final ad = await AdsRepository.getAd();
        if (ad != null && mounted) {
          await BorrowAdOverlay.show(context, ad);
        }
      }

      if (mounted) {
        setState(() => _done = res.costType == 'free'
            ? '✅ Free Borrow পাঠানো হয়েছে! (আজকের ১টি ব্যবহৃত)'
            : res.costType == 'vip'
                ? '✅ VIP Borrow পাঠানো হয়েছে!'
                : '✅ 10 Coin খরচে Borrow পাঠানো হয়েছে!');
        _load();
      }
    } catch (e) {
      if (mounted) setState(() => _done = '❌ ত্রুটি: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showInsufficient() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coin নেই 😅'),
        content: const Text('অতিরিক্ত Borrow-এর জন্য 10 Coin লাগবে। Coin কিনুন বা VIP নিন!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/wallet');
            },
            child: const Text('Coin কিনুন'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/vip');
            },
            child: const Text('VIP নিন 🌟'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔄 Life-Borrow',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (widget.ownerName != null) ...[
            const SizedBox(height: 4),
            Text('${widget.ownerName}-এর কনটেন্ট borrow করুন',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          if (s == null)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator()))
          else ...[
            _costRow(Icons.check_circle, AppColors.online,
                '১টি Free Borrow/দিন',
                s.freeAvailable ? 'উপলব্ধ ✅' : 'শেষ — আজকের ফ্রি Borrow ব্যবহৃত',
                s.freeAvailable),
            const SizedBox(height: 8),
            _costRow(Icons.star, AppColors.accent, 'VIP Unlimited Borrow',
                s.vip ? 'সক্রিয় 🌟' : '৳199/মাস', s.vip),
            const SizedBox(height: 8),
            _costRow(Icons.monetization_on, AppColors.secondary,
                'অতিরিক্ত Borrow = 10 Coin',
                'ব্যালেন্স: ${s.balance} coin', s.balance >= 10),
          ],
          const SizedBox(height: 8),
          const Text('📋 Owner-এর consent-এর পর Borrow active হবে (৭ দিন মেয়াদ)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          if (_done != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_done!, textAlign: TextAlign.center),
            ),
          FilledButton.icon(
            onPressed: (_submitting || s == null) ? null : _confirm,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            icon: _submitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.autorenew),
            label: Text(_submitting ? 'প্রসেস হচ্ছে…' : 'Borrow রিকোয়েস্ট পাঠান'),
          ),
        ],
      ),
    );
  }

  Widget _costRow(IconData icon, Color color, String title, String sub, bool good) =>
      Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(sub, style: TextStyle(
                fontSize: 12, color: good ? AppColors.online : Colors.grey)),
          ]),
        ),
        Icon(Icons.circle, size: 8, color: good ? AppColors.online : Colors.grey),
      ]);

  String _errorBn(String e) => {
        'own_content': 'নিজের কনটেন্ট borrow করা যায় না',
        'not_borrow_eligible': 'এই কনটেন্ট Borrow-এর জন্য eligible নয়',
        'blocked': 'ব্যবহারকারী unavailable',
        'already_requested': 'আগেই Borrow রিকোয়েস্ট আছে',
        'rate_limited': 'অনেক বেশি রিকোয়েস্ট — একটু পরে চেষ্টা করুন',
        'login_required': 'লগইন করুন',
      }[e] ?? e;
}