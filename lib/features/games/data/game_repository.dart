import 'package:supabase_flutter/supabase_flutter.dart';

class Game {
  final String id, creatorId, title;
  final String? description, coverUrl, url, engine;
  final int playersMin, playersMax;
  final bool ranked;
  const Game({required this.id, required this.creatorId, required this.title,
      this.description, this.coverUrl, this.url, this.engine,
      this.playersMin = 1, this.playersMax = 1, this.ranked = true});
  factory Game.fromMap(Map<String, dynamic> m) => Game(
      id: m['id'], creatorId: m['creator_id'], title: m['title'],
      description: m['description'], coverUrl: m['cover_url'], url: m['url'],
      engine: m['engine'], playersMin: m['players_min'] ?? 1,
      playersMax: m['players_max'] ?? 1, ranked: m['ranked'] ?? true);
}

class Tournament {
  final String id, gameId, title, status;
  final DateTime startsAt;
  final int entryFeeCoins, prizeCoins, maxPlayers, joined;
  const Tournament({required this.id, required this.gameId, required this.title,
      required this.status, required this.startsAt, this.entryFeeCoins = 0,
      this.prizeCoins = 0, this.maxPlayers = 16, this.joined = 0});
  factory Tournament.fromMap(Map<String, dynamic> m) => Tournament(
      id: m['id'], gameId: m['game_id'], title: m['title'],
      status: m['status'], startsAt: DateTime.parse(m['starts_at']),
      entryFeeCoins: m['entry_fee_coins'] ?? 0,
      prizeCoins: m['prize_coins'] ?? 0, maxPlayers: m['max_players'] ?? 16,
      joined: (m['tournament_participants'] as List?)?.length ?? 0);
}

class Match {
  final String id, gameId, player1, status;
  final String? player2, winner, turn;
  final List<String> board;
  const Match({required this.id, required this.gameId, required this.player1,
      required this.status, this.player2, this.winner, this.turn,
      this.board = const []});
  factory Match.fromMap(Map<String, dynamic> m) => Match(
      id: m['id'], gameId: m['game_id'], player1: m['player1'],
      player2: m['player2'], status: m['status'], winner: m['winner'],
      turn: m['turn'],
      board: (m['board'] as List).map((e) => e.toString()).toList());
  bool get myTurn =>
      turn == Supabase.instance.client.auth.currentUser?.id;
}

class GameRepository {
  GameRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static Future<List<Game>> list() async {
    final rows = await _db.from('games').select()
        .eq('status', 'published').order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Game.fromMap(r as Map<String, dynamic>)).toList();
  }

  static Future<List<Tournament>> tournaments(String gameId) async {
    final rows = await _db.from('tournaments')
        .select('*, tournament_participants(user_id)')
        .eq('game_id', gameId).order('starts_at', ascending: false);
    return (rows as List)
        .map((r) => Tournament.fromMap(r as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> joinTournament(String id) async {
    final res = await _db.rpc('join_tournament',
        params: {'p_tournament_id': id});
    return Map<String, dynamic>.from(res);
  }

  static Future<List<Map<String, dynamic>>> leaderboard(String gameId) async {
    final rows = await _db.from('game_leaderboard')
        .select('elo, wins, losses, profiles(full_name, avatar_url)')
        .eq('game_id', gameId).order('elo', ascending: false).limit(50);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── 1v1 Matchmaking ──
  static Future<Match> createMatch(String gameId) async {
    final row = await _db.from('matches').insert({
      'game_id': gameId, 'player1': _myId,
    }).select().single();
    return Match.fromMap(row);
  }

  /// ওপেন ম্যাচ খুঁজে ঢোকা (auto-match)
  static Future<Match?> quickMatch(String gameId) async {
    final open = await _db.from('matches').select()
        .eq('game_id', gameId).eq('status', 'open')
        .neq('player1', _myId).limit(1).maybeSingle();
    if (open != null) {
      final res = await _db.rpc('join_match',
          params: {'p_match_id': open['id']});
      if (res['ok'] == true) {
        final row = await _db.from('matches')
            .select().eq('id', open['id']).single();
        return Match.fromMap(row);
      }
    }
    return createMatch(gameId);
  }

  static Stream<List<Match>> matchStream(String matchId) =>
      _db.from('matches').stream(primaryKey: ['id'])
          .eq('id', matchId).map((r) => r.map(Match.fromMap).toList());

  static Future<Map<String, dynamic>> makeMove(
          String matchId, int index) async {
    final res = await _db.rpc('make_move',
        params: {'p_match_id': matchId, 'p_index': index});
    return Map<String, dynamic>.from(res);
  }

  // ── Game Creator ──
  static Future<Game> createGame(String title,
      {String? description, int playersMax = 2, bool ranked = true}) async {
    final row = await _db.from('games').insert({
      'creator_id': _myId, 'title': title, 'description': description,
      'players_max': playersMax, 'ranked': ranked,
    }).select().single();
    return Game.fromMap(row);
  }
}