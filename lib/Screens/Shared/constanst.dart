import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/core/responsive.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

// Custom widget for image customization
Widget buildImage({String? path}) {
  return Center(
    child: Image.asset(
      path.toString(),
      width: 400,
      height: 300,
      fit: BoxFit.fitWidth,
    ),
  );
}

// custom Scrolldecoration
PageDecoration pageDecoration() {
  return PageDecoration(
    titleTextStyle: TextStyle(fontSize: 35, color: Colors.black),
    bodyTextStyle: TextStyle(fontSize: 20, color: Colors.grey[600]),
    bodyPadding: EdgeInsets.all(16),
    pageColor: Colors.white,
    imagePadding: EdgeInsets.all(2),
  );
}

class UserModel extends ChangeNotifier {
  String? _uid;
  String? _name;
  String? _email;
  String? _matricule;
  String? _phonenumber;
  String? _avatarUrl;
  String? _institutionId;
  String? _institutionName;
  String? _bio;
  String? _department;
  String? _level;
  UserRole _role;
  SubscriptionTier _subscriptionTier;
  DateTime? _subscriptionExpiry;
  int _freeDownloadCount;
  int _aiCredits;
  DateTime? _createdAt;
  bool _trialUsed;
  bool _isTrialSubscription;
  DateTime? _aiSubscriptionExpiry;
  int _totalPoints;

  // Offline-start support: see tryUseCachedProfile/persistCache below.
  final SharedPreferences? _prefs;
  String? _cachedUid;
  static const _cacheKey = 'cached_user_profile_v1';

  UserModel({
    String? uid,
    String? name,
    String? email,
    String? matricule,
    String? phonenumber,
    String? avatarUrl,
    String? institutionId,
    String? institutionName,
    String? bio,
    String? department,
    String? level,
    UserRole role = UserRole.viewer,
    SubscriptionTier subscriptionTier = SubscriptionTier.free,
    DateTime? subscriptionExpiry,
    int freeDownloadCount = 0,
    int aiCredits = 5,
    DateTime? createdAt,
    bool trialUsed = false,
    bool isTrialSubscription = false,
    DateTime? aiSubscriptionExpiry,
    int totalPoints = 0,
    SharedPreferences? prefs,
  }) : _uid = uid,
       _name = name,
       _email = email,
       _matricule = matricule,
       _phonenumber = phonenumber,
       _avatarUrl = avatarUrl,
       _institutionId = institutionId,
       _institutionName = institutionName,
       _bio = bio,
       _department = department,
       _level = level,
       _role = role,
       _subscriptionTier = subscriptionTier,
       _subscriptionExpiry = subscriptionExpiry,
       _freeDownloadCount = freeDownloadCount,
       _aiCredits = aiCredits,
       _createdAt = createdAt,
       _trialUsed = trialUsed,
       _isTrialSubscription = isTrialSubscription,
       _aiSubscriptionExpiry = aiSubscriptionExpiry,
       _totalPoints = totalPoints,
       _prefs = prefs {
    if (prefs != null) _hydrateFromCache();
  }
  // Gettters
  String? get uid => _uid;
  String? get name => _name;
  String? get email => _email;
  String? get matricule => _matricule;
  String? get phoneNumber => _phonenumber;
  String? get avatarUrl => _avatarUrl;
  String? get institutionId => _institutionId;
  String? get institutionName => _institutionName;
  String? get bio => _bio;
  String? get department => _department;
  String? get level => _level;
  UserRole get role => _role;
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  int get freeDownloadCount => _freeDownloadCount;
  int get aiCredits => _aiCredits;
  DateTime? get createdAt => _createdAt;
  bool get trialUsed => _trialUsed;
  bool get isTrialSubscription => _isTrialSubscription;
  DateTime? get aiSubscriptionExpiry => _aiSubscriptionExpiry;
  int get totalPoints => _totalPoints;

  /// True while a separately-purchased Unlimited AI subscription is active.
  /// Independent of subscriptionTier/subscriptionExpiry (the App Plan), so
  /// the App Plan's free trial never grants free AI.
  bool get hasUnlimitedAI =>
      _aiSubscriptionExpiry != null &&
      _aiSubscriptionExpiry!.isAfter(DateTime.now());

