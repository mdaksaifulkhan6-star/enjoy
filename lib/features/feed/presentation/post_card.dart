import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../borrow/presentation/borrow_button.dart';
import '../data/post_repository.dart';
import 'comments_sheet.dart';

/// Universal Content Action Bar: 👍 Like • 🔄 Borrow • 💬 Comment • ↗ Share • 🔖 Save
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _mediaIndex = 0;

  void _react([String r = 'like']) =>
      PostRepository.toggleReaction(widget.post.id, r);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorAvatar != null
                      ? CachedNetworkImageProvider(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName ?? 'বেনামী',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          timeago.format(post.createdAt,
                              locale: 'en_short'),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (post.authorId == myId)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => PostRepository.deletePost(post.id),
                  ),
              ],
            ),
            if (post.text != null && post.text!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RichHashtagText(post.text!),
            ],
            // Multiple photos carousel
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: post.mediaUrls.length,
                  onPageChanged: (i) => setState(() => _mediaIndex = i),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              if (post.mediaUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      post.mediaUrls.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _mediaIndex
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            // Counts
            if (post.likeCount > 0 || post.commentCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${post.likeCount} লাইক • ${post.commentCount} কমেন্ট',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const Divider(height: 20),
            // Universal Action Bar (Borrow সহ — সব public post eligible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: post.myReaction != null
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: 'লাইক',
                  active: post.myReaction != null,
                  onTap: _react,
                ),
                _ActionButton(
                  icon: Icons.autorenew,
                  label: 'Borrow',
                  onTap: () => showBorrowSheet(context,
                      contentId: post.id,
                      contentType: 'post',
                      ownerName: post.authorName),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'কমেন্ট',
                  onTap: () => showCommentsSheet(context, post.id),
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'শেয়ার',
                  onTap: () async {
                    await PostRepository.incrementShare(post.id);
                    await Share.share(
                        '${post.text ?? ''}\n\nENJOY অ্যাপে দেখুন');
                  },
                ),
                _ActionButton(
                  icon: post.isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: 'সেভ',
                  active: post.isSaved,
                  onTap: () => PostRepository.toggleSave(post.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? AppColors.primary : null),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
}

/// Hashtag-highlighted rich text
class _RichHashtagText extends StatelessWidget {
  final String text;
  const _RichHashtagText(this.text);

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    for (final part in text.split(' ')) {
      if (part.startsWith('#')) {
        spans.add(TextSpan(
          text: '$part ',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600),
        ));
      } else {
        spans.add(TextSpan(text: '$part '));
      }
    }
    return Text.rich(TextSpan(
        children: spans,
        style: Theme.of(context).textTheme.bodyMedium));
  }
}