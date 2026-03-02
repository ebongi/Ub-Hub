import 'package:supabase_flutter/supabase_flutter.dart';

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
  silver,
  gold;

  static SubscriptionTier fromString(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'silver':
        return SubscriptionTier.silver;
      case 'gold':
        return SubscriptionTier.gold;
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
  final String? avatarUrl;

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
    this.avatarUrl,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'],
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
      avatarUrl: json['avatar_url'],
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
      'avatar_url': avatarUrl,
    };
  }

  bool get isSubscribed =>
      subscriptionTier != SubscriptionTier.free &&
      (subscriptionExpiry == null ||
          subscriptionExpiry!.isAfter(DateTime.now()));

  bool get isTrialActive {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inDays < 10;
  }

  int get trialDaysRemaining {
    if (createdAt == null) return 0;
    final diff = 10 - DateTime.now().difference(createdAt!).inDays;
    return diff.clamp(0, 10);
  }

  String get trialTimeLeft {
    if (createdAt == null) return "Expired";
    final expiryDate = createdAt!.add(const Duration(days: 10));
    final remaining = expiryDate.difference(DateTime.now());

    if (remaining.isNegative) return "Expired";

    if (remaining.inDays > 0) {
      return "${remaining.inDays}d ${remaining.inHours % 24}h remaining";
    } else {
      return "${remaining.inHours}h ${remaining.inMinutes % 60}m remaining";
    }
  }

  bool get hasUnlimitedDownloads =>
      role == UserRole.contributor ||
      role == UserRole.admin ||
      subscriptionTier == SubscriptionTier.gold ||
      isTrialActive;

  bool get canCreateDepartment =>
      role == UserRole.contributor || role == UserRole.admin;

  bool get canUploadMaterial =>
      role == UserRole.contributor || role == UserRole.admin || isTrialActive;
}
