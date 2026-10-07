import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/widgets/state_views.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Supabase.instance.client;
    final myId = db.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(title: const Text('নোটিফিকেশন')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.from('notifications').stream(primaryKey: ['id'])
            .eq('user_id', myId).order('created_at').map((r) => r.reversed.toList()),
        builder: (context, snap) {
          if (!snap.hasData) return AppStates.loading();
          if (snap.data!.isEmpty) {
            return AppStates.empty(
                title: 'কোনো নোটিফিকেশন নেই',
                icon: Icons.notifications_none);
          }
          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final n = snap.data![i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.favorite, size: 18)),
                title: Text({
                  'like': 'আপনার পোস্টে লাইক দিয়েছে',
                  'comment': 'কমেন্ট করেছে: ${n['message'] ?? ''}',
                  'fnf_request': 'FNF রিকোয়েস্ট পাঠিয়েছে',
                  'message': 'মেসেজ: ${n['message'] ?? ''}',
                  'borrow_request': 'আপনার কনটেন্ট Borrow চেয়েছে 🔄',
                  'borrow_accepted': 'Borrow রিকোয়েস্ট গৃহীত হয়েছে ✅',
                  'borrow_rejected': 'Borrow রিকোয়েস্ট বাতিল ❌',
                }[n['type']] ?? n['type']),
                subtitle: Text(timeago.format(DateTime.parse(n['created_at']))),
                tileColor: n['is_read'] ? null : Colors.pink.withValues(alpha: 0.05),
                onTap: () => db.from('notifications')
                    .update({'is_read': true}).eq('id', n['id']),
              );
            },
          );
        },
      ),
    );
  }
}