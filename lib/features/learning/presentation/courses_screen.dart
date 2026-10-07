import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/course_repository.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
              title: const Text('📚 কোর্স'),
              bottom: const TabBar(tabs: [
                Tab(text: 'সব কোর্স'),
                Tab(text: 'সার্টিফিকেট'),
                Tab(text: 'লার্নিং হিস্ট্রি'),
              ])),
          body: TabBarView(children: [
            // ── সব কোর্স ──
            FutureBuilder<List<Course>>(
              future: CourseRepository.list(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(
                      title: 'কোনো কোর্স নেই',
                      icon: Icons.school_outlined);
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final c = snap.data![i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CourseDetailScreen(course: c))),
                        leading: c.thumbnailUrl != null
                            ? Image.network(c.thumbnailUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover)
                            : const CircleAvatar(
                                child: Icon(Icons.school)),
                        title: Text(c.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${c.creatorName ?? ''}${c.rating != null ? ' • ⭐${c.rating!.toStringAsFixed(1)} (${c.reviewCount})' : ''}'),
                        trailing: Text(
                            c.priceBdt == 0 ? 'ফ্রি 🎉' : '৳${c.priceBdt}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: c.priceBdt == 0
                                    ? AppColors.online
                                    : AppColors.primary)),
                      ),
                    );
                  },
                );
              },
            ),
            // ── সার্টিফিকেট ──
            FutureBuilder<List<Certificate>>(
              future: CourseRepository.myCertificates(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(
                      title: 'এখনো কোনো সার্টিফিকেট নেই',
                      subtitle:
                          'কোর্স সম্পন্ন করলে সার্টিফিকেট পাবেন 🎓',
                      icon: Icons.workspace_premium_outlined);
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final c = snap.data![i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.workspace_premium,
                            color: AppColors.accent, size: 36),
                        title: Text(c.courseTitle ?? 'কোর্স',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Serial: ${c.serial}\n${c.issuedAt.toLocal().toString().substring(0, 10)}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
            // ── লার্নিং হিস্ট্রি ──
            FutureBuilder<List<Map<String, dynamic>>>(
              future: CourseRepository.myLearningHistory(),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                if (snap.data!.isEmpty) {
                  return AppStates.empty(
                      title: 'কোনো লার্নিং হিস্ট্রি নেই',
                      subtitle:
                          'কোর্স এনরোল করলে এখানে দেখা যাবে',
                      icon: Icons.history_edu_outlined);
                }
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (_, i) {
                    final h = snap.data![i];
                    final progress =
                        (h['progress'] as num?)?.toDouble() ?? 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading:
                            const Icon(Icons.menu_book_outlined),
                        title: Text('${h['title']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Enrolled: ${(h['enrolled_at']?.toString() ?? '').substring(0, 10)}'
                                '${h['completed_at'] != null ? ' • ✅ সম্পন্ন' : ''}'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 6,
                                borderRadius:
                                    BorderRadius.circular(3)),
                          ],
                        ),
                        trailing:
                            Text('${progress.toStringAsFixed(0)}%'),
                      ),
                    );
                  },
                );
              },
            ),
          ]),
        ),
      );
}