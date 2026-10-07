import 'package:flutter/material.dart';
import '../../../core/widgets/state_views.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _usernameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await ProfileRepository.getMyProfile();
    _nameCtrl.text = p.fullName ?? '';
    _usernameCtrl.text = p.username ?? '';
    _bioCtrl.text = p.bio ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ProfileRepository.updateProfile(
        fullName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().toLowerCase(),
        bio: _bioCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সেভ করা যায়নি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল এডিট'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(onPressed: _save, child: const Text('সেভ')),
        ],
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
            return AppStates.loading();
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'পূর্ণ নাম', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'নাম দিন' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username দিন';
                    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(v.trim())) {
                      return '৩-২০ অক্ষর: ছোট হাতের অক্ষর, সংখ্যা, _';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 150,
                  decoration: const InputDecoration(
                      labelText: 'বায়ো',
                      prefixIcon: Icon(Icons.notes_outlined)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}