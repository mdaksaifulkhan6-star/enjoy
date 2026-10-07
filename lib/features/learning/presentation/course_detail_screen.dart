import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/course_repository.dart';
import 'lesson_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool? _enrolled;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final e = await CourseRepository.isEnrolled(widget.course.id);
    if (mounted) setState(() => _enrolled = e);
  }

  Future<void> _review() async {
    int rating = 5;
    final ctrl = TextEditingController();
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, setD) => AlertDialog(
                title: const Text('রিভিউ দিন'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                          icon: Icon(
                              i <= rating ? Icons.star : Icons.star_border,
                              color: AppColors.accent),
                          onPressed: () => setD(() => rating = i)),
                  ]),
                  TextField(
                      controller: ctrl,
                      decoration:
                          const InputDecoration(labelText: 'মতামত'),
                      maxLines: 2),
                ]),
                actions: [
                  FilledButton(
                      onPressed: () async {
                        await CourseRepository.review(
                            widget.course.id, rating, ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('জমা দিন'))
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      appBar: AppBar(
          title:
              Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: FutureBuilder<List<Lesson>>(
        future: CourseRepository.lessons(c.id),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final lessons = snap.data!;
          final done = lessons.where((l) => l.completed).length;
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (c.thumbnailUrl != null)
              ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(c.thumbnailUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover)),
            const SizedBox(height: 12),
            Text(c.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (c.description != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(c.description!)),
            const SizedBox(height: 8),
            Text(
                '👨‍🏫 ${c.creatorName ?? ''} • ${lessons.length} লেসন • $done/${lessons.length} সম্পন্ন'),
            if (lessons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                    value: done / lessons.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8),
              ),
            const SizedBox(height: 8),
            if (_enrolled == false)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () async {
                  await CourseRepository.enroll(c.id);
                  _check();
                },
                icon: const Icon(Icons.how_to_reg),
                label: Text(c.priceBdt == 0
                    ? 'ফ্রি এনরোল করুন'
                    : 'এনরোল করুন — ৳${c.priceBdt}'),
              ),
            if (_enrolled == true)
              FilledButton.tonalIcon(
                  onPressed: _review,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('রিভিউ দিন')),
            const Divider(height: 32),
            const Text('📖 লেসনসমূহ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            for (final l in lessons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    l.completed
                        ? Icons.check_circle
                        : Icons.play_circle_outline,
                    color:
                        l.completed ? AppColors.online : AppColors.primary),
                title: Text('${l.position}. ${l.title}'),
                subtitle: Text(
                    '${l.durationSeconds}s${l.isFreePreview ? ' • ফ্রি প্রিভিউ' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (_enrolled != true && !l.isFreePreview && c.priceBdt > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('আগে এনরোল করুন')));
                    return;
                  }
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LessonPlayerScreen(lesson: l)));
                  setState(() {});
                },
              ),
          ]);
        },
      ),
    );
  }
}