  bool get canUseAI {
    if (role == UserRole.admin) return true;
    if (hasUnlimitedAI) return true;
    return _aiCredits > 0;
  }

  /// True while the current App Plan period (subscriptionTier/subscriptionExpiry)
  /// is the free trial, rather than a paid period.
  bool get isTrialActive =>
      _isTrialSubscription &&
      _subscriptionExpiry != null &&
      _subscriptionExpiry!.isAfter(DateTime.now());

  /// True while the App Plan (subscriptionTier/subscriptionExpiry) is an
  /// active paid period or the active free trial. Mirrors
  /// UserProfile.isSubscribed in lib/services/profile.dart.
  bool get isSubscribed =>
      (_subscriptionTier != SubscriptionTier.free &&
          _subscriptionExpiry != null &&
          _subscriptionExpiry!.isAfter(DateTime.now())) ||
      isTrialActive;

  /// New-account grace window, kept in sync with UserProfile's copy in
  /// lib/services/profile.dart (and the SQL is_authorized() function). On
  /// top of the free trial, not in place of it.
  static const _newAccountGraceWindow = Duration(days: 3);

  /// Kept in sync with UserProfile's copy in lib/services/profile.dart and
  /// the `INTERVAL '14 days'` in
  /// supabase/migrations/shorten_free_trial_to_two_weeks.sql.
  static const _trialLength = Duration(days: 14);

  /// Central logic for the Hard Paywall. Mirrors UserProfile.hasAccess.
  bool get hasAccess {
    if (_role == UserRole.admin || _role == UserRole.contributor) return true;
    if (isSubscribed) return true;
    if (_createdAt != null &&
        DateTime.now().difference(_createdAt!) < _newAccountGraceWindow) {
      return true;
    }
    return false;
  }

  /// Whether the realtime profile stream has delivered its first snapshot
  /// yet for the currently logged-in user. Lets `AuthWrapper` distinguish
  /// "no real data yet" (show a loader) from "real data says no access"
  /// (show PaywallScreen) — without it, every login/app-resume would flash
  /// PaywallScreen for a frame since the default field values (free tier,
  /// no createdAt) evaluate hasAccess == false.
  bool _profileLoaded = false;
  bool get profileLoaded => _profileLoaded;

