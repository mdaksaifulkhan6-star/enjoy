import 'package:supabase_flutter/supabase_flutter.dart';

class Course {
  final String id, creatorId, title;
  final String? description, thumbnailUrl, category, creatorName;
  final double priceBdt;
  final double? rating;
  final int? reviewCount;
  const Course({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.category,
    this.creatorName,
    this.priceBdt = 0,
    this.rating,
    this.reviewCount,
  });
  factory Course.fromMap(Map<String, dynamic> m) {
    final p = m['profiles'] as Map<String, dynamic>?;
    final rv = m['reviews'] as List? ?? [];
    final ratings = rv.isNotEmpty
        ? rv.map((r) => (r['rating'] as num).toDouble()).toList()
        : <double>[];
    return Course(
      id: m['id'],
      creatorId: m['creator_id'],
      title: m['title'],
      description: m['description'],
      thumbnailUrl: m['thumbnail_url'],
      category: m['category'],
      creatorName: p?['full_name'],
      priceBdt: (m['price_bdt'] as num?)?.toDouble() ?? 0,
      rating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      reviewCount: rv.length,
    );
  }
}

class Lesson {
  final String id, courseId, title;
  final String? videoUrl;
  final int position, durationSeconds;
  final bool isFreePreview, completed;
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.videoUrl,
    this.position = 0,
    this.durationSeconds = 0,
    this.isFreePreview = false,
    this.completed = false,
  });
  factory Lesson.fromMap(Map<String, dynamic> m) => Lesson(
      id: m['id'],
      courseId: m['course_id'],
      title: m['title'],
      videoUrl: m['video_url'],
      position: m['position'] ?? 0,
      durationSeconds: m['duration_seconds'] ?? 0,
      isFreePreview: m['is_free_preview'] ?? false);
}

class Certificate {
  final String id, courseId, serial;
  final String? courseTitle;
  final DateTime issuedAt;
  const Certificate({
    required this.id,
    required this.courseId,
    required this.serial,
    this.courseTitle,
    required this.issuedAt,
  });
  factory Certificate.fromMap(Map<String, dynamic> m) => Certificate(
      id: m['id'],
      courseId: m['course_id'],
      serial: m['serial'],
      courseTitle: m['courses']?['title'],
      issuedAt: DateTime.parse(m['issued_at']));
}

class CourseRepository {
  CourseRepository._();
  static final _db = Supabase.instance.client;
  static String get _myId => _db.auth.currentUser!.id;

  static Future<List<Course>> list() async {
    final rows = await _db.from('courses').select(
        '*, profiles(full_name), reviews(rating)').eq('is_published', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Course.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Lesson>> lessons(String courseId) async {
    final rows = await _db
        .from('lessons')
        .select('*, lesson_progress!left(user_id)')
        .eq('course_id', courseId)
        .order('position');
    return (rows as List).map((r) {
      final l = Lesson.fromMap(r as Map<String, dynamic>);
      return Lesson(
        id: l.id,
        courseId: l.courseId,
        title: l.title,
        videoUrl: l.videoUrl,
        position: l.position,
        durationSeconds: l.durationSeconds,
        isFreePreview: l.isFreePreview,
        completed: (r['lesson_progress'] as List?)
                ?.any((x) => x['user_id'] == _myId) ??
            false,
      );
    }).toList();
  }

  static Future<bool> isEnrolled(String courseId) async {
    final row = await _db
        .from('enrollments')
        .select()
        .eq('course_id', courseId)
        .eq('user_id', _myId)
        .maybeSingle();
    return row != null;
  }

  static Future<void> enroll(String courseId) async => _db
      .from('enrollments')
      .insert({'course_id': courseId, 'user_id': _myId});

  static Future<Map<String, dynamic>> completeLesson(
      String lessonId) async {
    final res =
        await _db.rpc('complete_lesson', params: {'p_lesson_id': lessonId});
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Certificate>> myCertificates() async {
    final rows = await _db
        .from('certificates')
        .select('*, courses(title)')
        .eq('user_id', _myId)
        .order('issued_at', ascending: false);
    return (rows as List)
        .map((r) => Certificate.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Learning History (my_learning_history view)
  static Future<List<Map<String, dynamic>>> myLearningHistory() async {
    final rows = await _db.from('my_learning_history').select();
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<void> review(
          String courseId, int rating, String text) async =>
      _db.from('reviews').upsert({
        'course_id': courseId,
        'user_id': _myId,
        'rating': rating,
        'text': text,
      });
}