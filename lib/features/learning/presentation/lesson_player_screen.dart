import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/course_repository.dart';
import 'quiz_screen.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonPlayerScreen({super.key, required this.lesson});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _completing = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.videoUrl != null) {
      _ctrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.lesson.videoUrl!))
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    final res = await CourseRepository.completeLesson(widget.lesson.id);
    if (mounted) {
      setState(() {
        _completing = false;
        _done = res['completed'] == true || res['ok'] == true;
      });
      if (res['completed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎓 অভিনন্দন! কোর্স সম্পন্ন — সার্টিফিকেট ইস্যু হয়েছে!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (_ctrl != null && _ctrl!.value.isInitialized)
            AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
                child: VideoPlayer(_ctrl!))
          else if (widget.lesson.videoUrl != null)
            const AspectRatio(aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()))
          else
            const AspectRatio(aspectRatio: 16 / 9,
                child: Center(child: Icon(Icons.ondemand_video, size: 64))),
          if (_ctrl != null && _ctrl!.value.isInitialized)
            IconButton(icon: Icon(_ctrl!.value.isPlaying
                ? Icons.pause : Icons.play_arrow), onPressed: () =>
                setState(() => _ctrl!.value.isPlaying
                    ? _ctrl!.pause() : _ctrl!.play())),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_completing || _done) ? null : _complete,
            icon: _completing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_done ? Icons.check_circle : Icons.check),
            label: Text(_done ? 'সম্পন্ন ✅' : 'লেসন সম্পন্ন করুন'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => QuizScreen(lessonId: widget.lesson.id,
                    lessonTitle: widget.lesson.title))),
            icon: const Icon(Icons.quiz),
            label: const Text('কুইজ দিন'),
          ),
        ]),
      );
}