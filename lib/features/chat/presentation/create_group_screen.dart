import 'package:flutter/material.dart';
import '../../../core/widgets/state_views.dart';
import '../../fnf/data/fnf_repository.dart';
import '../../groups/data/group_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      await GroupRepository.createGroup(
          name: _nameCtrl.text.trim(), memberIds: _selected.toList());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('নতুন গ্রুপ'),
          actions: [
            if (_creating)
              const Padding(padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else
              TextButton(onPressed: _create,
                  child: const Text('তৈরি করুন')),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'গ্রুপের নাম',
                    prefixIcon: Icon(Icons.groups_outlined)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('সদস্য বাছুন (FNF থেকে):',
                      style: TextStyle(fontWeight: FontWeight.w700))),
            ),
            Expanded(
              child: FutureBuilder<List<FnfUser>>(
                future: FnfRepository.myFriends(),
                builder: (context, snap) {
                  if (!snap.hasData) return AppStates.loading();
                  return ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final u = snap.data![i];
                      return CheckboxListTile(
                        value: _selected.contains(u.id),
                        onChanged: (v) => setState(() => v!
                            ? _selected.add(u.id)
                            : _selected.remove(u.id)),
                        secondary: CircleAvatar(
                          backgroundImage:
                              u.avatar != null ? NetworkImage(u.avatar!) : null,
                          child: u.avatar == null
                              ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u.name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}