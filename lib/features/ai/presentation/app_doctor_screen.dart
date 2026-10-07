import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/ai_service.dart';

class AppDoctorScreen extends StatelessWidget {
  const AppDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('App Doctor 🩺')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: AiService.doctorReport(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            final d = snap.data!;
            final errorCount = (d['errorCount'] as num?)?.toInt() ?? 0;
            final avgLoad = (d['avgLoadMs'] as num?)?.toInt() ?? 0;
            final platform = d['platform'] as String? ?? '-';
            final status = d['status'] as String? ?? '';
            final rows = <(IconData, String, String, bool)>[
              (Icons.devices, 'প্ল্যাটফর্ম', platform, true),
              (Icons.bug_report, 'রিপোর্টেড এরর', '$errorCount টি', errorCount == 0),
              (Icons.speed, 'গড় স্ক্রিন লোড', '$avgLoad ms', avgLoad < 500),
            ];
            return ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    leading: Icon(r.$1, color: r.$4 ? AppColors.online : Colors.red),
                    title: Text(r.$2),
                    trailing: Text(r.$3,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                color: AppColors.accent.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.healing, color: AppColors.accent),
                  title: const Text('স্বাস্থ্য রিপোর্ট'),
                  subtitle: Text(
                      '$status — Error/Performance Intelligence সক্রিয়'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await AiService.reportError('manual', 'Manual test report', null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('✅ টেস্ট রিপোর্ট পাঠানো হয়েছে')));
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('টেস্ট রিপোর্ট পাঠান'),
              ),
            ]);
          },
        ),
      );
}