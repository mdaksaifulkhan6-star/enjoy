import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class _Player {
  final String key, name;
  double x, y;
  _Player(this.key, this.name, this.x, this.y);
}

/// Social + Gaming Virtual World (realtime multiplayer)
class EnjoyWorldScreen extends StatefulWidget {
  const EnjoyWorldScreen({super.key});

  @override
  State<EnjoyWorldScreen> createState() => _EnjoyWorldScreenState();
}

class _EnjoyWorldScreenState extends State<EnjoyWorldScreen> {
  static const _worldW = 64.0, _worldH = 64.0;
  final _me = _Player('me', 'আমি', 32, 32);
  final Map<String, _Player> _others = {};
  final List<_Bubble> _bubbles = [];
  RealtimeChannel? _channel;
  Timer? _weatherTimer;
  String? _weather;
  final _chatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connect();
    _weatherTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => setState(() =>
            _weather = ['rain', 'snow', null][Random().nextInt(3)]));
  }

  Future<void> _connect() async {
    final db = Supabase.instance.client;
    final myName =
        db.auth.currentUser?.userMetadata?['full_name']?.toString() ??
            'Player';
    _channel = db.channel('enjoy-world-public')
      ..onPresenceSync((_) => _syncPresence())
      ..onBroadcast(
          event: 'chat',
          callback: (payload) {
            _bubbles.add(_Bubble(
                payload['name']?.toString() ?? '',
                payload['text']?.toString() ?? '',
                (payload['x'] as num?)?.toDouble() ?? 32,
                (payload['y'] as num?)?.toDouble() ?? 32,
                DateTime.now()));
            if (mounted) setState(() {});
          })
      ..subscribe((status, [_]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _channel
              ?.track({'name': myName, 'x': _me.x, 'y': _me.y});
        }
      });
  }

  void _syncPresence() {
    // ✅ Version-safe: supabase_flutter 2.17+ presenceState() typing
    //    (Map / List / nullable — সব কেসে dynamic দিয়ে handle)
    final dynamic raw = _channel?.presenceState();
    _others.clear();
    if (raw is Map) {
      raw.forEach((dynamic key, dynamic presences) {
        final list = presences is List ? presences : [presences];
        for (final p in list) {
          if (p is! Map) continue;
          final data =
              p['presence'] is Map ? p['presence'] as Map : p;
          final name = data['name']?.toString();
          if (name != null) {
            _others[key.toString()] = _Player(
              key.toString(),
              name,
              (data['x'] as num?)?.toDouble() ?? 32,
              (data['y'] as num?)?.toDouble() ?? 32,
            );
          }
        }
      });
    } else if (raw is List) {
      // কোনো ভার্সনে সরাসরি List return করলে
      for (final p in raw) {
        if (p is! Map) continue;
        final data = p['presence'] is Map ? p['presence'] as Map : p;
        final name = data['name']?.toString();
        if (name != null) {
          _others[name] = _Player(
            name,
            name,
            (data['x'] as num?)?.toDouble() ?? 32,
            (data['y'] as num?)?.toDouble() ?? 32,
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _move(double dx, double dy) async {
    setState(() {
      _me.x = (_me.x + dx).clamp(0, _worldW);
      _me.y = (_me.y + dy).clamp(0, _worldH);
    });
    await _channel
        ?.track({'name': _me.name, 'x': _me.x, 'y': _me.y});
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    _bubbles
        .add(_Bubble(_me.name, text, _me.x, _me.y, DateTime.now()));
    await _channel?.sendBroadcastMessage(
        event: 'chat',
        payload: {
          'name': _me.name,
          'text': text,
          'x': _me.x,
          'y': _me.y
        });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _weatherTimer?.cancel();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;
    return Scaffold(
      backgroundColor:
          isNight ? const Color(0xFF0B1020) : const Color(0xFF87CEEB),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (d) =>
                  _move(d.delta.dx / 12, d.delta.dy / 12),
              onTapDown: (d) {
                final size = context.size!;
                _move((d.localPosition.dx - size.width / 2) / 24,
                    (d.localPosition.dy - size.height / 2) / 24);
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _WorldPainter(
                    me: _me,
                    others: _others.values.toList(),
                    bubbles: _bubbles,
                    night: isNight,
                    weather: _weather),
              ),
            ),
          ),
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            child: Row(children: [
              Text('🌐 অনলাইন: ${_others.length + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
              const Spacer(),
              for (final (icon, dx, dy) in [
                (Icons.arrow_upward, 0.0, -1.0),
                (Icons.arrow_downward, 0.0, 1.0),
                (Icons.arrow_back, -1.0, 0.0),
                (Icons.arrow_forward, 1.0, 0.0),
              ])
                IconButton(
                  icon: Icon(icon, color: Colors.white, size: 20),
                  onPressed: () => _move(dx * 2, dy * 2),
                ),
            ]),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                      hintText: 'ওয়ার্ল্ড চ্যাট…',
                      hintStyle:
                          TextStyle(color: Colors.white38),
                      isDense: true,
                      border: InputBorder.none),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.send,
                      color: AppColors.primary),
                  onPressed: _sendChat),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble {
  final String name, text;
  final double x, y;
  final DateTime at;
  _Bubble(this.name, this.text, this.x, this.y, this.at);
  bool get alive => DateTime.now().difference(at).inSeconds < 6;
}

class _WorldPainter extends CustomPainter {
  final _Player me;
  final List<_Player> others;
  final List<_Bubble> bubbles;
  final bool night;
  final String? weather;
  _WorldPainter(
      {required this.me,
      required this.others,
      required this.bubbles,
      required this.night,
      this.weather});

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / 16;
    final ox = size.width / 2 - me.x * tile;
    final oy = size.height / 2 - me.y * tile;
    final rnd = Random(42);
    for (var gy = 0; gy < 64; gy++) {
      for (var gx = 0; gx < 64; gx++) {
        final r = rnd.nextDouble();
        final color = r < 0.6
            ? (night
                ? const Color(0xFF14351B)
                : const Color(0xFF4CAF50))
            : r < 0.7
                ? (night
                    ? const Color(0xFF1A2E4A)
                    : const Color(0xFF64B5F6))
                : r < 0.78
                    ? const Color(0xFF9E9E9E)
                    : r < 0.95
                        ? (night
                            ? const Color(0xFF0E2A14)
                            : const Color(0xFF2E7D32))
                        : const Color(0xFF795548);
        canvas.drawRect(
            Rect.fromLTWH(
                ox + gx * tile, oy + gy * tile, tile, tile),
            Paint()..color = color);
      }
    }

    void drawPlayer(_Player p, bool isMe) {
      final cx = ox + p.x * tile, cy = oy + p.y * tile;
      canvas.drawCircle(
          Offset(cx, cy),
          tile * 0.6,
          Paint()
            ..color = isMe
                ? AppColors.primary
                : AppColors.secondary);
      final tp = TextPainter(
          text: TextSpan(
              text: isMe ? '😀' : '🙂',
              style: const TextStyle(fontSize: 18)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      final nameTp = TextPainter(
          text: TextSpan(
              text: p.name,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)
        ..layout();
      nameTp.paint(
          canvas, Offset(cx - nameTp.width / 2, cy - tile));
    }

    for (final p in others) {
      drawPlayer(p, false);
    }
    drawPlayer(me, true);

    for (final b in bubbles.where((b) => b.alive)) {
      final cx = ox + b.x * tile, cy = oy + b.y * tile - tile * 1.6;
      final tp = TextPainter(
          text: TextSpan(
              text: '${b.name}: ${b.text}',
              style: const TextStyle(
                  fontSize: 11, color: Colors.white)),
          textDirection: TextDirection.ltr)
        ..layout();
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - tp.width / 2 - 6, cy - 4,
                  tp.width + 12, tp.height + 8),
              const Radius.circular(8)),
          Paint()..color = Colors.black.withValues(alpha: 0.7));
      tp.paint(canvas, Offset(cx - tp.width / 2, cy));
    }

    if (weather != null) {
      final wr = Random(7);
      for (var i = 0; i < 80; i++) {
        final px = wr.nextDouble() * size.width;
        final py = wr.nextDouble() * size.height;
        canvas.drawCircle(
            Offset(px, py),
            weather == 'rain' ? 1.2 : 2.2,
            Paint()
              ..color =
                  Colors.white.withValues(alpha: 0.5));
      }
    }

    if (night) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = Colors.indigo.withValues(alpha: 0.35));
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) => true;
}