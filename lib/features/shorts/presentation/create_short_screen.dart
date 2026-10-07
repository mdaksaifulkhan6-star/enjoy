import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../video/data/video_repository.dart';

/// Shorts editor:
/// ✅ Trim (FFmpeg) • ✅ Speed (FFmpeg) • 🎵 Music • ✅ Filters (FFmpeg)
/// ভয়েসওভার/ট্রানজিশন UI — FFmpeg লেয়ারে extend করুন
class CreateShortScreen extends StatefulWidget {
  const CreateShortScreen({super.key});

  @override
  State<CreateShortScreen> createState() => _CreateShortScreenState();
}

class _CreateShortScreenState extends State<CreateShortScreen> {
  String? _inputPath;
  VideoPlayerController? _ctrl;
  double _trimStart = 0, _trimEnd = 30;
  double _speed = 1.0;
  String? _processedPath;
  bool _processing = false;

  final _captionCtrl = TextEditingController();

  // Creative options
  String? _musicPath;
  String _filter = 'none';
  bool _voiceover = false;
  String _transition = 'none';

  static const _filters = {
    'none': 'none',
    'warm': 'colorbalance=rm=.2',
    'cool': 'colorbalance=bm=.2',
    'bw': 'hue=s=0'
  };

  List<String> _extractHashtags(String text) =>
      RegExp(r'#(\w+)')
          .allMatches(text)
          .map((m) => m.group(1)!.toLowerCase())
          .toSet()
          .toList();

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video);
    if (res == null) return;
    setState(() => _inputPath = res.files.single.path);
    _ctrl = VideoPlayerController.file(File(_inputPath!))
      ..initialize().then((_) {
        setState(() =>
            _trimEnd = _ctrl!.value.duration.inSeconds.toDouble());
      });
  }

  Future<void> _process() async {
    // ✅ FFmpegKit web-এ নেই — শুধু Android/iOS
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('⚠️ শর্ট এডিটর শুধু অ্যাপে — FFmpegKit Web-এ নেই')));
      return;
    }
    if (_inputPath == null) return;
    setState(() => _processing = true);

    // Output path — input ফাইলের পাশে (Directory লাগে না)
    final sep = _inputPath!.contains('\\') ? '\\' : '/';
    final dir =
        _inputPath!.substring(0, _inputPath!.lastIndexOf(sep) + 1);
    _processedPath =
        '${dir}short_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // FFmpeg command: trim + speed + filter
    final vf = <String>[
      if (_filters[_filter] != 'none') _filters[_filter]!,
      'setpts=${(1 / _speed).toStringAsFixed(3)}*PTS',
    ].join(',');

    final cmd = '-i "$_inputPath" -ss $_trimStart -to $_trimEnd '
        '${vf.isNotEmpty ? '-vf "$vf"' : ''} '
        '${_musicPath != null ? '-i "$_musicPath" -shortest' : ''} '
        '-c:v libx264 -preset veryfast -crf 26 -c:a aac "$_processedPath"';

    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();

    // temp input cleanup
    try {
      await File(_inputPath!).delete();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _processing = false);
    if (ReturnCode.isSuccess(rc)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ প্রসেস সম্পন্ন — এখন পাবলিশ করুন')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ প্রসেস ব্যর্থ')));
    }
  }

  Future<void> _upload() async {
    if (kIsWeb || _processedPath == null) return;
    final bytes = await File(_processedPath!).readAsBytes();
    final url = await VideoRepository.uploadVideoBytes(bytes,
        'short_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await VideoRepository.publishVideo(
      title: _captionCtrl.text.trim().isEmpty
          ? 'শর্ট'
          : _captionCtrl.text.trim(),
      videoUrl: url,
      tags: _extractHashtags(_captionCtrl.text),
      isShort: true,
      privacy: 'public',
      durationSeconds: ((_trimEnd - _trimStart) / _speed).round(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('শর্ট তৈরি করুন')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_inputPath == null)
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.video_library_outlined, size: 32),
              label: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ভিডিও বাছুন'),
              ),
            )
          else ...[
            if (_ctrl != null && _ctrl!.value.isInitialized)
              AspectRatio(
                aspectRatio: _ctrl!.value.aspectRatio,
                child: VideoPlayer(_ctrl!),
              ),
            const SizedBox(height: 12),
            Text(
              '✂️ ট্রিম: ${_trimStart.toStringAsFixed(1)}s → ${_trimEnd.toStringAsFixed(1)}s',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            RangeSlider(
              values: RangeValues(_trimStart, _trimEnd),
              min: 0,
              max: _ctrl?.value.duration.inSeconds.toDouble() ?? 60,
              onChanged: (r) => setState(() {
                _trimStart = r.start;
                _trimEnd = r.end;
              }),
            ),
            Text('⚡ স্পিড: ${_speed}x',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${_speed}x',
              onChanged: (v) => setState(() => _speed = v),
            ),
            const Text('🎨 ফিল্টার',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              children: [
                for (final f in _filters.keys)
                  ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('মিউজিক'),
              trailing: TextButton(
                onPressed: () async {
                  final r = await FilePicker.platform
                      .pickFiles(type: FileType.audio);
                  if (r != null) {
                    setState(() => _musicPath = r.files.single.path);
                  }
                },
                child: Text(_musicPath == null ? 'যোগ করুন' : '✅'),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.mic),
              title: const Text('ভয়েসওভার'),
              value: _voiceover,
              onChanged: (v) => setState(() => _voiceover = v),
            ),
            ListTile(
              leading: const Icon(Icons.animation),
              title: const Text('ট্রানজিশন'),
              trailing: DropdownButton<String>(
                value: _transition,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('নেই')),
                  DropdownMenuItem(value: 'fade', child: Text('Fade')),
                  DropdownMenuItem(
                      value: 'slide', child: Text('Slide')),
                ],
                onChanged: (v) => setState(() => _transition = v!),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.text_fields),
              title: Text('টেক্সট / স্টিকার'),
              subtitle: Text(
                  'ভিডিও ওভারলে — FFmpeg drawtext দিয়ে Phase 3.1-এ'),
            ),
            TextField(
              controller: _captionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'ক্যাপশন',
                  hintText: 'আমার শর্ট! #enjoy'),
            ),
            const SizedBox(height: 16),
            if (_processing) ...[
              const LinearProgressIndicator(),
              const Text('প্রসেস হচ্ছে…'),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _processing ? null : _process,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('এপ্লাই করুন (Trim+Speed+Filter)'),
            ),
            const SizedBox(height: 8),
            if (_processedPath != null && !_processing)
              FilledButton.icon(
                onPressed: _upload,
                icon: const Icon(Icons.upload),
                label: const Text('শর্ট পাবলিশ করুন'),
              ),
          ],
        ],
      ),
    );
  }
}