  /// Populates fields from the last snapshot `persistCache()` saved, without
  /// marking [profileLoaded] true yet — `AuthWrapper` only trusts this once
  /// [tryUseCachedProfile] confirms it belongs to the account that's
  /// actually signed in. Corrupt/missing/old-shape cache is silently
  /// ignored, same as having no cache at all.
  void _hydrateFromCache() {
    try {
      final raw = _prefs?.getString(_cacheKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cachedUid = map['uid'] as String?;
      _name = map['name'] as String?;
      _email = map['email'] as String?;
      _matricule = map['matricule'] as String?;
      _phonenumber = map['phoneNumber'] as String?;
      _avatarUrl = map['avatarUrl'] as String?;
      _institutionId = map['institutionId'] as String?;
      _institutionName = map['institutionName'] as String?;
      _bio = map['bio'] as String?;
      _department = map['department'] as String?;
      _level = map['level'] as String?;
      _role = UserRole.fromString(map['role'] as String?);
      _subscriptionTier = SubscriptionTier.fromString(map['subscriptionTier'] as String?);
      _subscriptionExpiry = _parseDate(map['subscriptionExpiry']);
      _freeDownloadCount = (map['freeDownloadCount'] as num?)?.toInt() ?? 0;
      _aiCredits = (map['aiCredits'] as num?)?.toInt() ?? 0;
      _createdAt = _parseDate(map['createdAt']);
      _trialUsed = map['trialUsed'] as bool? ?? false;
      _isTrialSubscription = map['isTrialSubscription'] as bool? ?? false;
      _aiSubscriptionExpiry = _parseDate(map['aiSubscriptionExpiry']);
      _totalPoints = (map['totalPoints'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Corrupt/old cache shape — behaves as if there were no cache.
      _cachedUid = null;
    }
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Unblocks `AuthWrapper` immediately using the cached snapshot above,
  /// if — and only if — it belongs to the account now actually signed in
  /// (`currentUid`). Without this, a cold start with no internet hangs
  /// forever: `AuthWrapper` waits on the live realtime profile stream,
  /// which never emits offline, and there is otherwise no fallback. The
  /// live stream still overwrites this with fresh data (and re-persists
  /// the cache) once/if it does arrive — this is only a stand-in until then.
  bool tryUseCachedProfile(String currentUid) {
    if (_profileLoaded || _cachedUid == null || _cachedUid != currentUid) {
      return false;
    }
    _uid = currentUid;
    _profileLoaded = true;
    notifyListeners();
    return true;
  }

  /// Saves the current snapshot so the next cold start can use
  /// [tryUseCachedProfile] instead of blocking on the live stream. Call
  /// this after every live profile update (see AuthWrapper).
  Future<void> persistCache() async {
    final prefs = _prefs;
    if (prefs == null || _uid == null) return;
    // Keep in-memory state consistent with what's about to be on disk, so a
    // same-session re-login (e.g. a token refresh) can still short-circuit
    // via tryUseCachedProfile instead of falling through to the live wait.
    _cachedUid = _uid;
    final map = {
      'uid': _uid,
      'name': _name,
      'email': _email,
      'matricule': _matricule,
      'phoneNumber': _phonenumber,
      'avatarUrl': _avatarUrl,
      'institutionId': _institutionId,
      'institutionName': _institutionName,
      'bio': _bio,
      'department': _department,
      'level': _level,
      'role': _role.name,
      'subscriptionTier': _subscriptionTier.name,
      'subscriptionExpiry': _subscriptionExpiry?.toIso8601String(),
      'freeDownloadCount': _freeDownloadCount,
      'aiCredits': _aiCredits,
      'createdAt': _createdAt?.toIso8601String(),
      'trialUsed': _trialUsed,
      'isTrialSubscription': _isTrialSubscription,
      'aiSubscriptionExpiry': _aiSubscriptionExpiry?.toIso8601String(),
      'totalPoints': _totalPoints,
    };
    try {
      await prefs.setString(_cacheKey, jsonEncode(map));
    } catch (_) {
      // Best-effort — a caching failure shouldn't affect the live session.
    }
  }

  int get trialDaysRemaining {
    if (!isTrialActive) return 0;
    return _subscriptionExpiry!.difference(DateTime.now()).inDays.clamp(0, _trialLength.inDays);
  }

  String trialTimeLeft(AppLocalizations l10n) {
    if (!isTrialActive) return l10n.unlimitedLabel;
    final days = trialDaysRemaining;
    return days > 0 ? l10n.daysRemainingLabel(days) : l10n.endingTodayLabel;
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setInstitutionId(String? id) {
    _institutionId = id;
    notifyListeners();
  }

  void setInstitutionName(String? name) {
    _institutionName = name;
    notifyListeners();
  }

  void update({
    String? uid,
    String? name,
    String? email,
    String? matricule,
    String? phoneNumber,
    String? avatarUrl,
    String? institutionId,
    String? institutionName,
    String? bio,
    String? department,
    String? level,
    UserRole? role,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    int? freeDownloadCount,
    int? aiCredits,
    DateTime? createdAt,
    bool? trialUsed,
    bool? isTrialSubscription,
    DateTime? aiSubscriptionExpiry,
    bool? profileLoaded,
    int? totalPoints,
  }) {
    if (uid != null) _uid = uid;
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (matricule != null) _matricule = matricule;
    if (phoneNumber != null) _phonenumber = phoneNumber;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (institutionId != null) _institutionId = institutionId;
    if (institutionName != null) _institutionName = institutionName;
    if (bio != null) _bio = bio;
    if (department != null) _department = department;
    if (level != null) _level = level;
    if (role != null) _role = role;
    if (subscriptionTier != null) _subscriptionTier = subscriptionTier;
    if (subscriptionExpiry != null) _subscriptionExpiry = subscriptionExpiry;
    if (freeDownloadCount != null) _freeDownloadCount = freeDownloadCount;
    if (aiCredits != null) _aiCredits = aiCredits;
    if (createdAt != null) _createdAt = createdAt;
    if (trialUsed != null) _trialUsed = trialUsed;
    if (isTrialSubscription != null) _isTrialSubscription = isTrialSubscription;
    if (aiSubscriptionExpiry != null)
      _aiSubscriptionExpiry = aiSubscriptionExpiry;
    if (profileLoaded != null) _profileLoaded = profileLoaded;
    if (totalPoints != null) _totalPoints = totalPoints;
    notifyListeners();
  }
}

class DepartmentUI extends StatelessWidget {
  const DepartmentUI({
    super.key,
    required this.color,
    required this.imageurl,
    required this.title,
    required this.description,
    required this.hostid,
  });
  final Color color;
  final String imageurl, title, description, hostid;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.isMobile ? 220 : 250,
      width: context.isMobile ? context.widthPct(45) : 280,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: context.isMobile ? 100 : 120,
            width: double.infinity,
            child: Image.asset(imageurl, fit: BoxFit.cover),
          ),
          SizedBox(height: 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18)),
              Text(description),
              Text(hostid),
            ],
          ),
        ],
      ),
    );
  }
}

