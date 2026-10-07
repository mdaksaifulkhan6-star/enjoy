import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/post_repository.dart';

/// Text post + single/multiple photos
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  final Map<String, Uint8List> _bytesCache = {};
  bool _uploading = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked =
        await _picker.pickMultiImage(maxWidth: 1920, imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
      // ✅ bytes cache (web + mobile — কোনো dart:io লাগে না)
      for (final img in picked) {
        _bytesCache[img.name] = await img.readAsBytes();
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _publish() async {
    if (_textCtrl.text.trim().isEmpty && _images.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final urls = <String>[];
      for (final img in _images) {
        final bytes = _bytesCache[img.name] ?? await img.readAsBytes();
        final url = await PostRepository.uploadMediaBytes(
            bytes, '${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        urls.add(url);
      }
      await PostRepository.createPost(
          text: _textCtrl.text.trim(), mediaUrls: urls);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('পোস্ট করা যায়নি: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন পোস্ট'),
        actions: [
          _uploading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _publish,
                  child: const Text('পোস্ট করুন',
                      style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
                hintText: 'কী ভাবছেন? #hashtag ব্যবহার করুন'),
          ),
          const SizedBox(height: 8),
          if (_images.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final bytes = _bytesCache[_images[i].name];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // ✅ bytes থেকে preview — web/mobile দুটোতেই
                        child: bytes != null
                            ? Image.memory(bytes,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover)
                            : Container(
                                width: 110,
                                height: 110,
                                color: Colors.grey.shade300,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _bytesCache.remove(_images[i].name);
                            _images.removeAt(i);
                          }),
                          child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('ছবি যোগ করুন (${_images.length})'),
          ),
        ],
      ),
    );
  }
}