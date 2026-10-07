import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../data/video_repository.dart';
import '../data/download_service.dart';

/// Quality + format selection, live progress, pause/resume, retry
void showDownloadSheet(BuildContext context, Video video) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    showDragHandle: true,
    builder: (_) => _DownloadSheet(video: video),
  );
}

class _DownloadSheet extends StatefulWidget {
  final Video video;
  const _DownloadSheet({required this.video});

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  String _quality = '720p';
  String _format = 'mp4';
  String _status = 'idle'; // idle, downloading, paused, completed, failed
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    DownloadService.stream.listen((s) {
      if (!mounted) return;
      setState(() {
        _status = s.status;
        _progress = s.progress;
        _error = s.error;
      });
      if (s.status == 'completed') {
        NotificationService.showLocal(
            'ডাউনলোড সম্পন্ন ✅', widget.video.title);
      }
    });
  }

  Future<void> _start() async {
    final name = 'enjoy_${widget.video.id.substring(0, 8)}';
    await DownloadService.download(
      videoId: widget.video.id,
      url: widget.video.videoUrl,
      quality: _quality,
      format: _format,
      fileName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _status == 'downloading';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.video.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          const Text('কোয়ালিটি',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final q in ['1080p', '720p', '480p'])
              ChoiceChip(
                label: Text(q),
                selected: _quality == q,
                onSelected: busy ? null : (_) => setState(() => _quality = q),
              ),
          ]),
          const SizedBox(height: 12),
          const Text('ফরম্যাট',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final f in ['mp4', 'webm'])
              ChoiceChip(
                label: Text(f),
                selected: _format == f,
                onSelected: busy ? null : (_) => setState(() => _format = f),
              ),
          ]),
          const SizedBox(height: 20),
          if (_status == 'downloading' || _status == 'paused') ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(1)}%'),
          ],
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (busy)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: DownloadService.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ),
              if (busy) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          if (_status == 'paused') {
                            _start(); // resume (Range header)
                          } else if (_status == 'failed') {
                            DownloadService.cancel();
                            _start(); // retry
                          } else {
                            _start();
                          }
                        },
                  icon: Icon(_status == 'paused'
                      ? Icons.play_arrow
                      : _status == 'failed'
                          ? Icons.refresh
                          : Icons.download),
                  label: Text(
                    _status == 'paused'
                        ? 'Resume'
                        : _status == 'failed'
                            ? 'Retry'
                            : _status == 'completed'
                                ? 'সম্পন্ন ✅'
                                : 'ডাউনলোড শুরু',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}