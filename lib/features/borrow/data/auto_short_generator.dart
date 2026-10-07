import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Borrowed content থেকে 9:16 vertical auto short (৩০ সেকেন্ড)
class AutoShortGenerator {
  AutoShortGenerator._();

  static Future<String?> generateFromUrl(String videoUrl, String contentId) async {
    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final src = '${tmp.path}/borrow_src_$ts.mp4';
    final out = '${tmp.path}/borrow_short_$ts.mp4';

    // ১. Download (FFmpeg সরাসরি URL-ও পারে, কিন্তু download নির্ভরযোগ্য)
    await Dio().download(videoUrl, src);

    // ২. 9:16 center-crop + 30s trim + 1080x1920
    final cmd =
        '-i "$src" -t 30 '
        '-vf "crop=ih*9/16:ih,scale=1080:1920,setsar=1" '
        '-c:v libx264 -preset veryfast -crf 26 -c:a aac -shortest "$out"';

    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();

    try { await File(src).delete(); } catch (_) {}

    if (ReturnCode.isSuccess(rc) && await File(out).exists()) {
      return out;
    }
    return null;
  }
}