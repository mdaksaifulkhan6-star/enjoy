import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../video/data/video_repository.dart';

/// Professional Video Editor: Trim • Speed • Filter • PiP • Green Screen • Text • Audio
class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  String? _input;
  VideoPlayerController? _ctrl;
  double _start = 0, _end = 30, _speed = 1;
  String _filter = 'none';
  String? _music, _pipImage, _greenBg;
  String _text = '';
  bool _busy = false;
  String? _output;

  static const _filters = {
    'none': 'none',
    'bw': 'hue=s=0',
    'warm': 'colorbalance=rm=.2',
    'cool': 'colorbalance=bm=.2'
  };

  Future<void> _pickVideo() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r == null || r.files.single.path == null) return;
    setState(() => _input = r.files.single.path);
    await _ctrl?.dispose();
    _ctrl = VideoPlayerController.file(File(_input!))
      ..initialize().then((_) =>
          setState(() => _end = _ctrl!.value.duration.inSeconds.toDouble()));
  }

  Future<void> _pick(FileType t, void Function(String) set) async {
    final r = await FilePicker.platform.pickFiles(type: t);
    if (r != null && r.files.single.path != null) {
      set(r.files.single.path!);
      setState(() {});
    }
  }

  Future<void> _process() async {
    if (_input == null || _busy) return;
    setState(() {
      _busy = true;
      _output = null;
    });
    final sep = _input!.contains('\\') ? '\\' : '/';
    final dir = _input!.substring(0, _input!.lastIndexOf(sep) + 1);
    _output = '${dir}edit_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final inputs = <String>['-i "$_input"'];
    final vf = <String>[
      if (_filters[_filter] != 'none') _filters[_filter]!,
      'setpts=${(1 / _speed).toStringAsFixed(3)}*PTS',
    ];
    if (_text.isNotEmpty) {
      vf.add(
          "drawtext=text='$_text':fontcolor=white:fontsize=32:x=(w-text_w)/2:y=h-140:box=1:boxcolor=black@0.5:boxborderw=8");
    }

    var hasOverlay = false;
    var nextIdx = 1;
    final fc = StringBuffer();

    if (_pipImage != null) {
      inputs.add('-i "$_pipImage"');
      fc.write('[$nextIdx:v]scale=iw/4:ih/4[pip];');
      fc.write('[0:v]${vf.isNotEmpty ? vf.join(',') : 'null'}[base];');
      fc.write('[base][pip]overlay=W-w-12:12[vout]');
      hasOverlay = true;
      nextIdx++;
    } else if (_greenBg != null) {
      inputs.add('-i "$_greenBg"');
      fc.write(
          '[0:v]${vf.isNotEmpty ? vf.join(',') : 'null'},colorkey=0x00FF00:0.35:0.15[ck];');
      fc.write('[$nextIdx:v][ck]overlay=0:0[vout]');
      hasOverlay = true;
      nextIdx++;
    }

    String? audioMap;
    if (_music != null) {
      inputs.add('-i "$_music"');
      audioMap = ' -map $nextIdx:a -shortest';
    }

    final vEncoder = '-c:v libx264 -preset veryfast -crf 25';
    final aEncoder = audioMap != null ? '-c:a aac' : '-c:a copy';
    String cmd;
    if (hasOverlay) {
      cmd = '${inputs.join(' ')} -ss $_start -to $_end '
          '-filter_complex "${fc.toString()}" -map "[vout]"'
          '${audioMap ?? ' -map 0:a?'} $vEncoder $aEncoder "$_output"';
    } else {
      final vfc = vf.isNotEmpty ? '-vf "${vf.join(',')}"' : '';
      cmd = '${inputs.join(' ')} -ss $_start -to $_end $vfc -map 0:v'
          '${audioMap ?? ' -map 0:a?'} $vEncoder $aEncoder "$_output"';
    }

    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (!mounted) return;
    setState(() => _busy = false);
    final ok = rc != null && ReturnCode.isSuccess(rc);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '✅ এডিট সম্পন্ন — পাবলিশ করুন'
            : '❌ ব্যর্থ — একসাথে PiP + Green Screen ব্যবহার না করে আলাদা করে চেষ্টা করুন')));
  }

  Future<void> _publish() async {
    if (_output == null) return;
    final bytes = await File(_output!).readAsBytes();
    final url = await VideoRepository.uploadVideoBytes(
        bytes, 'edit_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await VideoRepository.publishVideo(
        title: '✨ Edited Video',
        videoUrl: url,
        privacy: 'public',
        durationSeconds: ((_end - _start) / _speed).round());
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ভিডিও এডিটর 🎬')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (_input == null)
            OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library_outlined, size: 32),
                label: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('ভিডিও বাছুন')))
          else ...[
            if (_ctrl?.value.isInitialized == true)
              AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio,
                  child: VideoPlayer(_ctrl!)),
            Text(
                '✂️ ট্রিম: ${_start.toStringAsFixed(1)}s → ${_end.toStringAsFixed(1)}s'),
            RangeSlider(
                values: RangeValues(_start, _end),
                min: 0,
                max: _ctrl?.value.duration.inSeconds.toDouble() ?? 60,
                onChanged: (r) =>
                    setState(() { _start = r.start; _end = r.end; })),
            Text('⚡ স্পিড: ${_speed}x'),
            Slider(
                value: _speed,
                min: .5,
                max: 2,
                divisions: 6,
                onChanged: (v) => setState(() => _speed = v)),
            Wrap(spacing: 8, children: [
              for (final f in _filters.keys)
                ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f)),
            ]),
            ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('অডিও/মিউজিক'),
                trailing: TextButton(
                    onPressed: () => _pick(FileType.audio, (p) => _music = p),
                    child: Text(_music == null ? 'যোগ' : '✅'))),
            ListTile(
                leading: const Icon(Icons.picture_in_picture_alt),
                title: const Text('PiP (ছবি overlay)'),
                trailing: TextButton(
                    onPressed: () =>
                        _pick(FileType.image, (p) => _pipImage = p),
                    child: Text(_pipImage == null ? 'যোগ' : '✅'))),
            ListTile(
                leading: const Icon(Icons.wallpaper),
                title: const Text('Green Screen (BG)'),
                subtitle: const Text('foreground-এ সবুজ পর্দা লাগবে'),
                trailing: TextButton(
                    onPressed: () => _pick(FileType.any, (p) => _greenBg = p),
                    child: Text(_greenBg == null ? 'যোগ' : '✅'))),
            TextField(
              decoration: const InputDecoration(labelText: 'টেক্সট overlay'),
              onChanged: (v) => _text = v,
            ),
            const SizedBox(height: 12),
            if (_busy)
              const Column(children: [
                LinearProgressIndicator(),
                Text('প্রসেস হচ্ছে…')
              ]),
            FilledButton.icon(
                onPressed: _busy ? null : _process,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('এপ্লাই করুন')),
            if (_output != null && !_busy)
              FilledButton.icon(
                  onPressed: _publish,
                  icon: const Icon(Icons.upload),
                  label: const Text('পাবলিশ করুন')),
          ],
        ]),
      );
}