import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiMessage {
  final String text;
  final bool mine;
  _AiMessage(this.text, this.mine);
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final List<_AiMessage> _msgs = [
    _AiMessage(
        'সালাম! আমি ENJOY AI 🤖\nজিজ্ঞেস করুন: borrow, vip, coin, course, game, live, tv',
        false),
  ];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _greet();
  }

  Future<void> _greet() async {
    final mem = await AiService.memory('profile');
    final q = mem?['last_question']?.toString();
    if (q != null && q.isNotEmpty && mounted) {
      setState(() =>
          _msgs.add(_AiMessage('আবার দেখা হয়ে গেল! আগে জিজ্ঞেস করেছিলেন: "$q"', false)));
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_AiMessage(text, true));
      _typing = true;
    });
    await AiService.remember('profile', {'last_question': text});
    final reply = await AiService.chat(text);
    if (mounted) {
      setState(() {
        _typing = false;
        _msgs.add(_AiMessage(reply, false));
      });
    }
  }

  Future<void> _translate() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI অনুবাদ 🌉'),
        content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'টেক্সট লিখুন (বাংলা→English)')),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('অনুবাদ করুন')),
        ],
      ),
    );
    if (ok == true && ctrl.text.isNotEmpty) {
      final en = await AiService.translate(ctrl.text, 'en');
      if (mounted) {
        setState(() => _msgs.add(_AiMessage('🌉 ${ctrl.text}\n→ $en', true)));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('ENJOY AI 🤖'),
          actions: [
            IconButton(
                tooltip: 'অনুবাদ',
                icon: const Icon(Icons.translate),
                onPressed: _translate),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                return Align(
                  alignment:
                      m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      gradient: m.mine ? AppColors.brandGradient : null,
                      color: m.mine ? null : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.text,
                        style: TextStyle(
                            color: m.mine ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          if (_typing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('AI লিখছে…', style: TextStyle(fontSize: 12)),
              ]),
            ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final q in [
                  'Borrow কী?',
                  'VIP দাম',
                  'Coin কিভাবে কিনব?',
                  'Games আছে?'
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(label: Text(q), onPressed: () => _send(q)),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Row(children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration:
                      const InputDecoration(hintText: 'AI-কে জিজ্ঞেস করুন…'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _send()),
            ]),
          ),
        ]),
      );
}