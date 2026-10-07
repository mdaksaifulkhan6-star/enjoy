import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/game_repository.dart';
import 'create_game_screen.dart';
import 'tictactoe_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  Future<void> _play1v1(BuildContext context, Game g) async {
    final match = await GameRepository.quickMatch(g.id);
    if (match != null && context.mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TicTacToeScreen(
                  matchId: match.id, gameTitle: g.title)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🎮 Games')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateGameScreen())),
          icon: const Icon(Icons.add),
          label: const Text('নতুন গেম'),
        ),
        body: FutureBuilder<List<Game>>(
          future: GameRepository.list(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return AppStates.empty(
                  title: 'কোনো গেম নেই',
                  subtitle: 'Game Creator দিয়ে বানান!',
                  icon: Icons.sports_esports);
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final g = snap.data![i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundImage: g.coverUrl != null
                                  ? NetworkImage(g.coverUrl!)
                                  : null,
                              child: g.coverUrl == null
                                  ? const Icon(Icons.sports_esports)
                                  : null),
                          title: Text(g.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${g.playersMin}v${g.playersMax} • ${g.ranked ? 'Ranked ⚔️' : 'Casual'}'),
                        ),
                        Row(children: [
                          FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary),
                              onPressed: () => _play1v1(context, g),
                              icon: const Icon(Icons.sports_kabaddi),
                              label: const Text('1v1 খেলুন ⚔️')),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          _LeaderboardView(
                                              gameId: g.id,
                                              title: g.title))),
                              icon: const Icon(Icons.leaderboard),
                              label: const Text('লিডারবোর্ড')),
                        ]),
                        const SizedBox(height: 8),
                        _TournamentStrip(game: g),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class _LeaderboardView extends StatelessWidget {
  final String gameId, title;
  const _LeaderboardView({required this.gameId, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('🏆 $title — লিডারবোর্ড')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: GameRepository.leaderboard(gameId),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            if (snap.data!.isEmpty) {
              return AppStates.empty(
                  title: 'এখনো কেউ ranked খেলেনি');
            }
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final r = snap.data![i];
                final p = r['profiles'] as Map<String, dynamic>?;
                return ListTile(
                  leading: Text('#${i + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.primary)),
                  title: Text(p?['full_name'] ?? 'প্লেয়ার'),
                  subtitle: Text('${r['wins']}W / ${r['losses']}L'),
                  trailing: Text('${r['elo']} ELO',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                );
              },
            );
          },
        ),
      );
}

class _TournamentStrip extends StatelessWidget {
  final Game game;
  const _TournamentStrip({required this.game});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Tournament>>(
        future: GameRepository.tournaments(game.id),
        builder: (context, snap) {
          final ts = (snap.data ?? [])
              .where((t) => t.status == 'open')
              .toList();
          if (ts.isEmpty) return const SizedBox.shrink();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏟️ টুর্নামেন্ট',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                for (final t in ts)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events,
                        color: AppColors.accent),
                    title: Text(t.title),
                    subtitle: Text(
                        '${t.joined}/${t.maxPlayers} জন • Entry ${t.entryFeeCoins} Coin • Prize 🏆 ${t.prizeCoins} Coin'),
                    trailing: FilledButton.tonal(
                      onPressed: t.joined >= t.maxPlayers
                          ? null
                          : () async {
                              final res = await GameRepository
                                  .joinTournament(t.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(res['ok'] == true
                                            ? '✅ জয়েন হয়েছে!'
                                            : '❌ ${res['error']}')));
                              }
                            },
                      child: const Text('জয়েন'),
                    ),
                  ),
              ]);
        },
      );
}