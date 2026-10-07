import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central, secure configuration.
/// All secrets come from .env — nothing hardcoded.
class AppConfig {
  AppConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  static const String appName = 'ENJOY';
  static const String privacyUrl = 'https://your-domain.com/privacy';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}