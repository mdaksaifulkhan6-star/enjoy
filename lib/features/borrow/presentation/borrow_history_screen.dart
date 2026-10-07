import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/borrow_repository.dart';
import '../data/auto_short_generator.dart';
import '../../video/data/video_repository.dart';

/// Borrow History + status + Auto Short Generation
class BorrowHistoryScreen extends StatefulWidget {
  const BorrowHistoryScreen({super.key});

  @override
  State<BorrowHistoryScreen> createState() => _BorrowHistoryScreenState();
}

class _BorrowHistoryScreenState extends State<BorrowHistoryScreen> {
  bool _generating = false;

  Future<void> _autoShort(
      BorrowRequestItem item, String videoUrl) async {
    // ✅ FFmpegKit web সাপোর্ট করে না — শুধু Android/iOS-এ
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              '⚠️ Auto Short শুধু অ্যাপে (Android/iOS) কাজ করে')));
      return;
    }
    setState(() => _generating = true);
    try {
      final file = await AutoShortGenerator.generateFromUrl(
          videoUrl, item.contentId);
      if (file == null) throw Exception('জেনারেশন ব্যর্থ');
      final bytes = await File(file).readAsBytes();
      final url = await VideoRepository.uploadVideoBytes(bytes,
          'borrow_short_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await VideoRepository.publishVideo(
        title: '🔁 Borrowed Short',
        videoUrl: url,
        isShort: true,
        privacy: 'public',
        tags: const ['borrowed', 'enjoy'],
        durationSeconds: 30,
      );
      await BorrowRepository.track(
          item.contentId, item.contentType, 'short_generated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Auto Short পাবলিশ হয়েছে!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow History')),
      body: FutureBuilder<(List<BorrowRequestItem>, Map<String, String>)>(
        future: () async {
          final items = await BorrowRepository.history();
          final urls = await BorrowRepository.videoUrlsFor(items);
          return (items, urls);
        }(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final (items, urls) = snap.data!;
          if (items.isEmpty) {
            return AppStates.empty(
                title: 'কোনো Borrow নেই', icon: Icons.autorenew);
          }
          if (_generating) {
            return AppStates.loading(
                message: 'Auto Short তৈরি হচ্ছে…');
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              final videoUrl = urls[r.contentId];
              return ListTile(
                leading: Icon(
                    r.contentType == 'profile'
                        ? Icons.person
                        : r.contentType == 'post'
                            ? Icons.article
                            : Icons.video_library,
                    color: AppColors.primary),
                title: Text(
                    '${r.contentType.toUpperCase()} — ${r.costType == 'free' ? 'Free' : r.costType == 'vip' ? 'VIP' : '${r.coinsSpent} Coin'}'),
                subtitle: Text(_statusLine(r)),
                isThreeLine: r.isActive,
                trailing: r.isActive
                    ? SizedBox(
                        width: 96,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (videoUrl != null)
                              TextButton(
                                onPressed: _generating
                                    ? null
                                    : () => _autoShort(r, videoUrl),
                                child: const Text('⚡ Auto Short',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            TextButton(
                              onPressed: () async {
                                await BorrowRepository.complete(r.id);
                                setState(() {});
                              },
                              child: const Text('Return',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _statusLine(BorrowRequestItem r) => switch (r.status) {
        'pending' => '⏳ Owner-এর consent অপেক্ষায়',
        'active' =>
          '✅ চলমান • মেয়াদ: ${r.expiresAt?.toLocal().toString().substring(0, 10) ?? '-'}',
        'returned' => '📤 ফেরত দেওয়া হয়েছে',
        'rejected' =>
          '❌ বাতিল${r.coinsSpent > 0 ? ' (Coin refund হয়েছে)' : ''}',
        _ => r.status,
      };
}