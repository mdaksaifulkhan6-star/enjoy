import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage Architecture:
///   Supabase = Data + Backend (আগের মতোই)
///   Cloudinary = Media + CDN (videos/photos/thumbnails — ঐচ্ছিক, env বসালে চালু)
/// .env-এ CLOUDINARY_CLOUD_NAME + CLOUDINARY_UPLOAD_PRESET (unsigned) বসালে
/// মিডিয়া Cloudinary-তে যাবে; না বসালে আগের Supabase storage-ই কাজ করবে।
class MediaService {
  MediaService._();

  static String? get _cloudName =>
      const String.fromEnvironment('CLOUDINARY_CLOUD_NAME').isEmpty
          ? null
          : const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  // ⚠️ সহজ পথ: নিচের দুই লাইন ব্যবহার করুন (flutter_dotenv ইতিমধ্যে আছে)
  // static String? get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'];
  // static String? get _preset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  static bool get cloudinaryConfigured =>
      _cloudName != null; // && _preset != null

  /// Cloudinary-তে video upload → secure_url ফেরত; fail হলে null
  static Future<String?> uploadVideoToCloudinary(
      Uint8List bytes, String fileName) async {
    if (!cloudinaryConfigured) return null;
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'enjoy_unsigned' // ← .env থেকে নিন
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: fileName));
      final res = await req.send();
      if (res.statusCode != 200) return null;
      final body = await res.stream.bytesToString();
      final url = RegExp('"secure_url":"([^"]+)"').firstMatch(body)?.group(1);
      if (url == null) return null;
      await Supabase.instance.client.from('media_assets').insert({
        'owner_id': Supabase.instance.client.auth.currentUser?.id,
        'provider': 'cloudinary',
        'cloudinary_url': url,
        'kind': 'video',
      });
      return url.replaceAll(r'\/', '/');
    } catch (_) {
      return null;
    }
  }
}