List<Map<String, String>> computersciencecourses = [
  {'CSC205': 'Introduction to Computer Science'},
  {'CSC207': 'Introduction to  Algorithms'},
  {'CSC208': 'Programming in Python and C'},
  {'CSC209': 'Mathematical Foundations of Computer Science'},
  {'CSC210': 'Matrices and Linear Transformations'},
  {'CSC211': 'Probability and Statistics'},
  {'CSC212': 'Issues in Computing'},
  {'CSC214': 'Internet Technology and Web Design'},
  {'CSC301': 'Data Structures and Algorithms'},
  {'CSC303': 'Computer Organization and Architecture'},
  {'CSC304': 'Database Design'},
  {'CSC305': 'Object Oriented Programming'},
  {'CSC308': 'Java Programming'},
  {'CSC310': 'Database Design'},
  {'CSC311': 'Introduction to Computer Networks'},
  {'CSC314': 'Operating Systems'},
  {'CSC316': 'Functional Programming'},
  {'CSC402': 'Languages and Compilers'},
  {'CSC403': 'Numerical Analysis'},
  {'CSC404': 'Software Engineering'},
  {'CSC405': 'Artificial Intelligence'},
  {'CSC407': 'Programming and Language Paradigms'},
  {'CSC498': 'Computer Science Project'},
];

List<Map<String, String>> mathematicsCourses = [
  {'MAT201': 'Calculus I'},
  {'MAT202': 'Calculus II'},
  {'MAT203': 'Abstract Algebra'},
  {'MAT204': 'Linear Methods'},
  {'MAT207': 'Mathematical Methods IA'},
  {'MAT208': 'Mathematical Methods IIA'},
  {'MAT211': 'Mathematical Methods'},
  {'MAT301': 'Analysis I'},
  {'MAT302': 'Analysis II'},
  {'MAT303': 'Linear Algebra I'},
  {'MAT304': 'Linear Algebra II'},
  {'MAT305': 'Mathematical Probability I'},
  {'MAT306': 'Introduction to Mathematical Statistics'},
  {'MAT307': 'Introduction to Differential Equations'},
  {'MAT310': 'Mathematical Methods III'},
  {'MAT311': 'Analytical Mechanics'},
  {'MAT312': 'Electromagnetism'},
  {'MAT314': 'Analytic Geometry'},
  {'MAT401': 'Analysis III'},
  {'MAT402': 'General Topology'},
  {'MAT403': 'Set Theory'},
  {'MAT404': 'Group Theory'},
  {'MAT406': 'Mathematical Probability II'},
  {'MAT407': 'Complex Analysis I'},
  {'MAT409': 'Ordinary Differential Equations'},
  {'MAT411': 'Analytical Dynamics'},
  {'MAT412': 'Hydromechanics'},
  {'MAT413': 'Affine and Projective Geometry'},
  {'MAT415': 'Differential Geometry'},
  {'MAT416': 'Measure Theory and Integration'},
  {'MAT417': 'Calculus of Variations'},
  {'MAT418': 'Numerical Methods'},
  {'MAT419': 'Elements of Stochastic Processes'},
  {'MAT420': 'Elements of Queuing Theory'},
  {'MAT421': 'Multivariate Statistics'},
  {'MAT422': 'Introduction to Optimization'},
  {'MAT423': 'Combinatorics and Graph Theory'},
  {'MAT498': 'Research Project'},
];

