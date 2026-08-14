import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get\nStarted'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Set up your academic journey in a structured space built for students, departments, and shared study resources.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Get to\nKnow'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Find your institution, explore its schools and departments, and move quickly into the right courses and materials.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Study\nTogether'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Use department pages, group chat, notes, and shared content to collaborate with classmates without friction.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Learn\nSmarter'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Track tasks, prepare for exams, use AI support, and stay organized with tools designed for an academic workflow.'**
  String get onboardingPage4Body;

  /// No description provided for @signInWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInWelcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your academic journey.'**
  String get signInSubtitle;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressHint;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @minimumSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minimumSixCharacters;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Registration'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account in four guided steps designed for the academic workflow.'**
  String get registerSubtitle;

  /// No description provided for @registerStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String registerStepOf(int current, int total);

  /// No description provided for @registerBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get registerBack;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get registerComplete;

  /// No description provided for @registerVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION REQUIRED'**
  String get registerVerificationRequired;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get alreadyRegistered;

  /// No description provided for @signInToPortal.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Portal'**
  String get signInToPortal;

  /// No description provided for @accountStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountStepTitle;

  /// No description provided for @accountStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure your academic profile with a strong email and password.'**
  String get accountStepDescription;

  /// No description provided for @accountCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account credentials'**
  String get accountCredentialsTitle;

  /// No description provided for @accountCredentialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This section protects your portal access and your study records.'**
  String get accountCredentialsSubtitle;

  /// No description provided for @academicEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Email'**
  String get academicEmailLabel;

  /// No description provided for @academicEmailHint.
  ///
  /// In en, this message translates to:
  /// **'student@university.edu'**
  String get academicEmailHint;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @securePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Secure Password'**
  String get securePasswordLabel;

  /// No description provided for @enterStrongPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter strong password'**
  String get enterStrongPasswordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @minimumEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimumEightCharacters;

  /// No description provided for @addUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'Add at least one uppercase letter'**
  String get addUppercaseLetter;

  /// No description provided for @addDigit.
  ///
  /// In en, this message translates to:
  /// **'Add at least one digit'**
  String get addDigit;

  /// No description provided for @addSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Add a special character'**
  String get addSpecialCharacter;

  /// No description provided for @passwordSecurityLabel.
  ///
  /// In en, this message translates to:
  /// **'Password Security'**
  String get passwordSecurityLabel;

  /// No description provided for @passwordStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Use a mix of uppercase letters, numbers, and symbols.'**
  String get passwordStrengthHint;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @repeatPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPasswordHint;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @identityStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identityStepTitle;

  /// No description provided for @identityStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your real name and contact details so the community can identify you.'**
  String get identityStepDescription;

  /// No description provided for @personalIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal identity'**
  String get personalIdentityTitle;

  /// No description provided for @personalIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This section makes your profile recognizable to classmates and admins.'**
  String get personalIdentitySubtitle;

  /// No description provided for @fullLegalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Legal Name'**
  String get fullLegalNameLabel;

  /// No description provided for @firstLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'First and Last Name'**
  String get firstLastNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @phoneContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Contact'**
  String get phoneContactLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @academicStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get academicStepTitle;

  /// No description provided for @academicStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your university, matricule, and study level to unlock the right resources.'**
  String get academicStepDescription;

  /// No description provided for @academicAffiliationTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic affiliation'**
  String get academicAffiliationTitle;

  /// No description provided for @academicAffiliationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This links your account to the correct educational track.'**
  String get academicAffiliationSubtitle;

  /// No description provided for @studentMatriculeLabel.
  ///
  /// In en, this message translates to:
  /// **'Student Matricule'**
  String get studentMatriculeLabel;

  /// No description provided for @officialUniversityIdHint.
  ///
  /// In en, this message translates to:
  /// **'Official University ID'**
  String get officialUniversityIdHint;

  /// No description provided for @matriculeRequired.
  ///
  /// In en, this message translates to:
  /// **'Matricule is required'**
  String get matriculeRequired;

  /// No description provided for @currentAcademicLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Academic Level'**
  String get currentAcademicLevelLabel;

  /// No description provided for @selectYourLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Select your level'**
  String get selectYourLevelHint;

  /// No description provided for @pleaseSelectLevel.
  ///
  /// In en, this message translates to:
  /// **'Please select a level'**
  String get pleaseSelectLevel;

  /// No description provided for @assignedInstitutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned Institution'**
  String get assignedInstitutionLabel;

  /// No description provided for @selectYourUniversityHint.
  ///
  /// In en, this message translates to:
  /// **'Select your University'**
  String get selectYourUniversityHint;

  /// No description provided for @pleaseSelectUniversity.
  ///
  /// In en, this message translates to:
  /// **'Please select your university'**
  String get pleaseSelectUniversity;

  /// No description provided for @academicLevelResit.
  ///
  /// In en, this message translates to:
  /// **'Resit'**
  String get academicLevelResit;

  /// No description provided for @finalizeStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get finalizeStepTitle;

  /// No description provided for @finalizeStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile with your department and a short academic bio.'**
  String get finalizeStepDescription;

  /// No description provided for @finalizeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalize profile'**
  String get finalizeProfileTitle;

  /// No description provided for @finalizeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is the last step before your study account is ready.'**
  String get finalizeProfileSubtitle;

  /// No description provided for @academicBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Bio'**
  String get academicBioLabel;

  /// No description provided for @academicBioHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your academic interests...'**
  String get academicBioHint;

  /// No description provided for @academicDepartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Department'**
  String get academicDepartmentLabel;

  /// No description provided for @selectInstitutionFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Select an institution in the previous step to load departments.'**
  String get selectInstitutionFirstHint;

  /// No description provided for @chooseYourDepartmentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your Department'**
  String get chooseYourDepartmentHint;

  /// No description provided for @pleaseSelectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Please select your department'**
  String get pleaseSelectDepartment;

  /// No description provided for @noDepartmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No departments found for this institution.'**
  String get noDepartmentsFound;

  /// No description provided for @agreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTermsPrefix;

  /// No description provided for @termsOfServiceLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceLink;

  /// No description provided for @andSeparator.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andSeparator;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLink;

  /// No description provided for @agreeToTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms of Service and Privacy Policy to continue'**
  String get agreeToTermsRequired;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Profile'**
  String get accountProfileTitle;

  /// No description provided for @accountProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and edit your personal information'**
  String get accountProfileSubtitle;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users, roles, and departments'**
  String get adminDashboardSubtitle;

  /// No description provided for @aiCreditsPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Credits & Plans'**
  String get aiCreditsPlansTitle;

  /// No description provided for @aiCreditsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} Credits remaining'**
  String aiCreditsRemaining(int count);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your alerts and message preferences'**
  String get notificationsSubtitle;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark themes'**
  String get darkModeSubtitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we protect and use your data'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rules for using GO Study'**
  String get termsOfServiceSubtitle;

  /// No description provided for @supportGoStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Go Study'**
  String get supportGoStudyTitle;

  /// No description provided for @supportGoStudySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsor development or volunteer to help'**
  String get supportGoStudySubtitle;

  /// No description provided for @supportOptionsDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to support development.'**
  String get supportOptionsDialogBody;

  /// No description provided for @chatOnWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get chatOnWhatsAppButton;

  /// No description provided for @donateViaAppButton.
  ///
  /// In en, this message translates to:
  /// **'Donate via App'**
  String get donateViaAppButton;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedbackTitle;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or suggest an improvement'**
  String get sendFeedbackSubtitle;

  /// No description provided for @developerInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInformationTitle;

  /// No description provided for @developerInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App version, build, and engineering details'**
  String get developerInformationSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn more about the application '**
  String get aboutSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your data — profile, tasks, grades, exams, payment history, and chat history. This cannot be undone.'**
  String get deleteAccountDialogBody;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm.'**
  String get deleteAccountTypeToConfirm;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account: {error}'**
  String deleteAccountFailed(String error);

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app language'**
  String get appLanguageSubtitle;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @homeToolAiStudy.
  ///
  /// In en, this message translates to:
  /// **'AI Study'**
  String get homeToolAiStudy;

  /// No description provided for @homeToolExamSchedule.
  ///
  /// In en, this message translates to:
  /// **'Exam Schedule'**
  String get homeToolExamSchedule;

  /// No description provided for @homeToolPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get homeToolPerformance;

  /// No description provided for @homeToolLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get homeToolLibrary;

  /// No description provided for @homeToolNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get homeToolNews;

  /// No description provided for @homeToolMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get homeToolMarketplace;

  /// No description provided for @homeToolTaskManager.
  ///
  /// In en, this message translates to:
  /// **'Task Manager'**
  String get homeToolTaskManager;

  /// No description provided for @homeToolFocusTimer.
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get homeToolFocusTimer;

  /// No description provided for @homeToolTranscripts.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get homeToolTranscripts;

  /// No description provided for @homeToolPortal.
  ///
  /// In en, this message translates to:
  /// **'PORTAL'**
  String get homeToolPortal;

  /// No description provided for @homeToolSupportBot.
  ///
  /// In en, this message translates to:
  /// **'UB Support Bot'**
  String get homeToolSupportBot;

  /// No description provided for @homeToolOfflineAi.
  ///
  /// In en, this message translates to:
  /// **'Offline AI'**
  String get homeToolOfflineAi;

  /// No description provided for @gemmaChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline AI Chat'**
  String get gemmaChatTitle;

  /// No description provided for @gemmaChatDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat offline, for free'**
  String get gemmaChatDownloadTitle;

  /// No description provided for @gemmaChatDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'Download a one-time AI model (~530 MB) to chat with an AI tutor with no internet connection and no AI credits used. Wi-Fi is recommended.'**
  String get gemmaChatDownloadBody;

  /// No description provided for @gemmaChatDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get gemmaChatDownloadButton;

  /// No description provided for @gemmaChatDownloadProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String gemmaChatDownloadProgressPercent(int percent);

  /// No description provided for @gemmaChatDownloadCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gemmaChatDownloadCancelButton;

  /// No description provided for @gemmaChatDownloadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String gemmaChatDownloadFailedBody(String error);

  /// No description provided for @gemmaChatRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get gemmaChatRetryButton;

  /// No description provided for @gemmaChatRemoveModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove offline AI?'**
  String get gemmaChatRemoveModelTitle;

  /// No description provided for @gemmaChatRemoveModelBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the downloaded model from your device. You can download it again anytime.'**
  String get gemmaChatRemoveModelBody;

  /// No description provided for @gemmaChatRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get gemmaChatRemoveButton;

  /// No description provided for @gemmaChatRemoveMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove downloaded model'**
  String get gemmaChatRemoveMenuLabel;

  /// No description provided for @gemmaChatEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything, offline'**
  String get gemmaChatEmptyStateTitle;

  /// No description provided for @gemmaChatEmptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'No internet needed. No credits used.'**
  String get gemmaChatEmptyStateBody;

  /// No description provided for @gemmaChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message offline AI…'**
  String get gemmaChatInputHint;

  /// No description provided for @gemmaChatUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get gemmaChatUnavailableTitle;

  /// No description provided for @gemmaChatUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Offline AI currently requires Android. iOS support is planned.'**
  String get gemmaChatUnavailableBody;

  /// No description provided for @gemmaChatInfoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you download'**
  String get gemmaChatInfoDialogTitle;

  /// No description provided for @gemmaChatInfoDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand, download'**
  String get gemmaChatInfoDialogConfirm;

  /// No description provided for @gemmaChatInfoStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get gemmaChatInfoStorageTitle;

  /// No description provided for @gemmaChatInfoStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Uses about 530 MB of your phone\'s storage, permanently, until you remove it from this screen.'**
  String get gemmaChatInfoStorageBody;

  /// No description provided for @gemmaChatInfoRamTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory (RAM)'**
  String get gemmaChatInfoRamTitle;

  /// No description provided for @gemmaChatInfoRamBody.
  ///
  /// In en, this message translates to:
  /// **'Needs extra memory while you\'re chatting — works best on phones with at least 4 GB of RAM. Older or low-RAM phones may slow down while offline AI is in use.'**
  String get gemmaChatInfoRamBody;

  /// No description provided for @gemmaChatInfoPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get gemmaChatInfoPerformanceTitle;

  /// No description provided for @gemmaChatInfoPerformanceBody.
  ///
  /// In en, this message translates to:
  /// **'Responses are generated on your phone\'s own processor, so replies can be slower than the online AI tutor and may use more battery while chatting.'**
  String get gemmaChatInfoPerformanceBody;

  /// No description provided for @gemmaChatInfoAccuracyTitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get gemmaChatInfoAccuracyTitle;

  /// No description provided for @gemmaChatInfoAccuracyBody.
  ///
  /// In en, this message translates to:
  /// **'This is a smaller, lighter AI model built to run offline. Its answers can sometimes be incomplete or incorrect — always double-check anything important.'**
  String get gemmaChatInfoAccuracyBody;

  /// No description provided for @gemmaChatInfoDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Is your phone ready?'**
  String get gemmaChatInfoDeviceTitle;

  /// No description provided for @gemmaChatInfoDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Only download this if your phone is a reasonably recent, mid-range or higher device with enough free storage. On older or budget phones, offline AI may run slowly or affect the rest of the app\'s performance.'**
  String get gemmaChatInfoDeviceBody;

  /// No description provided for @sectionDepartmentsFaculties.
  ///
  /// In en, this message translates to:
  /// **'Departments & Faculties'**
  String get sectionDepartmentsFaculties;

  /// No description provided for @sectionTools.
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get sectionTools;

  /// No description provided for @noDepartmentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No departments available yet.'**
  String get noDepartmentsAvailable;

  /// No description provided for @exploreResources.
  ///
  /// In en, this message translates to:
  /// **'Explore Resources'**
  String get exploreResources;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @scholarFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Scholar'**
  String get scholarFallbackName;

  /// No description provided for @homeTrialLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial: {time}'**
  String homeTrialLabel(String time);

  /// No description provided for @resumeLearningLabel.
  ///
  /// In en, this message translates to:
  /// **'Resume Learning'**
  String get resumeLearningLabel;

  /// No description provided for @studentFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentFallbackName;

  /// No description provided for @unifiedAcademicPortal.
  ///
  /// In en, this message translates to:
  /// **'Unified Academic Portal'**
  String get unifiedAcademicPortal;

  /// No description provided for @noConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get noConnectionTitle;

  /// No description provided for @noConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet and try again.'**
  String get noConnectionBody;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @globalChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Global Chat'**
  String get globalChatTooltip;

  /// No description provided for @examSchedulePleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your schedule.'**
  String get examSchedulePleaseSignIn;

  /// No description provided for @allEventsListTitle.
  ///
  /// In en, this message translates to:
  /// **'All Events List'**
  String get allEventsListTitle;

  /// No description provided for @noEventsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled yet.'**
  String get noEventsScheduled;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @pleaseSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get pleaseSignInMessage;

  /// No description provided for @addTaskDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTaskDialogTitle;

  /// No description provided for @newTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTaskTitle;

  /// No description provided for @newTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get newTaskSubtitle;

  /// No description provided for @taskNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskNameLabel;

  /// No description provided for @taskNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Study Physics'**
  String get taskNameHint;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief details...'**
  String get taskDescriptionHint;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @taskProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String taskProgressLabel(int percent);

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @selectPriorityHint.
  ///
  /// In en, this message translates to:
  /// **'Select priority'**
  String get selectPriorityHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategoryHint;

  /// No description provided for @createTaskButton.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTaskButton;

  /// No description provided for @taskReminderNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Reminder'**
  String get taskReminderNotifTitle;

  /// No description provided for @taskReminderNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget: {title}'**
  String taskReminderNotifBody(String title);

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get categoryAcademic;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get categoryResearch;

  /// No description provided for @categorySideProjects.
  ///
  /// In en, this message translates to:
  /// **'Side projects'**
  String get categorySideProjects;

  /// No description provided for @toDoListTitle.
  ///
  /// In en, this message translates to:
  /// **'To-Do List'**
  String get toDoListTitle;

  /// No description provided for @searchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasksHint;

  /// No description provided for @noTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// No description provided for @taskGroupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskGroupOverdue;

  /// No description provided for @taskGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskGroupToday;

  /// No description provided for @taskGroupUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get taskGroupUpcoming;

  /// No description provided for @taskGroupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskGroupCompleted;

  /// No description provided for @noDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'No Deadline'**
  String get noDeadlineLabel;

  /// No description provided for @deadlineDisplay.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String deadlineDisplay(String date);

  /// No description provided for @focusCompleteNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Complete!'**
  String get focusCompleteNotifTitle;

  /// No description provided for @focusCompleteNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Great job! Take a short break.'**
  String get focusCompleteNotifBody;

  /// No description provided for @focusModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusModeTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @focusStatusFocusing.
  ///
  /// In en, this message translates to:
  /// **'FOCUSING'**
  String get focusStatusFocusing;

  /// No description provided for @focusStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'IDLE'**
  String get focusStatusIdle;

  /// No description provided for @focusPause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get focusPause;

  /// No description provided for @focusEngage.
  ///
  /// In en, this message translates to:
  /// **'ENGAGE'**
  String get focusEngage;

  /// No description provided for @focusReset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get focusReset;

  /// No description provided for @customizeTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Timer'**
  String get customizeTimerTitle;

  /// No description provided for @quickPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'QUICK PRESETS'**
  String get quickPresetsLabel;

  /// No description provided for @customDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM DURATION'**
  String get customDurationLabel;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @applyAndClose.
  ///
  /// In en, this message translates to:
  /// **'Apply & Close'**
  String get applyAndClose;

  /// No description provided for @offlineLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Library'**
  String get offlineLibraryTitle;

  /// No description provided for @offlineLibraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your offline library is empty.'**
  String get offlineLibraryEmptyTitle;

  /// No description provided for @offlineLibraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Download materials to access them without data.'**
  String get offlineLibraryEmptyBody;

  /// No description provided for @localCopySuffix.
  ///
  /// In en, this message translates to:
  /// **'{category} • Local Copy'**
  String localCopySuffix(String category);

  /// No description provided for @offlineFormatNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Format not supported for offline viewing yet'**
  String get offlineFormatNotSupported;

  /// No description provided for @deleteOfflineCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Offline Copy?'**
  String get deleteOfflineCopyTitle;

  /// No description provided for @removeFromDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get removeFromDeviceSubtitle;

  /// No description provided for @deleteOfflineCopyBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the secured copy of \'{title}\' from your device. You can re-download it anytime you\'re online.'**
  String deleteOfflineCopyBody(String title);

  /// No description provided for @deleteNowButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Now'**
  String get deleteNowButton;

  /// No description provided for @universityNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'University News'**
  String get universityNewsTitle;

  /// No description provided for @refreshNewsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh News'**
  String get refreshNewsTooltip;

  /// No description provided for @couldntFetchNews.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch news'**
  String get couldntFetchNews;

  /// No description provided for @unexpectedErrorTryLater.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again later.'**
  String get unexpectedErrorTryLater;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncementsYet;

  /// No description provided for @readFullArticle.
  ///
  /// In en, this message translates to:
  /// **'Read Full Article'**
  String get readFullArticle;

  /// No description provided for @performanceTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Tracker'**
  String get performanceTrackerTitle;

  /// No description provided for @switchToListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch to List'**
  String get switchToListTooltip;

  /// No description provided for @switchToPredictorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch to Predictor'**
  String get switchToPredictorTooltip;

  /// No description provided for @addGradeButton.
  ///
  /// In en, this message translates to:
  /// **'Add Grade'**
  String get addGradeButton;

  /// No description provided for @currentGpaLabel.
  ///
  /// In en, this message translates to:
  /// **'Current GPA'**
  String get currentGpaLabel;

  /// No description provided for @totalCreditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Credits'**
  String get totalCreditsLabel;

  /// No description provided for @gradePredictorTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade Predictor'**
  String get gradePredictorTitle;

  /// No description provided for @targetGpaLabel.
  ///
  /// In en, this message translates to:
  /// **'Target GPA'**
  String get targetGpaLabel;

  /// No description provided for @plannedCreditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned Credits'**
  String get plannedCreditsLabel;

  /// No description provided for @adviceImpossibleTarget.
  ///
  /// In en, this message translates to:
  /// **'Mathematically impossible this semester. Try a lower target.'**
  String get adviceImpossibleTarget;

  /// No description provided for @adviceOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great! Even a low grade will maintain your goal.'**
  String get adviceOnTrack;

  /// No description provided for @adviceNeedAverage.
  ///
  /// In en, this message translates to:
  /// **'You need an average of {grade} to reach {target}.'**
  String adviceNeedAverage(String grade, String target);

  /// No description provided for @semesterResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Semester Results'**
  String get semesterResultsTitle;

  /// No description provided for @coursesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Courses'**
  String coursesCount(int count);

  /// No description provided for @noGradesSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No grades saved yet. Use the \'+\' button to add your results.'**
  String get noGradesSavedYet;

  /// No description provided for @creditsAndSemester.
  ///
  /// In en, this message translates to:
  /// **'{credits} Credits • {semester}'**
  String creditsAndSemester(int credits, String semester);

  /// No description provided for @unknownSemester.
  ///
  /// In en, this message translates to:
  /// **'Unknown Semester'**
  String get unknownSemester;

  /// No description provided for @addResultDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Result'**
  String get addResultDialogTitle;

  /// No description provided for @addResultDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your academic success'**
  String get addResultDialogSubtitle;

  /// No description provided for @courseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Course Name'**
  String get courseNameLabel;

  /// No description provided for @courseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CSC 201'**
  String get courseNameHint;

  /// No description provided for @creditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsLabel;

  /// No description provided for @selectCreditsHint.
  ///
  /// In en, this message translates to:
  /// **'Select credits'**
  String get selectCreditsHint;

  /// No description provided for @gradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeLabel;

  /// No description provided for @selectGradeHint.
  ///
  /// In en, this message translates to:
  /// **'Select grade'**
  String get selectGradeHint;

  /// No description provided for @semesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semesterLabel;

  /// No description provided for @selectSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'Select semester'**
  String get selectSemesterHint;

  /// No description provided for @firstSemester.
  ///
  /// In en, this message translates to:
  /// **'First Semester'**
  String get firstSemester;

  /// No description provided for @secondSemester.
  ///
  /// In en, this message translates to:
  /// **'Second Semester'**
  String get secondSemester;

  /// No description provided for @saveResultButton.
  ///
  /// In en, this message translates to:
  /// **'Save Result'**
  String get saveResultButton;

  /// No description provided for @aiStudyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Study Plan'**
  String get aiStudyPlanTitle;

  /// No description provided for @regeneratePlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Plan'**
  String get regeneratePlanTooltip;

  /// No description provided for @aiAnalyzingSchedule.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your schedule...'**
  String get aiAnalyzingSchedule;

  /// No description provided for @readyForSmarterStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for a Smarter Study Session?'**
  String get readyForSmarterStudyTitle;

  /// No description provided for @readyForSmarterStudyBody.
  ///
  /// In en, this message translates to:
  /// **'I\'ll analyze your pending tasks and upcoming exams to create a balanced routine just for you.'**
  String get readyForSmarterStudyBody;

  /// No description provided for @generateMyPlanButton.
  ///
  /// In en, this message translates to:
  /// **'GENERATE MY PLAN'**
  String get generateMyPlanButton;

  /// No description provided for @aiPlanDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This plan is AI-generated and for guidance only.'**
  String get aiPlanDisclaimer;

  /// No description provided for @supportBotWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the University of Buea Support Center! I am your UB Support Bot. How can I help you with university-related inquiries today?'**
  String get supportBotWelcomeMessage;

  /// No description provided for @supportBotConnectionTrouble.
  ///
  /// In en, this message translates to:
  /// **'I\'m sorry, I\'m having trouble connecting right now. Please check your internet or try again later.'**
  String get supportBotConnectionTrouble;

  /// No description provided for @connectionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted.'**
  String get connectionInterrupted;

  /// No description provided for @universityOfBueaAssistant.
  ///
  /// In en, this message translates to:
  /// **'University of Buea Assistant'**
  String get universityOfBueaAssistant;

  /// No description provided for @manageKnowledgeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage Knowledge'**
  String get manageKnowledgeTooltip;

  /// No description provided for @askBasedOnDataHint.
  ///
  /// In en, this message translates to:
  /// **'Ask based on your data...'**
  String get askBasedOnDataHint;

  /// No description provided for @failedToLoadChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat history. Please check your connection.'**
  String get failedToLoadChatHistory;

  /// No description provided for @newFileAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'New File Analysis'**
  String get newFileAnalysisTitle;

  /// No description provided for @messageSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Message sync failed. Local history may be out of date.'**
  String get messageSyncFailed;

  /// No description provided for @outOfAiCreditsMessage.
  ///
  /// In en, this message translates to:
  /// **'You are out of AI credits.'**
  String get outOfAiCreditsMessage;

  /// No description provided for @aiThinkingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'I\'m analyzing your request and processing the information to provide a comprehensive answer...'**
  String get aiThinkingPlaceholder;

  /// No description provided for @sorryEncounteredError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I encountered an error: {error}'**
  String sorryEncounteredError(String error);

  /// No description provided for @sorryEncounteredCriticalError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I encountered a critical error: {error}'**
  String sorryEncounteredCriticalError(String error);

  /// No description provided for @deleteChatDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChatDialogTitle;

  /// No description provided for @deleteChatDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteChatDialogSubtitle;

  /// No description provided for @deleteChatConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? All messages will be permanently removed.'**
  String get deleteChatConfirmBody;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @howCanIHelpTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelpTodayMessage;

  /// No description provided for @quickStarterCalculus.
  ///
  /// In en, this message translates to:
  /// **'📈 Help me with calculus'**
  String get quickStarterCalculus;

  /// No description provided for @quickStarterStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'📝 Write a study plan'**
  String get quickStarterStudyPlan;

  /// No description provided for @quickStarterProjectIdeas.
  ///
  /// In en, this message translates to:
  /// **'💡 Project ideas'**
  String get quickStarterProjectIdeas;

  /// No description provided for @quickStarterSummarizeNotes.
  ///
  /// In en, this message translates to:
  /// **'📚 Summarize notes'**
  String get quickStarterSummarizeNotes;

  /// No description provided for @thinkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinkingLabel;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @askAiHint.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAiHint;

  /// No description provided for @newChatButton.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChatButton;

  /// No description provided for @noRecentChats.
  ///
  /// In en, this message translates to:
  /// **'No recent chats'**
  String get noRecentChats;

  /// No description provided for @clearAllChatsListTile.
  ///
  /// In en, this message translates to:
  /// **'Clear all chats'**
  String get clearAllChatsListTile;

  /// No description provided for @clearAllChatsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Chats'**
  String get clearAllChatsDialogTitle;

  /// No description provided for @clearAllChatsDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a clean slate'**
  String get clearAllChatsDialogSubtitle;

  /// No description provided for @clearAllChatsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all conversations? This action will permanently remove your entire chat history.'**
  String get clearAllChatsConfirmBody;

  /// No description provided for @clearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButton;

  /// No description provided for @showThinkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Thinking'**
  String get showThinkingLabel;

  /// No description provided for @codeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopiedToClipboard;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @privateChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Chat'**
  String get privateChatTitle;

  /// No description provided for @privateMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private Message'**
  String get privateMessageSubtitle;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainButton;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found.'**
  String get noQuestionsFound;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String correctAnswerLabel(String answer);

  /// No description provided for @reloadButton.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadButton;

  /// No description provided for @navHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHomeLabel;

  /// No description provided for @navDepartmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get navDepartmentsLabel;

  /// No description provided for @navAiAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get navAiAssistantLabel;

  /// No description provided for @navMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessagesLabel;

  /// No description provided for @navSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettingsLabel;

  /// No description provided for @studentPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Portal'**
  String get studentPortalTitle;

  /// No description provided for @syncingAcademicDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Syncing Academic Data...'**
  String get syncingAcademicDataLabel;

  /// No description provided for @reloadPageMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Reload Page'**
  String get reloadPageMenuItem;

  /// No description provided for @copyPortalLinkMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Copy Portal Link'**
  String get copyPortalLinkMenuItem;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @openInExternalBrowserMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Open in External Browser'**
  String get openInExternalBrowserMenuItem;

  /// No description provided for @allDepartmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get allDepartmentsTitle;

  /// No description provided for @searchForDepartmentHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a department...'**
  String get searchForDepartmentHint;

  /// No description provided for @newDeptButton.
  ///
  /// In en, this message translates to:
  /// **'New Dept'**
  String get newDeptButton;

  /// No description provided for @findFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Friends'**
  String get findFriendsTitle;

  /// No description provided for @searchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name…'**
  String get searchByNameHint;

  /// No description provided for @searchForStudentsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search for students to add'**
  String get searchForStudentsToAdd;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @friendsStatusChip.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsStatusChip;

  /// No description provided for @pendingStatusChip.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatusChip;

  /// No description provided for @requestedYouStatusChip.
  ///
  /// In en, this message translates to:
  /// **'Requested you'**
  String get requestedYouStatusChip;

  /// No description provided for @addFriendButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFriendButton;

  /// No description provided for @unknownUserName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUserName;

  /// No description provided for @findFriendsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get findFriendsTooltip;

  /// No description provided for @pendingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCountLabel(int count);

  /// No description provided for @friendRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequestsLabel;

  /// No description provided for @noFriendsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYetTitle;

  /// No description provided for @tapIconToFindFriends.
  ///
  /// In en, this message translates to:
  /// **'Tap the icon above to find\nand add fellow students'**
  String get tapIconToFindFriends;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @sendMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessageLabel;

  /// No description provided for @removeFriendLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get removeFriendLabel;

  /// No description provided for @noMessagesYetLabel.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYetLabel;

  /// No description provided for @acceptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptTooltip;

  /// No description provided for @declineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineTooltip;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @betaMemberBadge.
  ///
  /// In en, this message translates to:
  /// **'BETA MEMBER'**
  String get betaMemberBadge;

  /// No description provided for @openAdminDashboardButton.
  ///
  /// In en, this message translates to:
  /// **'Open Admin Dashboard'**
  String get openAdminDashboardButton;

  /// No description provided for @trialEndsInLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial Ends in: {time}'**
  String trialEndsInLabel(String time);

  /// No description provided for @personalInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationTitle;

  /// No description provided for @notSetValue.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetValue;

  /// No description provided for @matriculeLabel.
  ///
  /// In en, this message translates to:
  /// **'Matricule'**
  String get matriculeLabel;

  /// No description provided for @notProvidedValue.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvidedValue;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @currentLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Level'**
  String get currentLevelLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @noBioYetValue.
  ///
  /// In en, this message translates to:
  /// **'No bio yet'**
  String get noBioYetValue;

  /// No description provided for @unlimitedAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Access'**
  String get unlimitedAccessTitle;

  /// No description provided for @unlimitedAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can now upload and download everything for free.'**
  String get unlimitedAccessSubtitle;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmBody;

  /// No description provided for @changeAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get changeAvatarTitle;

  /// No description provided for @galleryOption.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryOption;

  /// No description provided for @cameraOption.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraOption;

  /// No description provided for @appAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get appAppearanceTitle;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColorLabel;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get roleAdmin;

  /// No description provided for @roleContributor.
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTOR'**
  String get roleContributor;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'VIEWER'**
  String get roleViewer;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required.'**
  String get adminAccessRequired;

  /// No description provided for @manageDepartmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage departments'**
  String get manageDepartmentsTitle;

  /// No description provided for @manageUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get manageUsersTitle;

  /// No description provided for @adminAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin access'**
  String get adminAccessLabel;

  /// No description provided for @administratorFallback.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administratorFallback;

  /// No description provided for @institutionFallback.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institutionFallback;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTitle;

  /// No description provided for @reviewYourAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your account'**
  String get reviewYourAccountSubtitle;

  /// No description provided for @noDepartmentsAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No departments available yet.'**
  String get noDepartmentsAvailableYet;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @schoolLabel.
  ///
  /// In en, this message translates to:
  /// **'School: {schoolId}'**
  String schoolLabel(String schoolId);

  /// No description provided for @schoolNotSet.
  ///
  /// In en, this message translates to:
  /// **'School not set'**
  String get schoolNotSet;

  /// No description provided for @searchNameMatriculeHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, matricule, or department'**
  String get searchNameMatriculeHint;

  /// No description provided for @searchForUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Search for a user'**
  String get searchForUserLabel;

  /// No description provided for @unknownUserFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUserFallback;

  /// No description provided for @noMatriculeFallback.
  ///
  /// In en, this message translates to:
  /// **'No matricule'**
  String get noMatriculeFallback;

  /// No description provided for @roleLabelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleLabelAdmin;

  /// No description provided for @roleLabelContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get roleLabelContributor;

  /// No description provided for @promoteToRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote to {role}'**
  String promoteToRoleTitle(String role);

  /// No description provided for @promoteUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Promote {name} to {role}?'**
  String promoteUserConfirmBody(String name, String role);

  /// No description provided for @thisUserFallback.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get thisUserFallback;

  /// No description provided for @promoteButton.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promoteButton;

  /// No description provided for @userIsNowRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} is now a {role}'**
  String userIsNowRoleLabel(String name, String role);

  /// No description provided for @globalChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Chat'**
  String get globalChatTitle;

  /// No description provided for @activeNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Now'**
  String get activeNowLabel;

  /// No description provided for @aboutGlobalChatLabel.
  ///
  /// In en, this message translates to:
  /// **'About Global Chat'**
  String get aboutGlobalChatLabel;

  /// No description provided for @connectWithPeersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with your peers'**
  String get connectWithPeersSubtitle;

  /// No description provided for @globalChatDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a real-time chat room for all users of GO-Study specific for this course. Please be respectful and follow community guidelines.'**
  String get globalChatDescription;

  /// No description provided for @gotItButton.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingMessages(String error);

  /// No description provided for @noMessagesYetSayHi.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi!'**
  String get noMessagesYetSayHi;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @sendAMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get sendAMessageHint;

  /// No description provided for @replyingToLabel.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingToLabel(String name);

  /// No description provided for @anonymousFallback.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousFallback;

  /// No description provided for @quickReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Review'**
  String get quickReviewTitle;

  /// No description provided for @aiGeneratedSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-generated document summary'**
  String get aiGeneratedSummarySubtitle;

  /// No description provided for @predictQuestionsBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Predict Questions'**
  String get predictQuestionsBarrierLabel;

  /// No description provided for @predictExamQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Predict Exam Questions'**
  String get predictExamQuestionsTitle;

  /// No description provided for @generatePracticeQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a practice quiz from this document'**
  String get generatePracticeQuizSubtitle;

  /// No description provided for @chooseDifficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose a difficulty level'**
  String get chooseDifficultyLevel;

  /// No description provided for @generateQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Quiz'**
  String get generateQuizButton;

  /// No description provided for @tableOfContentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get tableOfContentsTitle;

  /// No description provided for @navigateThroughDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate through the document'**
  String get navigateThroughDocumentSubtitle;

  /// No description provided for @noBookmarksFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks found in this document'**
  String get noBookmarksFoundMessage;

  /// No description provided for @searchInDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Search in document...'**
  String get searchInDocumentHint;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @chatWithPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat with PDF'**
  String get chatWithPdfTooltip;

  /// No description provided for @downloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadTooltip;

  /// No description provided for @askAnythingAboutDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about this document...'**
  String get askAnythingAboutDocumentHint;

  /// No description provided for @joinDiscussionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Join Discussion'**
  String get joinDiscussionTooltip;

  /// No description provided for @courseDiscussionTitle.
  ///
  /// In en, this message translates to:
  /// **'{code} Discussion'**
  String courseDiscussionTitle(String code);

  /// No description provided for @courseDiscussionRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Course Discussion Room'**
  String get courseDiscussionRoomSubtitle;

  /// No description provided for @noMaterialsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No materials for this course yet.'**
  String get noMaterialsYetMessage;

  /// No description provided for @generalResourcesHeader.
  ///
  /// In en, this message translates to:
  /// **'General Resources'**
  String get generalResourcesHeader;

  /// No description provided for @pastQuestionsAndAnswersHeader.
  ///
  /// In en, this message translates to:
  /// **'Past Questions & Answers'**
  String get pastQuestionsAndAnswersHeader;

  /// No description provided for @pqBadge.
  ///
  /// In en, this message translates to:
  /// **'PQ'**
  String get pqBadge;

  /// No description provided for @ansBadge.
  ///
  /// In en, this message translates to:
  /// **'ANS'**
  String get ansBadge;

  /// No description provided for @docBadge.
  ///
  /// In en, this message translates to:
  /// **'DOC'**
  String get docBadge;

  /// No description provided for @deleteMaterialDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Material?'**
  String get deleteMaterialDialogTitle;

  /// No description provided for @confirmDeleteMaterialBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {title}? This cannot be undone.'**
  String confirmDeleteMaterialBody(String title);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @materialDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Material deleted'**
  String get materialDeletedMessage;

  /// No description provided for @downloadMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadMenuItem;

  /// No description provided for @materialSecuredOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Material secured for offline access! 🔒'**
  String get materialSecuredOfflineMessage;

  /// No description provided for @pastQuestionAnswersCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past Question • {count} Answers'**
  String pastQuestionAnswersCountSubtitle(int count);

  /// No description provided for @deletePastQuestionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Past Question?'**
  String get deletePastQuestionDialogTitle;

  /// No description provided for @pastQuestionDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Past Question deleted'**
  String get pastQuestionDeletedMessage;

  /// No description provided for @noAnswersUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'No answers uploaded yet'**
  String get noAnswersUploadedYet;

  /// No description provided for @verifiedAnswerFeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Answer • {fee} XAF'**
  String verifiedAnswerFeeSubtitle(int fee);

  /// No description provided for @onlyContributorsCanUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'Only contributors and admins can upload content.'**
  String get onlyContributorsCanUploadMessage;

  /// No description provided for @addMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterialTitle;

  /// No description provided for @shareResourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share resources with your peers'**
  String get shareResourcesSubtitle;

  /// No description provided for @generalMaterialOption.
  ///
  /// In en, this message translates to:
  /// **'General Material'**
  String get generalMaterialOption;

  /// No description provided for @pastQuestionOption.
  ///
  /// In en, this message translates to:
  /// **'Past Question'**
  String get pastQuestionOption;

  /// No description provided for @answerOption.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answerOption;

  /// No description provided for @linkToQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Link to Question'**
  String get linkToQuestionLabel;

  /// No description provided for @selectTheQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Select the question'**
  String get selectTheQuestionHint;

  /// No description provided for @requiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidator;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Intro to Java Notes'**
  String get titleHintExample;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @brieflyDescribeContentHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the content'**
  String get brieflyDescribeContentHint;

  /// No description provided for @selectMaterialFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Material File'**
  String get selectMaterialFileLabel;

  /// No description provided for @fileSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File selected successfully'**
  String get fileSelectedSuccessfully;

  /// No description provided for @uploadPdfOrWordHint.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF or Word'**
  String get uploadPdfOrWordHint;

  /// No description provided for @supportsPdfDocImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Supports PDF, DOC, Images'**
  String get supportsPdfDocImagesHint;

  /// No description provided for @uploadMaterialButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Material'**
  String get uploadMaterialButton;

  /// No description provided for @pleaseSelectFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a file'**
  String get pleaseSelectFileMessage;

  /// No description provided for @uploadSuccessfulMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload successful!'**
  String get uploadSuccessfulMessage;

  /// No description provided for @selectMaterialTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the type of material you want to share'**
  String get selectMaterialTypeSubtitle;

  /// No description provided for @lectureNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lecture notes, summaries, textbooks'**
  String get lectureNotesSubtitle;

  /// No description provided for @previousExamPapersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Previous exam or test papers'**
  String get previousExamPapersSubtitle;

  /// No description provided for @solutionsToPastQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solutions to past questions'**
  String get solutionsToPastQuestionsSubtitle;

  /// No description provided for @verifiedAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Answer'**
  String get verifiedAnswerTitle;

  /// No description provided for @communityContributionCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Contribution Code'**
  String get communityContributionCodeTitle;

  /// No description provided for @guidelineReadableContent.
  ///
  /// In en, this message translates to:
  /// **'Ensure content is readable, correct, and fit for study.'**
  String get guidelineReadableContent;

  /// No description provided for @guidelineCheckDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Check if this resource is already uploaded.'**
  String get guidelineCheckDuplicate;

  /// No description provided for @guidelineAcademicOnly.
  ///
  /// In en, this message translates to:
  /// **'Upload only academic and educational materials.'**
  String get guidelineAcademicOnly;

  /// No description provided for @deleteDepartmentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Department?'**
  String get deleteDepartmentDialogTitle;

  /// No description provided for @confirmDeleteDepartmentBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This will delete all courses and materials within it. This action cannot be undone.'**
  String confirmDeleteDepartmentBody(String name);

  /// No description provided for @departmentDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Department deleted'**
  String get departmentDeletedMessage;

  /// No description provided for @deleteDepartmentMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Department'**
  String get deleteDepartmentMenuItem;

  /// No description provided for @aboutTabLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTabLabel;

  /// No description provided for @coursesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get coursesTabLabel;

  /// No description provided for @docsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docsTabLabel;

  /// No description provided for @chatTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTabLabel;

  /// No description provided for @departmentGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Group'**
  String departmentGroupTitle(String name);

  /// No description provided for @departmentalStudyGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Departmental Study Group'**
  String get departmentalStudyGroupSubtitle;

  /// No description provided for @uploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadButton;

  /// No description provided for @aboutDepartmentHeader.
  ///
  /// In en, this message translates to:
  /// **'About Department'**
  String get aboutDepartmentHeader;

  /// No description provided for @descriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHeader;

  /// No description provided for @departmentDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Details and descriptions about this department will appear here. Students can find general information, faculty details, and more.'**
  String get departmentDescriptionPlaceholder;

  /// No description provided for @noCoursesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No courses found!'**
  String get noCoursesFoundMessage;

  /// No description provided for @levelHeader.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelHeader(String level);

  /// No description provided for @otherCoursesHeader.
  ///
  /// In en, this message translates to:
  /// **'Other Courses'**
  String get otherCoursesHeader;

  /// No description provided for @courseDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Course deleted'**
  String get courseDeletedMessage;

  /// No description provided for @deleteCourseMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Course'**
  String get deleteCourseMenuItem;

  /// No description provided for @courseMaterialsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Course Materials'**
  String get courseMaterialsTooltip;

  /// No description provided for @noMaterialsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No materials yet'**
  String get noMaterialsYetShort;

  /// No description provided for @noResourcesAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No resources available'**
  String get noResourcesAvailableMessage;

  /// No description provided for @noPastQuestionsAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No past questions available'**
  String get noPastQuestionsAvailableMessage;

  /// No description provided for @downloadMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Material'**
  String get downloadMaterialTitle;

  /// No description provided for @secureAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure access to study resources'**
  String get secureAccessSubtitle;

  /// No description provided for @downloadFeeNotice.
  ///
  /// In en, this message translates to:
  /// **'To download \"{title}\" ({category}), a fee of {fee} XAF is required.'**
  String downloadFeeNotice(String title, String category, int fee);

  /// No description provided for @paymentPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Phone'**
  String get paymentPhoneLabel;

  /// No description provided for @paymentPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'6xxxxxxxx (MTN/Orange)'**
  String get paymentPhoneHint;

  /// No description provided for @payAndDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Pay & Download'**
  String get payAndDownloadButton;

  /// No description provided for @beFirstToContributeMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to contribute to this department\'s resources!'**
  String get beFirstToContributeMessage;

  /// No description provided for @addNewButton.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNewButton;

  /// No description provided for @addNewCourseMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Course'**
  String get addNewCourseMenuItem;

  /// No description provided for @uploadDepartmentResourceMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Upload Department Resource'**
  String get uploadDepartmentResourceMenuItem;

  /// No description provided for @uploadCourseMaterialMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Upload Course Material'**
  String get uploadCourseMaterialMenuItem;

  /// No description provided for @addCourseFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a course first!'**
  String get addCourseFirstMessage;

  /// No description provided for @uploadPastQuestionMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Upload Past Question'**
  String get uploadPastQuestionMenuItem;

  /// No description provided for @uploadAnswerMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Upload Answer'**
  String get uploadAnswerMenuItem;

  /// No description provided for @selectCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Course'**
  String get selectCourseTitle;

  /// No description provided for @whichCourseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which course is this for?'**
  String get whichCourseSubtitle;

  /// No description provided for @courseLevelCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} • {code}'**
  String courseLevelCodeSubtitle(String level, String code);

  /// No description provided for @deptResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Dept Resource'**
  String get deptResourceTitle;

  /// No description provided for @shareFacultyWideDocsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share faculty-wide documents'**
  String get shareFacultyWideDocsSubtitle;

  /// No description provided for @addResourcesForCourseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add resources for {name}'**
  String addResourcesForCourseSubtitle(String name);

  /// No description provided for @courseFallback.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseFallback;

  /// No description provided for @courseLabelPrefix.
  ///
  /// In en, this message translates to:
  /// **'Course: {name}'**
  String courseLabelPrefix(String name);

  /// No description provided for @generalOption.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalOption;

  /// No description provided for @resourceTitleHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Exam Prep Notes'**
  String get resourceTitleHintExample;

  /// No description provided for @briefResourceDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Brief details about the resource'**
  String get briefResourceDetailsHint;

  /// No description provided for @selectResourceFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Resource File'**
  String get selectResourceFileLabel;

  /// No description provided for @readyForUploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready for upload'**
  String get readyForUploadLabel;

  /// No description provided for @pdfDocImagesOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOC, or Images only'**
  String get pdfDocImagesOnlyHint;

  /// No description provided for @uploadResourceButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Resource'**
  String get uploadResourceButton;

  /// No description provided for @onlyAdminsCanAddCoursesMessage.
  ///
  /// In en, this message translates to:
  /// **'Only administrators can add new courses.'**
  String get onlyAdminsCanAddCoursesMessage;

  /// No description provided for @deleteCourseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Course?'**
  String get deleteCourseDialogTitle;

  /// No description provided for @aiCreditsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Credits Required'**
  String get aiCreditsRequiredTitle;

  /// No description provided for @outOfAiCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'You have run out of AI credits. Upgrade to a premium plan or top up your credits to continue using Gemini Academic.'**
  String get outOfAiCreditsBody;

  /// No description provided for @get50CreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get 50 Credits'**
  String get get50CreditsTitle;

  /// No description provided for @only500XafSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only 500 XAF'**
  String get only500XafSubtitle;

  /// No description provided for @notNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNowButton;

  /// No description provided for @topUpButton.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get topUpButton;

  /// No description provided for @rateUsBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUsBarrierLabel;

  /// No description provided for @rateUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Us!'**
  String get rateUsTitle;

  /// No description provided for @helpUsImproveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Ub-Hub'**
  String get helpUsImproveSubtitle;

  /// No description provided for @rateUsBody.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy using Ub-Hub, please take a moment to rate us. Your feedback is invaluable!'**
  String get rateUsBody;

  /// No description provided for @laterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterButton;

  /// No description provided for @rateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get rateNowButton;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @loveToHearFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'d love to hear from you!'**
  String get loveToHearFromYouTitle;

  /// No description provided for @feedbackBodyText.
  ///
  /// In en, this message translates to:
  /// **'Found a bug? Have a suggestion? Send us an email and help us make Ub-Hub better.'**
  String get feedbackBodyText;

  /// No description provided for @sendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmailButton;

  /// No description provided for @trialPeriodEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial Period Ended'**
  String get trialPeriodEndedTitle;

  /// No description provided for @trialExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your 4-day free access to  GoStudy has expired. Upgrade to a premium plan to unlock your academic dashboard, UB Support Bot, and unlimited materials.'**
  String get trialExpiredBody;

  /// No description provided for @viewUpgradePlansButton.
  ///
  /// In en, this message translates to:
  /// **'View Upgrade Plans'**
  String get viewUpgradePlansButton;

  /// No description provided for @addCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Course'**
  String get addCourseTitle;

  /// No description provided for @organizeAcademicContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your academic content'**
  String get organizeAcademicContentSubtitle;

  /// No description provided for @courseNameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Data Structures'**
  String get courseNameHintExample;

  /// No description provided for @pleaseEnterCourseName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a course name'**
  String get pleaseEnterCourseName;

  /// No description provided for @courseCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Course Code'**
  String get courseCodeLabel;

  /// No description provided for @courseCodeHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. CS201'**
  String get courseCodeHintExample;

  /// No description provided for @pleaseEnterCourseCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a course code'**
  String get pleaseEnterCourseCode;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @selectAcademicLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Select academic level'**
  String get selectAcademicLevelHint;

  /// No description provided for @userNotAuthenticatedMessage.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticatedMessage;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutAppTitle;

  /// No description provided for @appDescriptionBody.
  ///
  /// In en, this message translates to:
  /// **'GO-Study is your ultimate academic companion, specifically tailored for the University of Buea student community. From AI-driven study plans to real-time exam schedules and global peer collaboration, we empower you with the technical tools needed to navigate your academic journey with excellence and ease.'**
  String get appDescriptionBody;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @licensesLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Licenses & Legal'**
  String get licensesLegalTitle;

  /// No description provided for @openSourceLibrariesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open source libraries and legal info'**
  String get openSourceLibrariesSubtitle;

  /// No description provided for @appLegaleseCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Jovial Studio'**
  String get appLegaleseCopyright;

  /// No description provided for @aboutDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'GO-Study is an academic companion designed for students at the University of Buea. It provides easy access to resources, AI-powered study assistance, course management, and peer collaboration tools to help you excel in your academic journey.'**
  String get aboutDialogDescription;

  /// No description provided for @eventsCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Events Calendar'**
  String get eventsCalendarTitle;

  /// No description provided for @eventIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Event ID'**
  String get eventIdLabel;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventNameLabel;

  /// No description provided for @eventCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Category'**
  String get eventCategoryLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @venueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venueLabel;

  /// No description provided for @tbdValue.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbdValue;

  /// No description provided for @eventStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Start Time'**
  String get eventStartTimeLabel;

  /// No description provided for @eventEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event End Time'**
  String get eventEndTimeLabel;

  /// No description provided for @eventStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Status'**
  String get eventStatusLabel;

  /// No description provided for @eventImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Image'**
  String get eventImageLabel;

  /// No description provided for @addCommentButton.
  ///
  /// In en, this message translates to:
  /// **'Add Comment'**
  String get addCommentButton;

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEventTitle;

  /// No description provided for @confirmDeleteEventBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event? All associated data will be permanently removed.'**
  String get confirmDeleteEventBody;

  /// No description provided for @messageSellerButton.
  ///
  /// In en, this message translates to:
  /// **'Message Seller'**
  String get messageSellerButton;

  /// No description provided for @buyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNowButton;

  /// No description provided for @digitalPurchaseComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase flow for specific listings is coming soon!'**
  String get digitalPurchaseComingSoonMessage;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @noQuestionsInQuiz.
  ///
  /// In en, this message translates to:
  /// **'No questions found in this quiz.'**
  String get noQuestionsInQuiz;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @questionCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String questionCounterTitle(int current, int total);

  /// No description provided for @submitAnswerButton.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT ANSWER'**
  String get submitAnswerButton;

  /// No description provided for @greatJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Great Job!'**
  String get greatJobTitle;

  /// No description provided for @keepStudyingTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Studying!'**
  String get keepStudyingTitle;

  /// No description provided for @youScoredOutOfLabel.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} out of {total}'**
  String youScoredOutOfLabel(int score, int total);

  /// No description provided for @accuracyPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Accuracy'**
  String accuracyPercentLabel(int percent);

  /// No description provided for @backToGeneratorButton.
  ///
  /// In en, this message translates to:
  /// **'BACK TO GENERATOR'**
  String get backToGeneratorButton;

  /// No description provided for @materialsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsTabLabel;

  /// No description provided for @practiceTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTabLabel;

  /// No description provided for @selectLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Select a level'**
  String get selectLevelLabel;

  /// No description provided for @startLessonButton.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLessonButton;

  /// No description provided for @checkAnswerButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAnswerButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @matchingInstructionLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap a word on the left, then its match on the right.'**
  String get matchingInstructionLabel;

  /// No description provided for @frenchForEnglishSpeakersTitle.
  ///
  /// In en, this message translates to:
  /// **'French for English Speakers'**
  String get frenchForEnglishSpeakersTitle;

  /// No description provided for @englishForFrenchSpeakersTitle.
  ///
  /// In en, this message translates to:
  /// **'English for French Speakers'**
  String get englishForFrenchSpeakersTitle;

  /// No description provided for @supportDeveloperBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Support Developer'**
  String get supportDeveloperBarrierLabel;

  /// No description provided for @supportTheDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'Support the Developer'**
  String get supportTheDeveloperTitle;

  /// No description provided for @helpKeepProjectAliveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help keep the project alive and growing'**
  String get helpKeepProjectAliveSubtitle;

  /// No description provided for @supportDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your support helps us maintain the infrastructure and add new features. Any amount is appreciated! ❤️'**
  String get supportDialogBody;

  /// No description provided for @amountXafLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (XAF)'**
  String get amountXafLabel;

  /// No description provided for @amountHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get amountHintExample;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @phoneNumberHintPlain.
  ///
  /// In en, this message translates to:
  /// **'6xxxxxxxx'**
  String get phoneNumberHintPlain;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number required'**
  String get phoneNumberRequired;

  /// No description provided for @enterValidCameroonPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Cameroon phone number'**
  String get enterValidCameroonPhone;

  /// No description provided for @supportButton.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportButton;

  /// No description provided for @thankYouForSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your generous support! ❤️'**
  String get thankYouForSupportMessage;

  /// No description provided for @confirmApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Application'**
  String get confirmApplicationTitle;

  /// No description provided for @redirectToWhatsappBody.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to WhatsApp to complete your application with our support team.'**
  String get redirectToWhatsappBody;

  /// No description provided for @couldNotOpenWhatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Please ensure WhatsApp is installed.'**
  String get couldNotOpenWhatsappMessage;

  /// No description provided for @continueToWhatsappButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to WhatsApp'**
  String get continueToWhatsappButton;

  /// No description provided for @transcriptApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript Application'**
  String get transcriptApplicationTitle;

  /// No description provided for @applyNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNowTitle;

  /// No description provided for @requestTranscriptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to request your academic transcript.'**
  String get requestTranscriptSubtitle;

  /// No description provided for @personalInformationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationSectionTitle;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @enterYourNameValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourNameValidator;

  /// No description provided for @whatsappNumberHint.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number (e.g. 6xxxxxxxx)'**
  String get whatsappNumberHint;

  /// No description provided for @enterValidPhoneValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhoneValidator;

  /// No description provided for @enterValidEmailValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmailValidator;

  /// No description provided for @academicDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Details'**
  String get academicDetailsSectionTitle;

  /// No description provided for @matriculeNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Matricule Number'**
  String get matriculeNumberHint;

  /// No description provided for @enterYourMatriculeValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your matricule'**
  String get enterYourMatriculeValidator;

  /// No description provided for @facultyHint.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get facultyHint;

  /// No description provided for @enterYourFacultyValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your faculty'**
  String get enterYourFacultyValidator;

  /// No description provided for @departmentHint.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentHint;

  /// No description provided for @enterYourDepartmentValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your department'**
  String get enterYourDepartmentValidator;

  /// No description provided for @applicationOptionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Options'**
  String get applicationOptionsSectionTitle;

  /// No description provided for @modeOfApplicationHint.
  ///
  /// In en, this message translates to:
  /// **'Mode of Application'**
  String get modeOfApplicationHint;

  /// No description provided for @selectAModeValidator.
  ///
  /// In en, this message translates to:
  /// **'Select a mode'**
  String get selectAModeValidator;

  /// No description provided for @studentStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Student Status'**
  String get studentStatusHint;

  /// No description provided for @selectYourStatusValidator.
  ///
  /// In en, this message translates to:
  /// **'Select your status'**
  String get selectYourStatusValidator;

  /// No description provided for @submitApplicationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplicationButton;

  /// No description provided for @modeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Mode (1200 XAF)'**
  String get modeNormal;

  /// No description provided for @modeFast.
  ///
  /// In en, this message translates to:
  /// **'Fast Mode (2500 XAF)'**
  String get modeFast;

  /// No description provided for @modeSuperFast.
  ///
  /// In en, this message translates to:
  /// **'Super Fast Mode (3500 XAF)'**
  String get modeSuperFast;

  /// No description provided for @statusCurrentStudent.
  ///
  /// In en, this message translates to:
  /// **'Current Student'**
  String get statusCurrentStudent;

  /// No description provided for @statusFormerStudent.
  ///
  /// In en, this message translates to:
  /// **'Former Student'**
  String get statusFormerStudent;

  /// No description provided for @ubKnowledgeBaseTitle.
  ///
  /// In en, this message translates to:
  /// **'UB Knowledge Base'**
  String get ubKnowledgeBaseTitle;

  /// No description provided for @noUbKnowledgeYet.
  ///
  /// In en, this message translates to:
  /// **'No UB knowledge added yet'**
  String get noUbKnowledgeYet;

  /// No description provided for @addUniversityFactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add university facts for the bot to learn!'**
  String get addUniversityFactsSubtitle;

  /// No description provided for @processingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingLabel;

  /// No description provided for @uploadUbPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Upload UB PDF'**
  String get uploadUbPdfButton;

  /// No description provided for @addUbInfoButton.
  ///
  /// In en, this message translates to:
  /// **'Add UB Info'**
  String get addUbInfoButton;

  /// No description provided for @knowledgeScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Scope'**
  String get knowledgeScopeTitle;

  /// No description provided for @knowledgeScopeBody.
  ///
  /// In en, this message translates to:
  /// **'Should this information be available to all students (Global) or just you (Personal)?'**
  String get knowledgeScopeBody;

  /// No description provided for @personalOption.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalOption;

  /// No description provided for @globalOption.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globalOption;

  /// No description provided for @pdfTitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'PDF: {name}'**
  String pdfTitlePrefix(String name);

  /// No description provided for @pdfProcessedMessage.
  ///
  /// In en, this message translates to:
  /// **'PDF processed and added to knowledge base!'**
  String get pdfProcessedMessage;

  /// No description provided for @addUbKnowledgeBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Add UB Knowledge'**
  String get addUbKnowledgeBarrierLabel;

  /// No description provided for @newUniversityInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'New University Info'**
  String get newUniversityInfoTitle;

  /// No description provided for @topicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic (e.g. Admission)'**
  String get topicLabel;

  /// No description provided for @topicHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Faculty of Arts'**
  String get topicHintExample;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @provideUniversityInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Provide university-specific info...'**
  String get provideUniversityInfoHint;

  /// No description provided for @makeGlobalLabel.
  ///
  /// In en, this message translates to:
  /// **'Make Global'**
  String get makeGlobalLabel;

  /// No description provided for @visibleToAllUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible to all users'**
  String get visibleToAllUsersSubtitle;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @addDepartmentBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDepartmentBarrierLabel;

  /// No description provided for @newDepartmentTitle.
  ///
  /// In en, this message translates to:
  /// **'New Department'**
  String get newDepartmentTitle;

  /// No description provided for @expandAcademicEcosystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expand your academic ecosystem'**
  String get expandAcademicEcosystemSubtitle;

  /// No description provided for @departmentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get departmentNameLabel;

  /// No description provided for @departmentNameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Computer Science'**
  String get departmentNameHintExample;

  /// No description provided for @nameRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get nameRequiredValidator;

  /// No description provided for @schoolIdLabel.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get schoolIdLabel;

  /// No description provided for @identifyParentSchoolHint.
  ///
  /// In en, this message translates to:
  /// **'Identify the parent school'**
  String get identifyParentSchoolHint;

  /// No description provided for @schoolIdRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'School ID required'**
  String get schoolIdRequiredValidator;

  /// No description provided for @whatMakesDeptUniqueHint.
  ///
  /// In en, this message translates to:
  /// **'What makes this department unique?'**
  String get whatMakesDeptUniqueHint;

  /// No description provided for @descriptionRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Description required'**
  String get descriptionRequiredValidator;

  /// No description provided for @departmentIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Department Identity'**
  String get departmentIdentityLabel;

  /// No description provided for @uploadCoverPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload cover photo'**
  String get uploadCoverPhotoLabel;

  /// No description provided for @createDepartmentButton.
  ///
  /// In en, this message translates to:
  /// **'Create Department'**
  String get createDepartmentButton;

  /// No description provided for @developerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get developerInfoTitle;

  /// No description provided for @leadDeveloperAtJovialLaps.
  ///
  /// In en, this message translates to:
  /// **'Lead Developer @ Jovial Laps'**
  String get leadDeveloperAtJovialLaps;

  /// No description provided for @engineeringDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Engineering Details'**
  String get engineeringDetailsSection;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @buildNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumberLabel;

  /// No description provided for @frameworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get frameworkLabel;

  /// No description provided for @connectSection.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectSection;

  /// No description provided for @githubLabel.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get githubLabel;

  /// No description provided for @linkedinLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedinLabel;

  /// No description provided for @professionalProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Profile'**
  String get professionalProfileSubtitle;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmailLabel;

  /// No description provided for @directLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Direct Line'**
  String get directLineLabel;

  /// No description provided for @builtWithLoveForUbStudents.
  ///
  /// In en, this message translates to:
  /// **'Built with ❤️ for UB Students'**
  String get builtWithLoveForUbStudents;

  /// No description provided for @clearAllNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotificationsTitle;

  /// No description provided for @confirmClearAllNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This will permanently remove your recent activity history.'**
  String get confirmClearAllNotificationsBody;

  /// No description provided for @clearAllButtonShort.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButtonShort;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsTitle;

  /// No description provided for @receiveAlertsNewCoursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts for new courses'**
  String get receiveAlertsNewCoursesSubtitle;

  /// No description provided for @emailUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Updates'**
  String get emailUpdatesTitle;

  /// No description provided for @receiveDigestEmailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive digest emails'**
  String get receiveDigestEmailsSubtitle;

  /// No description provided for @studyRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Reminders'**
  String get studyRemindersTitle;

  /// No description provided for @dailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to stay on track'**
  String get dailyReminderSubtitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityTitle;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found'**
  String get noNotificationsFound;

  /// No description provided for @createNewEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Event'**
  String get createNewEventTitle;

  /// No description provided for @editEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEventTitle;

  /// No description provided for @eventNameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Computer Science Final'**
  String get eventNameHintExample;

  /// No description provided for @venueHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amphi 700'**
  String get venueHintExample;

  /// No description provided for @eventDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Description'**
  String get eventDescriptionLabel;

  /// No description provided for @addAdditionalDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional details...'**
  String get addAdditionalDetailsHint;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @upcomingExamNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Exam: {name}'**
  String upcomingExamNotificationTitle(String name);

  /// No description provided for @examVenueTimeNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Venue: {venue} @ {time}'**
  String examVenueTimeNotificationBody(String venue, String time);

  /// No description provided for @categoryMidterm.
  ///
  /// In en, this message translates to:
  /// **'Midterm'**
  String get categoryMidterm;

  /// No description provided for @categoryFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get categoryFinal;

  /// No description provided for @categoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get categoryQuiz;

  /// No description provided for @categoryAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get categoryAssignment;

  /// No description provided for @categoryPractical.
  ///
  /// In en, this message translates to:
  /// **'Practical'**
  String get categoryPractical;

  /// No description provided for @categoryPresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get categoryPresentation;

  /// No description provided for @unlimitedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedLabel;

  /// No description provided for @daysRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String daysRemainingLabel(int days);

  /// No description provided for @endingTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending today'**
  String get endingTodayLabel;

  /// No description provided for @currentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalanceLabel;

  /// No description provided for @creditsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{credits} Credits'**
  String creditsCountLabel(int credits);

  /// No description provided for @topUpAiCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up AI Credits'**
  String get topUpAiCreditsTitle;

  /// No description provided for @creditsUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Credits are used for Gemini AI interactions. Core academic tools remain free for everyone.'**
  String get creditsUsageSubtitle;

  /// No description provided for @fapshiTestModeLabel.
  ///
  /// In en, this message translates to:
  /// **'FAPSHI TEST MODE'**
  String get fapshiTestModeLabel;

  /// No description provided for @fapshiTestModeBody.
  ///
  /// In en, this message translates to:
  /// **'Test payment integration with the Fapshi Sandbox (100 XAF). Adds 10 test credits.'**
  String get fapshiTestModeBody;

  /// No description provided for @pay100XafTestButton.
  ///
  /// In en, this message translates to:
  /// **'Pay 100 XAF (Test)'**
  String get pay100XafTestButton;

  /// No description provided for @starterPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Starter Pack'**
  String get starterPackTitle;

  /// No description provided for @studentPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Pack'**
  String get studentPackTitle;

  /// No description provided for @mostPopularLabel.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopularLabel;

  /// No description provided for @creditsCountAiLabel.
  ///
  /// In en, this message translates to:
  /// **'{credits} AI Credits'**
  String creditsCountAiLabel(int credits);

  /// No description provided for @unlimitedAiSubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Subscriptions'**
  String get unlimitedAiSubscriptionsTitle;

  /// No description provided for @unlimitedMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Monthly'**
  String get unlimitedMonthlyTitle;

  /// No description provided for @featureUnlimitedGeminiChat.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Gemini AI Chat'**
  String get featureUnlimitedGeminiChat;

  /// No description provided for @featureUnlimitedPdfSummaries.
  ///
  /// In en, this message translates to:
  /// **'Unlimited PDF Summaries'**
  String get featureUnlimitedPdfSummaries;

  /// No description provided for @featurePriorityAiResponse.
  ///
  /// In en, this message translates to:
  /// **'Priority AI Response'**
  String get featurePriorityAiResponse;

  /// No description provided for @featureAiStudyPlanGenerator.
  ///
  /// In en, this message translates to:
  /// **'AI Study Plan Generator'**
  String get featureAiStudyPlanGenerator;

  /// No description provided for @featureStructureQuizGenerator.
  ///
  /// In en, this message translates to:
  /// **'Structure Quiz Generator'**
  String get featureStructureQuizGenerator;

  /// No description provided for @appPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'App Plan'**
  String get appPlanTitle;

  /// No description provided for @appPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited downloads and priority support. Separate from AI credits/subscription above.'**
  String get appPlanSubtitle;

  /// No description provided for @pricePerMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'{price} XAF / month'**
  String pricePerMonthLabel(int price);

  /// No description provided for @currentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanButton;

  /// No description provided for @getUnlimitedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Unlimited'**
  String get getUnlimitedButton;

  /// No description provided for @trialActiveLeftBadge.
  ///
  /// In en, this message translates to:
  /// **'TRIAL ACTIVE • {time} LEFT'**
  String trialActiveLeftBadge(String time);

  /// No description provided for @currentPlanBadge.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlanBadge;

  /// No description provided for @firstMonthFreeBadge.
  ///
  /// In en, this message translates to:
  /// **'FIRST MONTH FREE'**
  String get firstMonthFreeBadge;

  /// No description provided for @startFreeTrialButton.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrialButton;

  /// No description provided for @subscribeButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeButton;

  /// No description provided for @freeMonthThenPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Free for 1 month, then {price} XAF / month'**
  String freeMonthThenPriceLabel(int price);

  /// No description provided for @aiFeaturesBilledSeparatelyShort.
  ///
  /// In en, this message translates to:
  /// **'AI features are billed separately and not included.'**
  String get aiFeaturesBilledSeparatelyShort;

  /// No description provided for @startYourFreeMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Your Free Month'**
  String get startYourFreeMonthTitle;

  /// No description provided for @noPaymentRequiredTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No payment required today'**
  String get noPaymentRequiredTodaySubtitle;

  /// No description provided for @freeTrialTermsBody.
  ///
  /// In en, this message translates to:
  /// **'Your App Plan is free for the first 30 days, then renews at {price} XAF/month. AI features are billed separately and are not included in this trial.'**
  String freeTrialTermsBody(int price);

  /// No description provided for @freeTrialActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Free trial activated!'**
  String get freeTrialActivatedMessage;

  /// No description provided for @buyCreditsBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Buy Credits'**
  String get buyCreditsBarrierLabel;

  /// No description provided for @buyPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy {packName}'**
  String buyPackTitle(String packName);

  /// No description provided for @addCreditsToBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add {credits} credits to your balance'**
  String addCreditsToBalanceSubtitle(int credits);

  /// No description provided for @enterMomoNumberToPayBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your MoMo/OM number to pay {amount} XAF.'**
  String enterMomoNumberToPayBody(int amount);

  /// No description provided for @phoneNumberHintUppercase.
  ///
  /// In en, this message translates to:
  /// **'6XXXXXXXX'**
  String get phoneNumberHintUppercase;

  /// No description provided for @payNowButton.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNowButton;

  /// No description provided for @completePaymentInBrowserShort.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in browser...'**
  String get completePaymentInBrowserShort;

  /// No description provided for @waitingForApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval...'**
  String get waitingForApprovalMessage;

  /// No description provided for @creditsAddedSuccessfullyMessage.
  ///
  /// In en, this message translates to:
  /// **'{credits} credits added successfully!'**
  String creditsAddedSuccessfullyMessage(int credits);

  /// No description provided for @contributorBadge.
  ///
  /// In en, this message translates to:
  /// **'CONTRIBUTOR'**
  String get contributorBadge;

  /// No description provided for @beACreatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Be a Creator'**
  String get beACreatorTitle;

  /// No description provided for @contributorUploadBody.
  ///
  /// In en, this message translates to:
  /// **'Upload your own materials, earn from downloads, and unlock everything forever.'**
  String get contributorUploadBody;

  /// No description provided for @includedWithAdminContributor.
  ///
  /// In en, this message translates to:
  /// **'Included with Admin/Contributor'**
  String get includedWithAdminContributor;

  /// No description provided for @oneTimePayment5000Xaf.
  ///
  /// In en, this message translates to:
  /// **'One-time Payment 5000 XAF'**
  String get oneTimePayment5000Xaf;

  /// No description provided for @subscribeToTierTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to {tierName}'**
  String subscribeToTierTitle(String tierName);

  /// No description provided for @unlockPremiumToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium academic tools'**
  String get unlockPremiumToolsSubtitle;

  /// No description provided for @enterMomoForDaysBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your Mobile Money number to pay {amount} XAF for {days} days of access.'**
  String enterMomoForDaysBody(int amount, int days);

  /// No description provided for @completePaymentBrowserTip.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the browser window.\n\nTip: Stay on the Fapshi page until the USSD prompt appears on your phone.'**
  String get completePaymentBrowserTip;

  /// No description provided for @checkPhoneMomoPromptTip.
  ///
  /// In en, this message translates to:
  /// **'Check your phone for a MoMo prompt.\n\nMTN: Keep screen unlocked.\nOrange: Dial #150*50# if prompted for an OTP.'**
  String get checkPhoneMomoPromptTip;

  /// No description provided for @subscriptionActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated!'**
  String get subscriptionActivatedMessage;

  /// No description provided for @upgradeToContributorTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Contributor'**
  String get upgradeToContributorTitle;

  /// No description provided for @unlockEverythingForeverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock everything forever'**
  String get unlockEverythingForeverSubtitle;

  /// No description provided for @contributorUpgradeTermsBody.
  ///
  /// In en, this message translates to:
  /// **'Pay 5000 XAF once to unlock unlimited downloads, uploads, and all premium features forever.'**
  String get contributorUpgradeTermsBody;

  /// No description provided for @momoOmNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Momo/OM Number'**
  String get momoOmNumberLabel;

  /// No description provided for @youAreNowContributorMessage.
  ///
  /// In en, this message translates to:
  /// **'You are now a Contributor!'**
  String get youAreNowContributorMessage;

  /// No description provided for @testCreditsPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Credits'**
  String get testCreditsPackTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
