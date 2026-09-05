import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

enum UserRole {
  viewer,
  contributor,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'contributor':
        return UserRole.contributor;
      case 'admin':
        return UserRole.admin;
      case 'viewer':
      default:
        return UserRole.viewer;
    }
  }

  String get name => toString().split('.').last;
}

enum SubscriptionTier {
  free,
  monthly,
  yearly;

  static SubscriptionTier fromString(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'monthly':
      case 'silver':
        return SubscriptionTier.monthly;
      case 'yearly':
      case 'gold':
        return SubscriptionTier.yearly;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  String get name => toString().split('.').last;
}

class UserProfile {
  final String id;
  final String? name;
  final String? matricule;
  final String? phoneNumber;
  final String? level;
  final UserRole role;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final int freeDownloadCount;
  final DateTime? upgradedAt;
  final DateTime? createdAt;
  final int aiCredits;
  final String? avatarUrl;
  final String? institutionId;
  final String? bio;
  final String? department;
  final bool trialUsed;
  final bool isTrialSubscription;
  final DateTime? aiSubscriptionExpiry;
  final int totalPoints;

  UserProfile({
    required this.id,
    this.name,
    this.matricule,
    this.phoneNumber,
    this.level,
    this.role = UserRole.viewer,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.freeDownloadCount = 0,
    this.upgradedAt,
    this.createdAt,
    this.aiCredits = 5,
    this.avatarUrl,
    this.institutionId,
    this.bio,
    this.department,
    this.trialUsed = false,
    this.isTrialSubscription = false,
    this.aiSubscriptionExpiry,
    this.totalPoints = 0,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    String? parsedName = json['name'];
    if (parsedName == null || parsedName.trim().isEmpty) {
      final user = Supabase.instance.client.auth.currentUser;
      parsedName = user?.userMetadata?['name'] ?? user?.email?.split('@').first;
    }

    return UserProfile(
      id: json['id'] ?? '',
      name: parsedName,
      matricule: json['matricule'],
      phoneNumber: json['phone_number'],
      level: json['level'],
      role: UserRole.fromString(json['role']),
      subscriptionTier: SubscriptionTier.fromString(json['subscription_tier']),
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.parse(json['subscription_expiry'])
          : null,
      freeDownloadCount: json['free_download_count'] ?? 0,
      upgradedAt: json['upgraded_at'] != null
          ? DateTime.parse(json['upgraded_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : Supabase.instance.client.auth.currentUser?.createdAt != null
          ? DateTime.parse(Supabase.instance.client.auth.currentUser!.createdAt)
          : null,
      aiCredits: json['ai_credits'] ?? 5,
      avatarUrl: json['avatar_url'],
      institutionId: json['institution_id'],
      bio: json['bio'],
      department: json['department'],
      trialUsed: json['trial_used'] ?? false,
      isTrialSubscription: json['subscription_is_trial'] ?? false,
      aiSubscriptionExpiry: json['ai_subscription_expiry'] != null
          ? DateTime.parse(json['ai_subscription_expiry'])
          : null,
      totalPoints: json['total_points'] ?? 0,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'matricule': matricule,
      'phone_number': phoneNumber,
      'level': level,
      'role': role.name,
      'subscription_tier': subscriptionTier.name,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'free_download_count': freeDownloadCount,
      'upgraded_at': upgradedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'ai_credits': aiCredits,
      'avatar_url': avatarUrl,
      'institution_id': institutionId,
      'bio': bio,
      'department': department,
      'trial_used': trialUsed,
      'subscription_is_trial': isTrialSubscription,
      'ai_subscription_expiry': aiSubscriptionExpiry?.toIso8601String(),
      'total_points': totalPoints,
    };
  }

  /// How long a brand-new account gets full access before the paywall
  /// applies, even with subscription_tier still 'free' and no trial
  /// claimed yet — enough time to discover and tap "Start Free Trial".
  /// Keep in sync with the SQL `INTERVAL '3 days'` in
  /// supabase/migrations/reconcile_paywall_with_trial_model.sql.
  static const _newAccountGraceWindow = Duration(days: 3);

  /// True while the App Plan (subscription_tier/subscription_expiry) is an
  /// active paid period or the active free trial month.
  bool get isSubscribed =>
      (subscriptionTier != SubscriptionTier.free &&
          subscriptionExpiry != null &&
          subscriptionExpiry!.isAfter(DateTime.now())) ||
      isTrialActive;

  /// True while the current App Plan period (subscription_tier/subscription_expiry)
  /// is the free trial month, rather than a paid period.
  bool get isTrialActive =>
      isTrialSubscription &&
      subscriptionExpiry != null &&
      subscriptionExpiry!.isAfter(DateTime.now());

  int get trialDaysRemaining {
    if (!isTrialActive) return 0;
    return subscriptionExpiry!.difference(DateTime.now()).inDays.clamp(0, 30);
  }

  String trialTimeLeft(AppLocalizations l10n) {
    if (!isTrialActive) return l10n.unlimitedLabel;
    final days = trialDaysRemaining;
    return days > 0 ? l10n.daysRemainingLabel(days) : l10n.endingTodayLabel;
  }

  bool get hasUnlimitedDownloads => isSubscribed;

  bool get canCreateDepartment => role == UserRole.admin; // Only admins can create departments/faculties

  bool get canUploadMaterial => true; // Everyone can help build the platform by uploading notes/study guides

  /// Central logic for the Hard Paywall: admins/contributors and active
  /// subscribers (including the active free trial) always have access; a
  /// brand-new account also has access for `_newAccountGraceWindow` so it
  /// isn't paywalled the instant it signs up.
  bool get hasAccess {
    if (role == UserRole.admin || role == UserRole.contributor) return true;
    if (isSubscribed) return true;
    if (createdAt != null && DateTime.now().difference(createdAt!) < _newAccountGraceWindow) {
      return true;
    }
    return false;
  }

  /// True while a separately-purchased Unlimited AI subscription is active.
  /// Independent of the App Plan's subscriptionTier/subscriptionExpiry, so
  /// the App Plan's free trial month never grants free AI.
  bool get hasUnlimitedAI =>
      aiSubscriptionExpiry != null && aiSubscriptionExpiry!.isAfter(DateTime.now());

  /// AI Access Logic
  bool get canUseAI {
    // Admins have unlimited access
    if (role == UserRole.admin) return true;

    // Check for an active, separately-purchased Unlimited AI subscription
    if (hasUnlimitedAI) return true;

    // Otherwise check credits
    return aiCredits > 0;
  }
}
