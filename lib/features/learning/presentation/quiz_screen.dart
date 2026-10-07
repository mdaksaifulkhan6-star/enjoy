import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/course_repository.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId, lessonTitle;
  const QuizScreen(
      {super.key, required this.lessonId, required this.lessonTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _answers = {};
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await Supabase.instance.client
        .from('quiz_questions')
        .select()
        .eq('lesson_id', widget.lessonId)
        .order('id');
    if (mounted) setState(() => _questions = (rows as List).cast());
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সব প্রশ্নের উত্তর দিন')));
      return;
    }
    setState(() => _submitting = true);
    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['correct_index']) correct++;
    }
    final pct = _questions.isEmpty
        ? 0
        : (correct / _questions.length * 100).round();
    final passed = pct >= 60;
    final db = Supabase.instance.client;
    await db.from('quiz_attempts').insert({
      'lesson_id': widget.lessonId,
      'user_id': db.auth.currentUser!.id,
      'score_pct': pct,
      'passed': passed,
    });
    if (passed) await CourseRepository.completeLesson(widget.lessonId);
    if (mounted) {
      setState(() {
        _submitting = false;
        _result = {'pct': pct, 'passed': passed, 'correct': correct};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final r = _result!;
      return Scaffold(
        appBar: AppBar(title: Text(widget.lessonTitle)),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    r['passed']
                        ? Icons.emoji_events
                        : Icons.refresh,
                    size: 72,
                    color: r['passed']
                        ? AppColors.accent
                        : Colors.grey),
                Text('${r['pct']}%',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w900)),
                Text('${r['correct']}/${_questions.length} সঠিক'),
                Text(r['passed']
                    ? '🎉 পাস! লেসন সম্পন্ন হয়েছে'
                    : '৬০% পেলে পাস — আবার চেষ্টা করুন'),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ফিরে যান')),
              ]),
        ),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.lessonTitle)),
          body: AppStates.loading(message: 'প্রশ্ন লোড হচ্ছে…'));
    }
    return Scaffold(
      appBar: AppBar(title: Text('কুইজ — ${widget.lessonTitle}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (var i = 0; i < _questions.length; i++) ...[
          Text('প্রশ্ন ${i + 1}: ${_questions[i]['question']}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800)),
          RadioGroup<int>(
            groupValue: _answers[i],
            onChanged: (v) {
              if (v != null) setState(() => _answers[i] = v);
            },
            child: Column(children: [
              for (var j = 0;
                  j < (_questions[i]['options'] as List).length;
                  j++)
                RadioListTile<int>(
                  value: j,
                  title: Text(_questions[i]['options'][j]),
                  dense: true,
                ),
            ]),
          ),
          const Divider(height: 28),
        ],
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(
              _submitting ? 'জমা হচ্ছে…' : 'উত্তর জমা দিন'),
        ),
      ]),
    );
  }
}