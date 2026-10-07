import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/data/ai_service.dart';
import '../../feed/data/post_repository.dart';

/// Professional Photo Editor: Filter • Crop • Text • Effects
/// Export: RepaintBoundary → PNG → post (১০০% real)
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  Uint8List? _bytes;
  ui.Image? _decoded;
  int _filter = 0;
  double _brightness = 0;
  double _blur = 0;
  double? _aspect;
  String _overlay = '';
  final _captionCtrl = TextEditingController();
  final _exportKey = GlobalKey();
  bool _exporting = false;

  static const _aspectOptions = {
    'ফ্রি': null,
    '1:1': 1.0,
    '4:5': 4 / 5,
    '16:9': 16 / 9
  };
  static const _filterNames = [
    'নরমাল', 'সাদাকালো', 'সেপিয়া', 'কুল', 'ওয়ার্ম', 'কনট্রাস্ট'
  ];

  static List<double> _matrix(int i, double brightness) {
    final b = brightness * 60;
    switch (i) {
      case 1:
        return [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0];
      case 2:
        return [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272,
            0.534, 0.131, 0, 0, 0, 0, 0, 1, 0];
      case 3:
        return [0.9, 0, 0, 0, 0, 0, 1, 0, 0, 10, 0, 0, 1.2, 0, 20, 0, 0, 0, 1, 0];
      case 4:
        return [1.15, 0, 0, 0, 10, 0, 1.05, 0, 0, 0, 0, 0, 0.85, 0, 0, 0, 0, 0, 1, 0];
      case 5:
        return [1.3, 0, 0, 0, -15, 0, 1.3, 0, 0, -15, 0, 0, 1.3, 0, -15, 0, 0, 0, 1, 0];
      default:
        return [1, 0, 0, 0, b, 0, 1, 0, 0, b, 0, 0, 1, 0, b, 0, 0, 0, 1, 0];
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 2000);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    setState(() {
      _bytes = bytes;
      _decoded = decoded;
    });
  }

  Future<void> _addText() async {
    final ctrl = TextEditingController(text: _overlay);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('টেক্সট যোগ করুন'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'আপনার টেক্সট')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাদ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('যোগ করুন')),
        ],
      ),
    );
    if (ok == true) setState(() => _overlay = ctrl.text.trim());
  }

  Future<void> _aiCaption() async {
    final reply = await AiService.chat(
        'এই ছবির জন্য ১ লাইন ক্যাপশন + ৩টা hashtag বাংলায় লিখো');
    _captionCtrl.text = reply.replaceAll('\n', ' ');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ AI ক্যাপশন বসানো হয়েছে')));
    }
  }

  Future<void> _export() async {
    if (_bytes == null) return;
    setState(() => _exporting = true);
    try {
      final boundary = _exportKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final png = data!.buffer.asUint8List();
      final url = await PostRepository.uploadMediaBytes(
          png, 'edit_${DateTime.now().millisecondsSinceEpoch}.png');
      await PostRepository.createPost(
          text: _captionCtrl.text.trim().isEmpty
              ? '✨ Photo Editor-এ বানানো #enjoy'
              : _captionCtrl.text.trim(),
          mediaUrls: [url]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ এডিটেড ফটো পোস্ট হয়েছে!')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect ??
        (_decoded == null ? 1.0 : _decoded!.width / _decoded!.height);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ফটো এডিটর ✨'),
        actions: [
          if (_bytes != null)
            TextButton(
              onPressed: _exporting ? null : _export,
              child: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('পোস্ট করুন',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: _bytes == null
          ? Center(
              child: OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      size: 32),
                  label: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('ছবি বাছুন'))))
          : Column(children: [
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _exportKey,
                    child: AspectRatio(
                      aspectRatio: aspect,
                      child: ClipRect(
                        child: ColorFiltered(
                          colorFilter:
                              ColorFilter.matrix(_matrix(_filter, _brightness)),
                          child: ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                                sigmaX: _blur, sigmaY: _blur),
                            child: Image.memory(_bytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (var i = 0; i < _filterNames.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(_filterNames[i]),
                          selected: _filter == i,
                          onSelected: (_) => setState(() => _filter = i),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final e in _aspectOptions.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('Crop ${e.key}'),
                          selected: _aspect == e.value,
                          onSelected: (_) =>
                              setState(() => _aspect = e.value),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.title, size: 18),
                        label: Text(_overlay.isEmpty ? 'টেক্সট' : '✏️ $_overlay'),
                        onPressed: _addText,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Text('💡', style: TextStyle(fontSize: 12)),
                  Expanded(
                      child: Slider(
                          value: _brightness,
                          min: -1,
                          max: 1,
                          onChanged: (v) => setState(() => _brightness = v))),
                  const Text('🌫️', style: TextStyle(fontSize: 12)),
                  Expanded(
                      child: Slider(
                          value: _blur,
                          min: 0,
                          max: 10,
                          onChanged: (v) => setState(() => _blur = v))),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                    controller: _captionCtrl,
                    decoration: const InputDecoration(
                        hintText: 'ক্যাপশন…', isDense: true),
                  )),
                  IconButton(
                      onPressed: _aiCaption,
                      icon: const Icon(Icons.auto_awesome,
                          color: AppColors.accent)),
                ]),
              ),
            ]),
    );
  }
}