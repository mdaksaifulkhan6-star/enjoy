import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/video_repository.dart';

/// Upload → Preview → Title/Description/Thumbnail/Category/Tags/Privacy → Publish
class UploadVideoScreen extends StatefulWidget {
  final bool asShort;
  const UploadVideoScreen({super.key, this.asShort = false});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  PlatformFile? _videoFile;
  VideoPlayerController? _previewCtrl;
  PlatformFile? _thumbFile;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String _category = 'জেনারেল';
  String _privacy = 'public';
  bool _allowDownload = false;
  bool _copyright = false;
  bool _borrowEligible = false;
  bool _publishing = false;

  static const _categories = [
    'জেনারেল', 'গেমিং', 'শিক্ষা', 'মিউজিক', 'ভ্লগ', 'কমেডি', 'স্পোর্টস'
  ];

  @override
  void dispose() {
    _previewCtrl?.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.video, withData: true);
    if (res == null) return;
    setState(() => _videoFile = res.files.single);
    await _previewCtrl?.dispose();
    _previewCtrl = kIsWeb
        ? VideoPlayerController.networkUrl(
            Uri.parse(_videoFile!.path!))
        : VideoPlayerController.file(File(_videoFile!.path!));
    _previewCtrl!.initialize().then((_) => setState(() {}));
  }

  Future<void> _pickThumbnail() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (res != null) setState(() => _thumbFile = res.files.single);
  }

  Future<void> _publish() async {
    if (_videoFile == null || _titleCtrl.text.trim().isEmpty) return;
    if (_videoFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ভিডিও পড়া যায়নি — আবার বাছুন')));
      return;
    }
    setState(() => _publishing = true);
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_videoFile!.name}';
      final videoUrl = await VideoRepository.uploadVideoBytes(
          _videoFile!.bytes!, fileName);

      String? thumbUrl;
      if (_thumbFile?.bytes != null) {
        thumbUrl = await VideoRepository.uploadThumbnailBytes(
            _thumbFile!.bytes!, 'thumb_$fileName.jpg');
      }

      final duration = _previewCtrl?.value.duration.inSeconds ?? 0;

      await VideoRepository.publishVideo(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        videoUrl: videoUrl,
        thumbnailUrl: thumbUrl,
        category: _category,
        tags:
            _tagsCtrl.text.split(' ').where((t) => t.isNotEmpty).toList(),
        privacy: _privacy,
        allowDownload: _allowDownload,
        copyrightProtected: _copyright,
        borrowEligible: _borrowEligible,
        isShort: widget.asShort,
        durationSeconds: duration,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'পাবলিশ ব্যর্থ: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.asShort ? 'শর্ট আপলোড' : 'ভিডিও আপলোড')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_videoFile == null)
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam_outlined, size: 32),
              label: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ভিডিও নির্বাচন করুন'),
              ),
            )
          else if (_previewCtrl != null &&
              _previewCtrl!.value.isInitialized)
            AspectRatio(
              aspectRatio: _previewCtrl!.value.aspectRatio,
              child: VideoPlayer(_previewCtrl!),
            ),
          if (_previewCtrl != null &&
              _previewCtrl!.value.isInitialized) ...[
            const SizedBox(height: 8),
            Text(
                'Duration: ${_previewCtrl!.value.duration.inSeconds}s • ${_videoFile!.name}'),
          ],
          if (_publishing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const Text('আপলোড হচ্ছে… (বড় ভিডিওতে কিছুটা সময় লাগবে)'),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'টাইটেল *'),
          ),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'ডেসক্রিপশন'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickThumbnail,
            icon: const Icon(Icons.image_outlined),
            label: Text(_thumbFile == null
                ? 'থাম্বনেইল বাছুন (ঐচ্ছিক)'
                : '✅ থাম্বনেইল নির্বাচিত'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c, child: Text(c))
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(
                labelText: 'ট্যাগস (স্পেস দিয়ে আলাদা করুন)',
                hintText: 'gaming flutter bangla'),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'public',
                  label: Text('Public'),
                  icon: Icon(Icons.public)),
              ButtonSegment(
                  value: 'friends',
                  label: Text('FNF'),
                  icon: Icon(Icons.group)),
              ButtonSegment(
                  value: 'private',
                  label: Text('Private'),
                  icon: Icon(Icons.lock)),
            ],
            selected: {_privacy},
            onSelectionChanged: (s) =>
                setState(() => _privacy = s.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('ডাউনলোড অনুমতি'),
            subtitle: const Text('দর্শকরা ডাউনলোড করতে পারবে'),
            value: _allowDownload,
            onChanged: (v) => setState(() => _allowDownload = v),
          ),
          SwitchListTile(
            title: const Text('© কপিরাইট প্রোটেকশন'),
            subtitle: const Text('ডাউনলোড সম্পূর্ণ বন্ধ থাকবে'),
            value: _copyright,
            onChanged: (v) => setState(() => _copyright = v),
          ),
          SwitchListTile(
            title: const Text('🔄 Life-Borrow Eligible'),
            subtitle: const Text(
                'অন্যরা Borrow বাটন দিয়ে রিকোয়েস্ট করতে পারবে'),
            value: _borrowEligible,
            onChanged: (v) => setState(() => _borrowEligible = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                (_videoFile == null || _publishing) ? null : _publish,
            icon: _publishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.publish),
            label: Text(_publishing ? 'পাবলিশ হচ্ছে…' : 'পাবলিশ করুন'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}