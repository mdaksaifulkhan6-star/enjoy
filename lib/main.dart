import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/error_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Secure configuration (.env file — never hardcoded)
  await dotenv.load(fileName: '.env');

  // Supabase Initialization
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // App Doctor — Error Intelligence
  ErrorReporter.init();

  runApp(const EnjoyApp());
}