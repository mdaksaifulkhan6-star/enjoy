import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/deep_link_service.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../../auth/presentation/sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showOnline = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await ProfileRepository.getMyProfile();
      setState(() => _showOnline = p.showOnlineStatus);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await ProfileRepository.setOnlineStatus(false);
    await DeepLinkService.dispose();
    await AuthRepository.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(user?.email ?? ''),
            subtitle: const Text('Google অ্যাকাউন্ট'),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.circle_outlined),
            title: const Text('অনলাইন স্ট্যাটাস দেখান'),
            subtitle: const Text('অন্যরা আপনাকে অনলাইন দেখতে পাবে'),
            value: _showOnline,
            onChanged: (v) async {
              setState(() => _showOnline = v);
              await ProfileRepository.updateProfile(showOnlineStatus: v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('ডার্ক মোড'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('গোপনীয়তা ও নিরাপত্তা'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('রিপোর্ট সমস্যা'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('গোপনীয়তা নীতি'),
            subtitle: Text(AppConfig.privacyUrl,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('লগ আউট', style: TextStyle(color: Colors.red)),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('লগ আউট করবেন?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বাতিল')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _logout();
                      },
                      child: const Text('লগ আউট')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}