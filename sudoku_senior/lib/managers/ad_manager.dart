import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  // Singleton instance
  static final AdManager instance = AdManager._internal();
  factory AdManager() => instance;

  // IDs de producción (Android) / prueba (iOS)
  static String get bannerId => Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/6472689369'
      : 'ca-app-pub-3940256099942544/2934735716';
  static final String _interstitialId = Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/4856355362'
      : 'ca-app-pub-3940256099942544/4411468910';
  static final String _rewardedId = Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/4688834407'
      : 'ca-app-pub-3940256099942544/1712485313';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;

  AdManager._internal() {
    loadInterstitial();
    loadRewarded();
  }

  void loadInterstitial() {
    if (_isInterstitialReady || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialReady = false;
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  void showInterstitial(Function onAdClosed) {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          loadInterstitial();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          loadInterstitial();
          onAdClosed();
        },
      );
      _interstitialAd!.show();
      _isInterstitialReady = false;
    } else {
      onAdClosed();
      loadInterstitial();
    }
  }

  void loadRewarded() {
    if (_isRewardedReady || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _isRewardedReady = true;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _isRewardedReady = false;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  void showRewarded(Function onUserEarnedReward, {Function? onAdFailed}) {
    if (_isRewardedReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedReady = false;
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedReady = false;
          loadRewarded();
          if (onAdFailed != null) onAdFailed();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
        },
      );
      _isRewardedReady = false;
    } else {
      loadRewarded();
      if (onAdFailed != null) onAdFailed();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
    _isLoadingInterstitial = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedReady = false;
    _isLoadingRewarded = false;
  }

  static BannerAd createBanner() {
    return BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}
