import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/chat_repository.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String? groupId;
  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.isGroup = false,
    this.groupId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  Message? _replyTo;
  bool _recording = false;

  String get _myId => Supabase.instance.client.auth.currentUser!.id;

  @override
  void dispose() {
    _ctrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send({
    String type = 'text',
    String? content,
    String? mediaUrl,
  }) async {
    if (type == 'text' && _ctrl.text.trim().isEmpty) return;
    await ChatRepository.sendMessage(
      convId: widget.conversationId,
      type: type,
      content: content ?? (type == 'text' ? _ctrl.text.trim() : null),
      mediaUrl: mediaUrl,
      replyToId: _replyTo?.id,
    );
    _ctrl.clear();
    setState(() => _replyTo = null);
  }

  Future<Uint8List?> _bytesOf(PlatformFile f) async {
    if (f.bytes != null) return f.bytes;
    if (f.path != null) return File(f.path!).readAsBytes();
    return null;
  }

  Future<void> _sendImage() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1920);
    if (img == null) return;
    final url = await ChatRepository.uploadChatMediaBytes(
        await img.readAsBytes(),
        '${DateTime.now().millisecondsSinceEpoch}_${img.name}');
    await _send(type: 'image', mediaUrl: url);
  }

  Future<void> _sendVideo() async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.video, withData: true);
    if (r == null) return;
    final f = r.files.single;
    final bytes = await _bytesOf(f);
    if (bytes == null) return;
    final url = await ChatRepository.uploadChatMediaTyped(
        bytes,
        '${DateTime.now().millisecondsSinceEpoch}_${f.name}',
        'video/mp4');
    await _send(type: 'video', mediaUrl: url);
  }

  Future<void> _sendFile() async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r == null) return;
    final f = r.files.single;
    final bytes = await _bytesOf(f);
    if (bytes == null) return;
    final url = await ChatRepository.uploadChatMediaTyped(
        bytes,
        '${DateTime.now().millisecondsSinceEpoch}_${f.name}',
        'application/octet-stream');
    await _send(type: 'file', mediaUrl: url, content: f.name);
  }

  // ── Voice message (mic চেপে রেকর্ড, আবার চাপ দিয়ে পাঠান) ──
  Future<void> _toggleRecord() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Voice message শুধু অ্যাপে (Android/iOS)')));
      return;
    }
    if (!await _recorder.hasPermission()) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      final url = await ChatRepository.uploadChatMediaTyped(
          bytes,
          'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          'audio/mp4');
      await _send(type: 'voice', mediaUrl: url);
    } else {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // ✅ record 5.x: path হলো named required parameter
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() => _recording = true);
    }
  }

  // ── Mention (@) — group member picker ──
  Future<void> _pickMention() async {
    final members =
        await ChatRepository.membersOf(widget.conversationId);
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final m in members)
            if (m['user_id'] != _myId)
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(
                    ((m['profiles']?['full_name'] ?? '')
                                .toString()
                                .isNotEmpty
                            ? '${m['profiles']?['full_name']}'
                            : '${m['profiles']?['username']}')
                        .toString()),
                onTap: () => Navigator.pop(
                    ctx,
                    (m['profiles']?['username'] ?? 'user')
                        .toString()),
              ),
        ]),
      ),
    );
    if (picked != null) {
      _ctrl.text = '${_ctrl.text}@$picked ';
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  void _onMessageLongPress(Message m) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('রিপ্লাই'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = m);
              }),
          const Divider(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              for (final e in ['❤️', '😂', '👍', '😮', '😢'])
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      ChatRepository.toggleReaction(m.id, e);
                    },
                    child: Text(e,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// @mention highlight সহ rich text
  Widget _richText(String content, Color color) {
    final spans = <TextSpan>[];
    for (final part in content.split(' ')) {
      if (part.startsWith('@')) {
        spans.add(TextSpan(
            text: '$part ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800)));
      } else {
        spans.add(TextSpan(text: '$part '));
      }
    }
    return Text.rich(
        TextSpan(children: spans, style: TextStyle(color: color)));
  }

  Widget _media(Message m, bool mine) {
    switch (m.type) {
      case 'image':
        return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
                imageUrl: m.mediaUrl!, width: 200));
      case 'video':
        return _ChatVideo(url: m.mediaUrl!);
      case 'voice':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_circle_fill,
              color: mine ? Colors.white : AppColors.primary),
          const SizedBox(width: 6),
          Text('🎤 Voice message',
              style: TextStyle(
                  color: mine ? Colors.white : Colors.black87)),
        ]);
      case 'file':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.insert_drive_file,
              color: mine ? Colors.white70 : Colors.grey),
          const SizedBox(width: 6),
          Flexible(
              child: Text(m.content ?? 'File',
                  style: TextStyle(
                      color:
                          mine ? Colors.white : Colors.black87))),
        ]);
      default:
        return _richText(
            m.content ?? '', mine ? Colors.white : Colors.black87);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(children: [
          if (_recording)
            Container(
              width: double.infinity,
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                  '🎙️ রেকর্ড হচ্ছে… আবার চাপ দিয়ে পাঠান',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream:
                  ChatRepository.messagesStream(widget.conversationId),
              builder: (context, snap) {
                if (!snap.hasData) return AppStates.loading();
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return AppStates.empty(
                      title: 'কোনো মেসেজ নেই',
                      icon: Icons.chat_outlined);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.senderId == _myId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _onMessageLongPress(m),
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context)
                                      .size
                                      .width *
                                  0.75),
                          decoration: BoxDecoration(
                            gradient:
                                mine ? AppColors.brandGradient : null,
                            color: mine ? null : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft:
                                  Radius.circular(mine ? 16 : 4),
                              bottomRight:
                                  Radius.circular(mine ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (m.replyToId != null)
                                Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Text('↩ রিপ্লাই',
                                      style:
                                          TextStyle(fontSize: 11)),
                                ),
                              _media(m, mine),
                              const SizedBox(height: 3),
                              Text(timeago.format(m.createdAt),
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: mine
                                          ? Colors.white70
                                          : Colors
                                              .grey
                                              .shade600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Row(children: [
                const Icon(Icons.reply, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_replyTo!.content ?? '[media]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                GestureDetector(
                    onTap: () => setState(() => _replyTo = null),
                    child: const Icon(Icons.close, size: 16)),
              ]),
            ),
          SafeArea(
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  onPressed: _sendVideo),
              IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _sendFile),
              IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _sendImage),
              if (widget.isGroup)
                IconButton(
                    icon: const Icon(Icons.alternate_email),
                    onPressed: _pickMention),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                      hintText: 'মেসেজ লিখুন…',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16)),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                icon: Icon(
                    _recording ? Icons.stop : Icons.mic,
                    color: _recording
                        ? Colors.red
                        : AppColors.primary),
                onPressed: _toggleRecord,
              ),
              IconButton(
                icon: const Icon(Icons.send,
                    color: AppColors.primary),
                onPressed: () => _send(),
              ),
            ]),
          ),
        ]),
      );
}

class _ChatVideo extends StatefulWidget {
  final String url;
  const _ChatVideo({required this.url});

  @override
  State<_ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends State<_ChatVideo> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ctrl.value.isInitialized
      ? GestureDetector(
          onTap: () => setState(() => _ctrl.value.isPlaying
              ? _ctrl.pause()
              : _ctrl.play()),
          child: SizedBox(
            width: 200,
            child: AspectRatio(
                aspectRatio: _ctrl.value.aspectRatio,
                child: VideoPlayer(_ctrl)),
          ),
        )
      : const SizedBox(
          width: 200,
          height: 120,
          child: Center(child: CircularProgressIndicator()));
}