import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/channel_repository.dart';
import 'channel_profile_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  Future<void> _create() async {
    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন চ্যানেল'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'চ্যানেলের নাম')),
          TextField(
              controller: handleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Handle (@username)')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('তৈরি করুন')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.isNotEmpty) {
      try {
        await ChannelRepository.createChannel(
            nameCtrl.text.trim(), handleCtrl.text.trim());
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(e.toString().replaceAll('Exception: ', ''))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('আমার চ্যানেল')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('নতুন চ্যানেল')),
        body: FutureBuilder<List<Channel>>(
          future: ChannelRepository.myChannels(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return AppStates.empty(
                  title: 'কোনো চ্যানেল নেই',
                  subtitle: 'একটি অ্যাকাউন্টে একাধিক চ্যানেল বানান!',
                  icon: Icons.video_library_outlined);
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
                                ChannelProfileScreen(channel: c))),
                    leading: CircleAvatar(
                        backgroundImage: c.avatarUrl != null
                            ? NetworkImage(c.avatarUrl!)
                            : null,
                        child: c.avatarUrl == null
                            ? const Icon(Icons.tv)
                            : null),
                    title: Row(children: [
                      Flexible(
                          child: Text(c.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      if (c.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 16, color: AppColors.primary),
                      ],
                    ]),
                    subtitle: Text('@${c.handle}'),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await ChannelRepository.deleteChannel(c.id);
                          setState(() {});
                        }),
                  ),
                );
              },
            );
          },
        ),
      );
}