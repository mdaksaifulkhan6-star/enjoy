import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../ai/presentation/ai_assistant_screen.dart';
import '../../ai/presentation/app_doctor_screen.dart';
import '../../borrow/presentation/borrow_analytics_screen.dart';
import '../../borrow/presentation/borrow_history_screen.dart';
import '../../borrow/presentation/borrow_requests_screen.dart';
import '../../boost/presentation/boost_screen.dart';
import '../../creator_studio/presentation/creator_studio_screen.dart';
import '../../fnf/presentation/fnf_screen.dart';
import '../../games/presentation/games_hub_screen.dart';
import '../../learning/presentation/courses_screen.dart';
import '../../live/presentation/live_list_screen.dart';
import '../../tv/presentation/tv_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../world/presentation/enjoy_world_screen.dart';
import '../../world/presentation/world_editor_screen.dart';
import '../data/profile_repository.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Profile> _future = ProfileRepository.getMyProfile();

  Future<void> _refresh() async {
    setState(() => _future = ProfileRepository.getMyProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: FutureBuilder<Profile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return AppStates.loading();
          }
          if (snap.hasError) {
            return AppStates.error(
                message: 'প্রোফাইল লোড করা যায়নি',
                onRetry: _refresh);
          }
          final p = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: p.avatarUrl != null
                        ? NetworkImage(p.avatarUrl!)
                        : null,
                    child: p.avatarUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(p.fullName ?? 'বেনামী',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (p.displayOnline) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.circle,
                                size: 10, color: AppColors.online),
                          ],
                        ]),
                        Text('@${p.username ?? ''}',
                            style: TextStyle(
                                color: Colors.grey.shade600)),
                        if (p.bio != null && p.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(p.bio!),
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const EditProfileScreen())),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('প্রোফাইল এডিট করুন'),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('🎬 Creator',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                ListTile(
                  leading: const Icon(Icons.tv_outlined),
                  title: const Text('Creator Studio'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const CreatorStudioScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch_outlined),
                  title: const Text('Short Boost 🚀'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BoostScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Borrow Analytics'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const BorrowAnalyticsScreen())),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('🔄 Life-Borrow',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: const Text('Borrow রিকোয়েস্ট'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const BorrowRequestsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Borrow History'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const BorrowHistoryScreen())),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('💰 Monetization',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Wallet 💰'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WalletScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('VIP 🌟'),
                  onTap: () => Navigator.pushNamed(context, '/vip'),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('🌐 ENJOY World',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('কোর্স 📚'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CoursesScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.sports_esports),
                  title: const Text('Games 🎮'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GamesHubScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('ENJOY World 🌐'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EnjoyWorldScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('World Editor 🗺️'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const WorldEditorScreen())),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('✨ AI & Live',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('ENJOY AI 🤖'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AiAssistantScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.podcasts_outlined),
                  title: const Text('Live 🔴'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LiveListScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.live_tv),
                  title: const Text('ENJOY TV 📺'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TvScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.healing_outlined),
                  title: const Text('App Doctor 🩺'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AppDoctorScreen())),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('FNF'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FnfScreen())),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}