List<Map<String, String>> physicsCourses = [
  {'ELT201': 'Electronic Devices'},
  {'ELT204': 'Analogue Electronics and basic circuit analysis'},
  {'ELT301': 'Digital Electronics'},
  {'ELT302': 'Microprocessors'},
  {'ELT303': 'Applied Electronics and Workshop Practice'},
  {'ELT304': 'Digital design laboratory'},
  {'ELT307': 'RF and Microwave Systems'},
  {'ELT401': 'Power Electronics'},
  {'ELT402': 'Communication systems'},
  {'ELT403': 'Analogue Integrated circuits'},
  {'ELT404': 'Introduction to control systems'},
  {'ELT406': 'Digital signal processing'},
  {'ELT408': 'Introduction toPHYsical design and Integrated circuits'},
  {'ELT410': 'Signal and systems'},
  {'ELT412': 'Computer architecture and data networks'},
  {'ELT426': 'Analogue Integrated circuits laboratory'},
  {'ELT491': 'Professional Internship'},
  {'ELT498': 'Project'},
  {'PHY202': 'Mechanics I'},
  {'PHY205': 'Thermodynamics and Structure of Matter'},
  {'PHY207': 'Mathematical Methods forPHYsics I'},
  {'PHY208': 'Electricity and Magnetism I'},
  {'PHY211': 'Waves and Optics I'},
  {'PHY212': 'GeneralPHYsics'},
  {'PHY215': 'Basic Concepts of Waves and Optics'},
  {'PHY218': 'Principles of Electricity and Magnetism'},
  {'PHY220': 'GeneralPHYsics'},
  {'PHY301': 'Mechanics II'},
  {'PHY305': 'Electricity and Magnetism II'},
  {'PHY306': 'Mathematical Methods of PHYsics II'},
  {'PHY308': 'Quantum Mechanics I'},
  {'PHY311': 'General Physics IIA'},
  {'PHY312': 'ThermalPHYsics'},
  {'PHY314': 'Special Relativity'},
  {'PHY317': 'Electronics I'},
  {'PHY405': 'Solid StatePHYsics'},
  {'PHY406': 'Atomic and NuclearPHYsics'},
  {'PHY410': 'Quantum Mechanics II'},
  {'PHY411': 'Electrodynamics'},
  {'PHY412': 'Waves and Optics II'},
  {'PHY417': 'Introduction to General Relativity and Cosmology'},
  {'PHY419': 'Introduction to Geophysics'},
  {'PHY420': 'Introduction to StatisticalPHYsics and Applications'},
  {'PHY422': 'Electronics II'},
  {'PHY424': 'Introduction to fluid mechanics'},
  {'PHY498': 'Physics project'},
];

Future<Map<String, dynamic>> getquestions() async {
  await Future.delayed(Duration(seconds: 2));
  final url = Uri.parse("https://opentdb.com/api.php?amount=50&category=18");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print("Error: ${response.body}");
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching questions: $e');
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: context.dynamicText(36),
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : theme.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: context.dynamicText(17),
            height: 1.5,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          fontSize: context.dynamicText(14),
          color: isDarkMode ? Colors.white38 : Colors.grey[500],
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: context.dynamicSize(22),
          color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : Colors.grey.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(
          vertical: context.dynamicSize(18),
          horizontal: context.dynamicSize(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: context.dynamicSize(60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode
              ? Colors.cyanAccent
              : theme.colorScheme.primary,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class AuthDropdown extends StatelessWidget {
  final String value;
  final String hintText;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const AuthDropdown({
    super.key,
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      isExpanded: true,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      icon: Icon(
        Icons.expand_more_rounded,
        color: isDarkMode ? Colors.white54 : Colors.grey[600],
      ),
      dropdownColor: isDarkMode
          ? theme.colorScheme.surfaceContainerHigh
          : Colors.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          color: isDarkMode ? Colors.white38 : Colors.grey[500],
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 22,
          color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
        ),
        filled: true,
        fillColor: isDarkMode
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : Colors.grey.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
