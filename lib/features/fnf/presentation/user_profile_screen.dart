import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../borrow/presentation/borrow_button.dart';
import '../../safety/data/safety_repository.dart';
import '../data/fnf_repository.dart';

/// Other user's profile — relationship + safety + Profile Borrow
class UserProfileScreen extends StatefulWidget {
  final FnfUser user;
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _relation = 'none';

  @override
  void initState() {
    super.initState();
    _loadRelation();
  }

  Future<void> _loadRelation() async {
    final r = await FnfRepository.relationshipWith(widget.user.id);
    if (mounted) setState(() => _relation = r);
  }

  Future<void> _onMenuSelected(String v) async {
    switch (v) {
      case 'block':
        await SafetyRepository.blockUser(widget.user.id);
        if (mounted) Navigator.pop(context);
        break;
      case 'mute':
        await SafetyRepository.muteUser(widget.user.id);
        break;
      case 'report':
        await SafetyRepository.report(
          targetType: 'user',
          targetId: widget.user.id,
          reason: 'inappropriate',
        );
        break;
    }
  }

  Widget _buildRelationButton() {
    switch (_relation) {
      case 'none':
        return FilledButton.icon(
          onPressed: () async {
            await FnfRepository.sendRequest(widget.user.id);
            _loadRelation();
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('FNF রিকোয়েস্ট পাঠান'),
        );
      case 'pending_sent':
        return const FilledButton.tonal(
          onPressed: null,
          child: Text('রিকোয়েস্ট পাঠানো হয়েছে ⏳'),
        );
      case 'pending_received':
        return FilledButton(
          onPressed: () {},
          child: const Text('রিকোয়েস্ট অ্যাক্সেপ্ট করুন'),
        );
      default:
        return FilledButton.tonalIcon(
          onPressed: () async {
            await FnfRepository.removeFriend(widget.user.id);
            _loadRelation();
          },
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('FNF রিমুভ করুন'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(u.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'mute', child: Text('মিউট করুন')),
              PopupMenuItem(value: 'block', child: Text('ব্লক করুন')),
              PopupMenuItem(value: 'report', child: Text('রিপোর্ট করুন')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundImage:
                      u.avatar != null ? NetworkImage(u.avatar!) : null,
                  child: u.avatar == null
                      ? const Icon(Icons.person, size: 52)
                      : null,
                ),
                if (u.displayOnline)
                  const Positioned(
                    bottom: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.circle,
                          size: 14, color: AppColors.online),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              u.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),
          _buildRelationButton(),
          const SizedBox(height: 10),
          // Profile Borrow (contentType 'profile' — engine-এ owner consent)
          OutlinedButton.icon(
            onPressed: () => showBorrowSheet(context,
                contentId: u.id, contentType: 'profile', ownerName: u.name),
            icon: const Icon(Icons.autorenew, color: AppColors.primary),
            label: const Text('🔄 Profile Borrow'),
          ),
        ],
      ),
    );
  }
}