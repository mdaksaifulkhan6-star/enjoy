import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldScene {
  final String id, creatorId, name;
  final int gridW, gridH, version;
  final List<int> tiles;
  final List<Map<String, dynamic>> objects;
  final bool isPublished;
  const WorldScene({required this.id, required this.creatorId,
      required this.name, this.gridW = 32, this.gridH = 32,
      this.version = 1, this.tiles = const [], this.objects = const [],
      this.isPublished = false});
  factory WorldScene.fromMap(Map<String, dynamic> m) => WorldScene(
      id: m['id'], creatorId: m['creator_id'], name: m['name'],
      gridW: m['grid_w'] ?? 32, gridH: m['grid_h'] ?? 32,
      version: m['version'] ?? 1,
      tiles: (m['tiles'] as List).map((e) => (e as num).toInt()).toList(),
      objects: (m['objects'] as List).cast<Map<String, dynamic>>(),
      isPublished: m['is_published'] ?? false);
}

class WorldRepository {
  WorldRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  /// Tiles: 0=grass 1=water 2=sand 3=road 4=forest 5=building
  static const tileEmojis = ['🟩', '🟦', '🟨', '⬛', '🌲', '🏠'];

  static Future<List<WorldScene>> myScenes() async {
    final rows = await _db.from('world_scenes').select()
        .eq('creator_id', _myId).order('updated_at', ascending: false);
    return (rows as List)
        .map((r) => WorldScene.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Save — version control (প্রতি save-এ version+1 + history row)
  static Future<WorldScene> save({
    String? sceneId, required String name, required int gridW,
    required int gridH, required List<int> tiles,
    required List<Map<String, dynamic>> objects, bool publish = false,
  }) async {
    Map<String, dynamic> row;
    if (sceneId == null) {
      row = await _db.from('world_scenes').insert({
        'creator_id': _myId, 'name': name, 'grid_w': gridW,
        'grid_h': gridH, 'tiles': tiles, 'objects': objects,
        'is_published': publish,
      }).select().single();
    } else {
      row = await _db.rpc('save_scene', params: {
        'p_scene_id': sceneId, 'p_name': name, 'p_tiles': tiles,
        'p_objects': objects, 'p_publish': publish,
      }).select().single();
    }
    return WorldScene.fromMap(row);
  }

  static Future<List<Map<String, dynamic>>> assets() async {
    final rows = await _db.from('asset_library').select().order('category');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// 🧠 AI-Assisted (foundation): seeded procedural terrain —
  /// hills (forest), rivers (water), beaches (sand)
  static List<int> aiGenerate(int w, int h, {int seed = 7}) {
    final rnd = Random(seed);
    final tiles = List<int>.filled(w * h, 0);
    final riverX = rnd.nextInt(w);
    for (var y = 0; y < h; y++) {
      final rx = (riverX + sin(y / 3) * 2).round();
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if ((x - rx).abs() <= 0) { tiles[i] = 1; }
        else if ((x - rx).abs() == 1) { tiles[i] = 2; }
        else if (rnd.nextDouble() < 0.08) { tiles[i] = 4; }
        else if (rnd.nextDouble() < 0.02) { tiles[i] = 5; }
      }
    }
    return tiles;
  }
}