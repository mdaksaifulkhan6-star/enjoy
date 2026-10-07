import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/game_repository.dart';

class TicTacToeScreen extends StatelessWidget {
  final String matchId, gameTitle;
  const TicTacToeScreen({super.key, required this.matchId,
      required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(title: Text('⚔️ $gameTitle — 1v1')),
      body: StreamBuilder<List<Match>>(
        stream: GameRepository.matchStream(matchId),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) return AppStates.loading();
          final m = snap.data!.first;

          if (m.status == 'open') {
            return AppStates.empty(
                title: 'প্রতিপক্ষের অপেক্ষায়…',
                subtitle: 'Link শেয়ার করলে বন্ধু join করতে পারবে',
                icon: Icons.hourglass_top);
          }

          final mySymbol = m.player1 == myId ? 'X' : 'O';
          final finished = m.status == 'finished';
          String status;
          if (finished) {
            status = m.winner == null ? '🤝 ড্র!'
                : m.winner == myId ? '🎉 আপনি জিতেছেন! (+ELO)'
                : '😢 হেরেছেন (ELO কমেছে)';
          } else {
            status = m.myTurn ? '🎯 আপনার চাল ($mySymbol)' : '⏳ প্রতিপক্ষের চাল…';
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(status, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                      itemCount: 9,
                      itemBuilder: (_, i) {
                        final cell = i < m.board.length ? m.board[i] : '';
                        return GestureDetector(
                          onTap: (finished || cell.isNotEmpty || !m.myTurn)
                              ? null
                              : () async {
                                  final res = await GameRepository
                                      .makeMove(matchId, i);
                                  if (res['ok'] != true && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text('${res['error']}')));
                                  }
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(cell,
                                  style: TextStyle(
                                      fontSize: 48, fontWeight: FontWeight.w900,
                                      color: cell == 'X'
                                          ? AppColors.primary
                                          : AppColors.secondary)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (finished)
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ফিরে যান')),
              ),
          ]);
        },
      ),
    );
  }
}