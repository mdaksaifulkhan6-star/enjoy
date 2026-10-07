// ── presentation/admin_panel_screen.dart ──
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_repository.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: AdminRepository.isAdmin(),
        builder: (context, adminSnap) {
          if (!adminSnap.hasData) return AppStates.loading();
          if (adminSnap.data != true) {
            return AppStates.empty(
                title: '⛔ Access Denied',
                subtitle: 'এই স্ক্রিন শুধু Admin-দের জন্য',
                icon: Icons.security);
          }
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Admin Panel 🛡️'),
                bottom: const TabBar(tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Payouts'),
                  Tab(text: 'Fraud / Reports'),
                ]),
              ),
              body: TabBarView(children: [
                _OverviewTab(),
                _PayoutsTab(),
                _FraudTab(),
              ]),
            ),
          );
        },
      );
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
        future: AdminRepository.overview(),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          final d = snap.data!;
          final items = [
            ('👥 Users', d['users']),
            ('🎬 Videos', d['videos']),
            ('🔄 Borrows Today', d['borrows_today']),
            ('🪙 Coin Revenue (৳)', d['coin_revenue_bdt']),
            ('🌟 VIP Revenue (৳)', d['vip_revenue_bdt']),
            ('🔄 Borrow Revenue (৳)', d['borrow_revenue_bdt']),
            ('📺 Ad Revenue (৳)', d['ad_revenue_bdt']),
            ('⏳ Pending Payouts', d['pending_payouts']),
            ('🎁 Pending Cashouts', d['pending_cashouts']),
            ('🚨 Open Fraud', d['open_fraud']),
            ('🚩 Open Reports', d['open_reports']),
          ];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: items.length,
            itemBuilder: (_, i) => Card(
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text('${items[i].$2}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                Text(items[i].$1, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12)),
              ]),
            ),
          );
        },
      );
}

class _PayoutsTab extends StatefulWidget {
  @override
  State<_PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends State<_PayoutsTab> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) => ListView(
        key: ValueKey(_tick),
        padding: const EdgeInsets.all(12),
        children: [
          const Text('🎁 Reward Cash-Outs (pending)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminRepository.pendingCashouts(),
            builder: (context, s) => Column(children: [
              for (final c in s.data ?? [])
                Card(child: ListTile(
                  title: Text(
                      '${c['profiles']?['full_name'] ?? ''} — ৳${c['amount_bdt']}'),
                  subtitle: Text(
                      '${c['points']} pts • ${c['method']} • ${c['account_number']}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: AppColors.online),
                        onPressed: () async {
                          await AdminRepository.processCashout(
                              c['id'] as String, true);
                          setState(() => _tick++);
                        }),
                    IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await AdminRepository.processCashout(
                              c['id'] as String, false);
                          setState(() => _tick++);
                        }),
                  ]),
                )),
              if ((s.data ?? []).isEmpty)
                const Padding(padding: EdgeInsets.all(8),
                    child: Text('কিছু pending নেই')),
            ]),
          ),
          const Divider(height: 32),
          const Text('🏦 Creator Payouts (requested)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminRepository.pendingPayouts(),
            builder: (context, s) => Column(children: [
              for (final p in s.data ?? [])
                Card(child: ListTile(
                  title: Text(
                      '${p['profiles']?['full_name'] ?? ''} — ৳${p['amount_bdt']}'),
                  subtitle: Text('${p['method']} • ${p['account_number']}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: AppColors.online),
                      onPressed: () async {
                        await AdminRepository.processPayout(
                            p['id'] as String, true);
                        setState(() => _tick++);
                      }),
                )),
              if ((s.data ?? []).isEmpty)
                const Padding(padding: EdgeInsets.all(8),
                    child: Text('কিছু pending নেই')),
            ]),
          ),
        ],
      );
}

class _FraudTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12),
        children: [
          const Text('🚨 Fraud Signals',
              style: TextStyle(fontWeight: FontWeight.w800)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminRepository.fraudSignals(),
            builder: (context, s) => Column(children: [
              for (final f in s.data ?? [])
                Card(child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('${f['signal_type']}'),
                  subtitle: Text(
                      '${f['profiles']?['full_name'] ?? ''} • ${f['details']}'),
                )),
              if ((s.data ?? []).isEmpty)
                const Padding(padding: EdgeInsets.all(8),
                    child: Text('কোনো open fraud নেই ✅')),
            ]),
          ),
          const Divider(height: 32),
          const Text('🚩 Open Reports',
              style: TextStyle(fontWeight: FontWeight.w800)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminRepository.openReports(),
            builder: (context, s) => Column(children: [
              for (final r in s.data ?? [])
                Card(child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('${r['target_type']} — ${r['reason']}'),
                  subtitle: Text('${r['details'] ?? ''}'),
                )),
              if ((s.data ?? []).isEmpty)
                const Padding(padding: EdgeInsets.all(8),
                    child: Text('কোনো open report নেই ✅')),
            ]),
          ),
        ],
      );
}