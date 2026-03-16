import 'package:go_study/services/profile.dart';

class SubscriptionService {
  static const double silverPrice = 1000.0;
  static const double goldPrice = 2500.0;
  static const double contributorPrice = 5000.0;

  static const int freeTierDownloadLimit = 5;

  static String getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.silver:
        return "Silver";
      case SubscriptionTier.gold:
        return "Gold";
      case SubscriptionTier.free:
        return "Free";
    }
  }

  static double getTierPrice(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.silver:
        return silverPrice;
      case SubscriptionTier.gold:
        return goldPrice;
      case SubscriptionTier.free:
        return 0.0;
    }
  }

  static List<String> getTierFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.gold:
        return [
          "Unlimited Downloads",
          "Unlimited AI Study Plans",
          "Priority Support",
          "No Ads (Future)",
        ];
      case SubscriptionTier.silver:
        return [
          "Unlimited Downloads",
          "Duration: 2 Weeks",
          "5 AI Study Plans / Week",
          "Priority Support",
        ];
      case SubscriptionTier.free:
        return [
          "5 Free Downloads",
          "Pay per Item (150-300 XAF) after limit",
          "1 AI Study Plan / Week",
          "Standard Support",
        ];
    }
  }

  static bool canDownloadForFree(UserProfile profile) {
    if (profile.hasUnlimitedDownloads || profile.isTrialActive) return true;
    if (profile.subscriptionTier == SubscriptionTier.silver &&
        profile.isSubscribed) {
      return true;
    }
    // Any user who is not subscribed (Free or expired) gets the 5 free downloads
    if (profile.freeDownloadCount < freeTierDownloadLimit) {
      return true;
    }
    return false;
  }

  static int getRemainingDownloads(UserProfile profile) {
    if (profile.hasUnlimitedDownloads || profile.isTrialActive) {
      return -1; // Unlimited
    }
    if (profile.subscriptionTier == SubscriptionTier.silver &&
        profile.isSubscribed) {
      return -1; // Unlimited
    }

    // Any user not subscribed gets the 5 free downloads limit
    return (freeTierDownloadLimit - profile.freeDownloadCount).clamp(
      0,
      freeTierDownloadLimit,
    );
  }
}
