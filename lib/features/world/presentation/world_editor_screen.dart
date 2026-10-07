import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/world_repository.dart';

class WorldEditorScreen extends StatefulWidget {
  final WorldScene? existing;
  const WorldEditorScreen({super.key, this.existing});

  @override
  State<WorldEditorScreen> createState() => _WorldEditorScreenState();
}

class _WorldEditorScreenState extends State<WorldEditorScreen> {
  static const _w = 32, _h = 32;
  late List<int> _tiles;
  final List<Map<String, dynamic>> _objects = [];
  final _nameCtrl = TextEditingController();
  int _selectedTile = 0;
  String? _selectedAsset;
  List<Map<String, dynamic>> _assets = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl.text = e?.name ?? '';
    _tiles = e != null && e.tiles.length == _w * _h
        ? List<int>.from(e.tiles)
        : List<int>.filled(_w * _h, 0);
    if (e != null) _objects.addAll(e.objects);
    _loadAssets();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    _assets = await WorldRepository.assets();
    if (mounted) setState(() {});
  }

  Future<void> _save({bool publish = false}) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await WorldRepository.save(
        sceneId: widget.existing?.id,
        name: _nameCtrl.text.trim(),
        gridW: _w,
        gridH: _h,
        tiles: _tiles,
        objects: _objects,
        publish: publish,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ সেভ হয়েছে (version+1)')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _nameCtrl,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
              hintText: 'দৃশ্যের নাম', border: InputBorder.none),
        ),
        actions: [
          IconButton(
            tooltip: 'AI Generate',
            icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
            onPressed: () => setState(() => _tiles = WorldRepository.aiGenerate(
                _w, _h, seed: DateTime.now().millisecond)),
          ),
          IconButton(
            tooltip: 'Publish',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _saving ? null : () => _save(publish: true),
          ),
          TextButton(
              onPressed: _saving ? null : () => _save(),
              child: const Text('সেভ')),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (var i = 0; i < WorldRepository.tileEmojis.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(WorldRepository.tileEmojis[i]),
                    selected: _selectedTile == i && _selectedAsset == null,
                    onSelected: (_) => setState(() {
                      _selectedTile = i;
                      _selectedAsset = null;
                    }),
                  ),
                ),
              const VerticalDivider(),
              for (final a in _assets)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${a['emoji']} ${a['name']}'),
                    selected: _selectedAsset == a['name'],
                    onSelected: (_) =>
                        setState(() => _selectedAsset = a['name'] as String),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GestureDetector(
            onPanUpdate: _paintAt,
            onTapDown: _paintAt,
            child: AspectRatio(
              aspectRatio: _w / _h,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _w),
                itemCount: _w * _h,
                itemBuilder: (_, i) {
                  final obj = _objects.where(
                      (o) => o['x'] == i % _w && o['y'] == i ~/ _w);
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade200, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        obj.isNotEmpty
                            ? _emojiFor(obj.first['asset']?.toString() ?? '')
                            : WorldRepository
                                .tileEmojis[_tiles[i].clamp(0, 5)],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _selectedAsset != null
                ? 'অবজেক্ট: $_selectedAsset — গ্রিডে ট্যাপ করে বসান'
                : 'টাইল: $_selectedTile — পেইন্ট করতে ড্র্যাগ/ট্যাপ করুন',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ]),
    );
  }

  void _paintAt(dynamic details) {
    final box = context.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(details.globalPosition as Offset);
    final gridTop = 56.0 +
        1 +
        kToolbarHeight +
        MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size.width;
    final cell = size / _w;
    final gx = (local.dx / cell).floor();
    final gy = ((local.dy - gridTop) / cell).floor();
    if (gx < 0 || gy < 0 || gx >= _w || gy >= _h) return;
    setState(() {
      if (_selectedAsset != null) {
        _objects.removeWhere((o) => o['x'] == gx && o['y'] == gy);
        _objects.add({'x': gx, 'y': gy, 'asset': _selectedAsset});
      } else {
        _tiles[gy * _w + gx] = _selectedTile;
      }
    });
  }

  String _emojiFor(String asset) {
    final a = _assets.where((x) => x['name'] == asset);
    return a.isNotEmpty ? a.first['emoji'] as String : '📦';
  }
}