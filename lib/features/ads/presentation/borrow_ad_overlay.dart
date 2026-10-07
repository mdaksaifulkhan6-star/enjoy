import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/ads_repository.dart';

/// Applicable 5-Second Fullscreen Ad — Borrow flow-তে দেখায়
class BorrowAdOverlay {
  BorrowAdOverlay._();

  static Future<void> show(BuildContext context, AdCampaign ad) {
    return showDialog(
      context: context,
      barrierDismissible: false,          // ৫ সেকেন্ড skip করা যাবে না
      barrierColor: Colors.black,
      builder: (_) => _AdView(ad: ad),
    );
  }
}

class _AdView extends StatefulWidget {
  final AdCampaign ad;
  const _AdView({required this.ad});

  @override
  State<_AdView> createState() => _AdViewState();
}

class _AdViewState extends State<_AdView> {
  VideoPlayerController? _ctrl;
  int _remaining = 5;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Impression track (server-এ counter বাড়ে)
    await AdsRepository.track(widget.ad.id, 'impression');

    _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.ad.creativeUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _ctrl!.play();
        }
      });

    // ৫ সেকেন্ড কাউন্টডাউন
    for (var i = 5; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _remaining = i - 1);
    }
    // Complete = revenue event (revenue_bdt server-এ auto-calc)
    await AdsRepository.track(widget.ad.id, 'complete');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        Center(
          child: _ctrl != null && _ctrl!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio,
                  child: VideoPlayer(_ctrl!))
              : const CircularProgressIndicator(color: Colors.white),
        ),
        Positioned(
          top: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$_remaining',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
        Positioned(
          top: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.black54,
            child: const Text('Ad',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Text(widget.ad.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}