import 'package:flutter/material.dart';
import '../data/live_repository.dart';
import 'live_watch_screen.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _category = 'জেনারেল';
  bool _starting = false;

  static const _cats = ['জেনারেল', 'গেমিং', 'শিক্ষা', 'মিউজিক', 'টক শো', 'ইভেন্ট'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_titleCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) return;
    setState(() => _starting = true);
    try {
      final id = await LiveRepository.goLive(
        title: _titleCtrl.text.trim(),
        streamUrl: _urlCtrl.text.trim(),
        category: _category,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => LiveWatchScreen(room: {
                    'id': id,
                    'title': _titleCtrl.text.trim(),
                    'stream_url': _urlCtrl.text.trim(),
                    'host_id': '',
                    'is_host': true,
                  })));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))));
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Go Live 🔴')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
            controller: _titleCtrl,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'লাইভের টাইটেল *'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
            items: [
              for (final c in _cats) DropdownMenuItem(value: c, child: Text(c))
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
                labelText: 'HLS Stream URL (.m3u8) *',
                hintText: 'https://…/stream.m3u8'),
          ),
          const SizedBox(height: 8),
          const Card(
            color: Color(0xFFFFF8E1),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  '📡 Broadcast: OBS/Streamlabs দিয়ে RTMP → HLS provider '
                  '(Mux/Cloudflare Stream/AWS IVS) থেকে .m3u8 URL বসান।',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _starting ? null : _start,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.podcasts),
            label: Text(_starting ? 'শুরু হচ্ছে…' : '🔴 লাইভ শুরু করুন'),
          ),
        ]),
      );
}