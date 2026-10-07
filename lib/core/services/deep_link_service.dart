import 'dart:async';
import 'package:app_links/app_links.dart';

/// Deep Link Foundation — Phase 01.
/// Handles app:// and https:// links; routing added in later phases.
class DeepLinkService {
  DeepLinkService._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  /// Called once after login. [onLink] receives parsed Uri.
  static void start(void Function(Uri uri) onLink) {
    _sub ??= _appLinks.uriLinkStream.listen((uri) => onLink(uri));
  }

  static Future<Uri?> get initialLink => _appLinks.getInitialLink();

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}