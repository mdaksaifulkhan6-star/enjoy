import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/borrow_repository.dart';

/// Owner-এর consent স্ক্রিন + আমার পাঠানো requests-এর status
class BorrowRequestsScreen extends StatefulWidget {
  const BorrowRequestsScreen({super.key});

  @override
  State<BorrowRequestsScreen> createState() => _BorrowRequestsScreenState();
}

class _BorrowRequestsScreenState extends State<BorrowRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 2, vsync: this);
  int _tick = 0;

  Future<void> _refresh() async => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow রিকোয়েস্ট'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'আমাকে আসা'), Tab(text: 'আমি পাঠিয়েছি'),
        ]),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RequestsList(key: ValueKey('r$_tick'), received: true, onChanged: _refresh),
          _RequestsList(key: ValueKey('s$_tick'), received: false, onChanged: _refresh),
        ],
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final bool received;
  final VoidCallback onChanged;
  const _RequestsList({super.key, required this.received, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BorrowRequestItem>>(
      future: received
          ? BorrowRepository.receivedRequests()
          : BorrowRepository.sentRequests(),
      builder: (context, snap) {
        if (!snap.hasData) return AppStates.loading();
        if (snap.data!.isEmpty) {
          return AppStates.empty(
              title: received ? 'কোনো রিকোয়েস্ট আসেনি' : 'আপনি কিছু পাঠাননি',
              icon: Icons.autorenew);
        }
        return ListView.builder(
          itemCount: snap.data!.length,
          itemBuilder: (_, i) {
            final r = snap.data![i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    r.contentType == 'profile' ? Icons.person : Icons.video_library,
                    color: AppColors.primary),
                ),
                title: Text(
                    '${r.contentType.toUpperCase()} • ${_statusBn(r.status)}'),
                subtitle: Text(
                    '${r.costType == 'free' ? 'Free' : r.costType == 'vip' ? 'VIP' : '${r.coinsSpent} Coin'} • '
                    '${r.createdAt?.toLocal().toString().substring(0, 16) ?? ''}'),
                trailing: received && r.isPending
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: AppColors.online, size: 30),
                          onPressed: () async {
                            await BorrowRepository.respond(r.id, true);
                            onChanged();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 28),
                          onPressed: () async {
                            await BorrowRepository.respond(r.id, false);
                            onChanged();
                          },
                        ),
                      ])
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  String _statusBn(String s) => {
        'pending': '⏳ Consent অপেক্ষায়',
        'active': '✅ চলমান (৭ দিন)',
        'returned': '📤 ফেরত দেওয়া',
        'rejected': '❌ বাতিল',
        'revoked': '🚫 প্রত্যাহার',
      }[s] ?? s;
}