import 'package:supabase_flutter/supabase_flutter.dart';

class AdCampaign {
  final String id, title, creativeUrl;
  final String? ctaUrl;
  const AdCampaign({required this.id, required this.title,
      required this.creativeUrl, this.ctaUrl});
  factory AdCampaign.fromMap(Map<String, dynamic> m) => AdCampaign(
        id: m['id'], title: m['title'],
        creativeUrl: m['creative_url'], ctaUrl: m['cta_url'],
      );
}

class AdsRepository {
  AdsRepository._();
  static final _db = Supabase.instance.client;

  /// Active campaign serve (budget থাকা যেকোনো একটা)
  static Future<AdCampaign?> getAd() async {
    final rows = await _db.rpc('get_borrow_ad');
    final list = rows as List;
    if (list.isEmpty) return null;
    return AdCampaign.fromMap(Map<String, dynamic>.from(list.first));
  }

  /// impression/complete track — server-এ revenue auto-calc হয়
  static Future<void> track(String campaignId, String event) async {
    await _db.rpc('track_ad_event',
        params: {'p_campaign_id': campaignId, 'p_event': event});
  }
}