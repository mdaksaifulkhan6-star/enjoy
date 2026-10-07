import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/game_repository.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _playersMax = 2;
  bool _ranked = true;
  bool _creating = false;

  static const _sizes = [1, 2, 4, 8, 10, 20, 50, 100];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      final g = await GameRepository.createGame(
        _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        playersMax: _playersMax,
        ranked: _ranked,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '✅ "${g.title}" তৈরি — এডিটর/Scene Phase 7.1-এ')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', ''))));
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🎮 Game Creator')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
              controller: _titleCtrl,
              maxLength: 60,
              decoration:
                  const InputDecoration(labelText: 'গেমের নাম *')),
          TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'বিবরণ')),
          const SizedBox(height: 8),
          const Text('সর্বোচ্চ প্লেয়ার',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final n in _sizes)
              ChoiceChip(
                label: Text(n == 1 ? 'Single' : '$n Players'),
                selected: _playersMax == n,
                onSelected: (_) => setState(() => _playersMax = n),
              ),
          ]),
          SwitchListTile(
            title: const Text('Ranked (ELO)'),
            value: _ranked,
            onChanged: (v) => setState(() => _ranked = v),
          ),
          const Card(
            color: Color(0xFFFFF8E1),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  '🛠️ Scene Editor / World Editor / AI-Assisted / Version Control — '
                  'games-এর engine ফিল্ডে flutter/html5 নির্বাচন করে world_scenes-এ লিংক করুন। '
                  'Testing = 1v1 ম্যাচ দিয়ে।',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _creating ? null : _create,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            icon: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sports_esports),
            label: Text(_creating ? 'তৈরি হচ্ছে…' : 'গেম তৈরি করুন'),
          ),
        ]),
      );
}