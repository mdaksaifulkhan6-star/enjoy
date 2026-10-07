import 'package:flutter/foundation.dart';
import '../../features/ai/data/ai_service.dart';

/// App Doctor: পুরো অ্যাপের error global catch → Supabase Intelligence
class ErrorReporter {
  ErrorReporter._();

  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AiService.reportError(
        'flutter',
        details.exceptionAsString(),
        details.stack?.toString(),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AiService.reportError('platform', error.toString(), stack.toString());
      return true;
    };
  }
}