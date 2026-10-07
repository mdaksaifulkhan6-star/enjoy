import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google AdMob — Banner / Interstitial / Rewarded / Rewarded Interstitial /
/// App Open / Native (Web-এ auto-skip; শুধু Android/iOS-এ কাজ করে)
/// ⚠️ এখন Google TEST Unit ID; production-এ নিজের ID বসান।
/// Frequency + placement = ad_settings টেবিল থেকে (Admin control)
class AdmobService {
  AdmobService._();

  static const _bannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _interId = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _rewardedInterId = 'ca-app-pub-3940256099942544/5354046379';
  static const _appOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const _nativeId = 'ca-app-pub-3940256099942544/2247696110';

  static BannerAd? banner;
  static NativeAd? nativeAd;
  static DateTime? _lastInterstitial;
  static bool _appOpenShown = false;
  static final Map<String, dynamic> _settings = {
    'banner': {'enabled': true},
    'interstitial': {'enabled': true, 'min_minutes': 5},
    'rewarded': {'enabled': true, 'coins': 10, 'max_per_day': 5},
    'app_open': {'enabled': true},
    'native': {'enabled': false},
  };

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_supported) return;
    // ⚠️ UMP/GDPR consent: production-এ আলাদা consent flow যোগ করবেন
    // (google_mobile_ads ভার্সনভেদে API আলাদা — compile নিরাপত্তার জন্য এখন বাদ)
    await MobileAds.instance.initialize();
    await _loadSettings();
    _loadBanner();
    _loadNative();
    _loadAppOpen();
  }

  static Future<void> _loadSettings() async {
    try {
      final rows =
          await Supabase.instance.client.from('ad_settings').select();
      for (final r in (rows as List)) {
        _settings[r['key'] as String] =
            Map<String, dynamic>.from(r['value'] as Map);
      }
    } catch (_) {}
  }

  static bool _enabled(String key) =>
      (_settings[key]?['enabled'] as bool?) ?? false;

  // ── Banner ──
  static void _loadBanner() {
    if (!_enabled('banner')) return;
    banner = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(),
    )..load();
  }

  static Widget? bannerWidget() {
    final b = banner;
    if (!_supported || b == null) return null;
    return SizedBox(height: 50, child: AdWidget(ad: b));
  }

  // ── Native ──
  static void _loadNative() {
    if (!_enabled('native')) return;
    nativeAd = NativeAd(
      adUnitId: _nativeId,
      listener: NativeAdListener(),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
      ),
    )..load();
  }

  static Widget? nativeWidget() {
    final n = nativeAd;
    if (!_supported || n == null) return null;
    return SizedBox(height: 100, child: AdWidget(ad: n));
  }

  // ── Interstitial (frequency controlled) ──
  static Future<void> maybeShowInterstitial() async {
    if (!_supported || !_enabled('interstitial')) return;
    final minMin =
        (_settings['interstitial']?['min_minutes'] as num?)?.toInt() ?? 5;
    if (_lastInterstitial != null &&
        DateTime.now().difference(_lastInterstitial!).inMinutes < minMin) {
      return;
    }
    await InterstitialAd.load(
      adUnitId: _interId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _lastInterstitial = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose());
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  // ── Rewarded → coin credit (backend-verified) ──
  static Future<bool> showRewardedForCoins() async {
    if (!_supported) return false;
    if (!_enabled('rewarded')) return false;
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose());
          ad.show(onUserEarnedReward: (_, __) async {
            try {
              final res =
                  await Supabase.instance.client.rpc('credit_ad_reward');
              completer.complete(
                  Map<String, dynamic>.from(res as Map)['ok'] == true);
            } catch (_) {
              completer.complete(false);
            }
          });
        },
        onAdFailedToLoad: (_) => completer.complete(false),
      ),
    );
    return completer.future;
  }

  // ── Rewarded Interstitial ──
  static Future<void> showRewardedInterstitial() async {
    if (!_supported) return;
    await RewardedInterstitialAd.load(
      adUnitId: _rewardedInterId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose());
          ad.show(onUserEarnedReward: (_, __) {});
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  // ── App Open (cold start-এ একবার) ──
  static void _loadAppOpen() {
    if (!_enabled('app_open')) return;
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (_appOpenShown) {
            ad.dispose();
            return;
          }
          _appOpenShown = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose());
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }
}