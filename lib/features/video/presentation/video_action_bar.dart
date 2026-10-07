import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../borrow/presentation/borrow_button.dart';
import '../data/video_repository.dart';
import 'download_sheet.dart';
import 'video_comments_sheet.dart';

/// Universal Content Action Bar:
/// 👍 Like • 🔄 Borrow (eligible only) • 💬 Comment • ↗ Share • 🔖 Save • ⬇ Download
class VideoActionBar extends StatelessWidget {
  final Video video;
  const VideoActionBar({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final canDownload = video.allowDownload &&
        !video.copyrightProtected &&
        video.privacy == 'public';

    Widget btn(IconData icon, String label, VoidCallback onTap,
            {bool active = false}) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 24,
                  color: active ? AppColors.primary : Colors.white),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11)),
            ]),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn(
            video.myReaction != null
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            '${video.likeCount}',
            () => VideoRepository.toggleReaction(video.id),
            active: video.myReaction != null,
          ),
          if (video.borrowEligible)
            BorrowButton(
                contentId: video.id,
                contentType: 'video',
                ownerName: video.authorName),
          // 💬 Comment — video_comments টেবিল (FK crash fix)
          btn(
            Icons.mode_comment_outlined,
            '${video.commentCount}',
            () => showVideoCommentsSheet(context, video.id),
          ),
          btn(Icons.share_outlined, 'শেয়ার', () {}),
          btn(
            video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            'সেভ',
            () => VideoRepository.toggleSave(video.id),
            active: video.isSaved,
          ),
          if (canDownload)
            btn(Icons.download_outlined, 'ডাউনলোড',
                () => showDownloadSheet(context, video))
          else if (video.copyrightProtected)
            btn(Icons.lock_outline, 'প্রোটেক্টেড', () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(
                      content: Text(
                          '© কপিরাইট প্রোটেক্টেড — ডাউনলোড নিষিদ্ধ')));
            }),
        ],
      ),
    );
  }
}