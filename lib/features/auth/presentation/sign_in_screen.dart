import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../shell/main_shell.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Internet Connection Check
      if (!await ConnectivityService.isOnline) {
        throw Exception(
            'ইন্টারনেট সংযোগ নেই। অনুগ্রহ করে চেক করে আবার চেষ্টা করুন।');
      }

      final launched = await AuthRepository.signInWithGoogle();
      if (!launched) {
        throw Exception('Google sign-in শুরু করা যায়নি');
      }

      // ⚠️ Web-এ এই লাইনে পৌঁছানোর আগেই page redirect হয়ে যাবে —
      //    ফিরে এলে SplashScreen session দেখে MainShell-এ নিয়ে যাবে।
      if (!kIsWeb) {
        await ProfileRepository.ensureMyProfile();
        await ProfileRepository.setOnlineStatus(true);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Image.asset('assets/logo/enjoy_logo.png', width: 120),
              ),
              const SizedBox(height: 28),
              Text('ENJOY-এ স্বাগতম',
                  style: textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'একটি অ্যাপ • একটি অ্যাকাউন্ট • একটি ইকোসিস্টেম',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const Spacer(flex: 2),
              if (_loading) ...[
                AppStates.loading(
                    message: kIsWeb
                        ? 'Google-এ redirect হচ্ছে…'
                        : 'সাইন ইন হচ্ছে…'),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _loading ? null : _handleGoogleSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                label: const Text('Google দিয়ে চালিয়ে যান'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('পরে করবো'),
              ),
              const SizedBox(height: 12),
              Text(
                'সাইন ইন করলে আপনি আমাদের শর্তাবলী ও গোপনীয়তা নীতিতে সম্মত হচ্ছেন',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}