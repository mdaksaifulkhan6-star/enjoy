import '../../video/data/video_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShortsRepository {
  ShortsRepository._();
  static final _db = Supabase.instance.client;

  /// Vertical swipe feed — realtime shorts stream
  static Stream<List<Video>> shortsFeed() {
    return _db.from('videos').stream(primaryKey: ['id'])
        .eq('is_short', true).eq('privacy', 'public').eq('status', 'published')
        .order('created_at')
        .map((r) => r.map(Video.fromMap).toList().reversed.toList());
  }
}