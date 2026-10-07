import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';

/// Supabase Auth + Google OAuth + Session Management.
///
/// 🌐 Web: Supabase-hosted OAuth redirect (Flutter Web-এর জন্য recommended) —
///    পেজ Google-এ redirect হয়ে আবার অ্যাপে ফিরে আসে, session auto-restore হয়।
/// 📱 Android/iOS: native google_sign_in plugin।
class AuthRepository {
  AuthRepository._();

  static final _client = Supabase.instance.client;
  static final GoogleSignIn _google = GoogleSignIn.instance;

  static Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  /// Google দিয়ে সাইন ইন (Sign In/Sign Up একই flow)।
  /// Web-এ true return করার পরপরই page redirect হয়ে যাবে।
  static Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: browser পুরোপুরি redirect হবে, ফিরে এলে Splash session ধরবে
      return _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin, // বর্তমান Codespaces URL
      );
    }
    return _signInWithGoogleNative();
  }

  /// Android/iOS: native Google Sign-In (আগের মতোই)
  static Future<bool> _signInWithGoogleNative() async {
    final webClientId = AppConfig.googleWebClientId;
    if (webClientId.isEmpty) {
      throw Exception('GOOGLE_WEB_CLIENT_ID .env ফাইলে সেট নেই!');
    }

    await _google.initialize(serverClientId: webClientId);

    final GoogleSignInAccount googleUser = await _google.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google ID token পাওয়া যায়নি');
    }

    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    if (res.user == null) throw const AuthException('Sign-in ব্যর্থ');
    return true;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
    if (!kIsWeb) await _google.signOut();
  }
}