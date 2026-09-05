// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPage1Title => 'Let\'s get\nStarted';

  @override
  String get onboardingPage1Body =>
      'Set up your academic journey in a structured space built for students, departments, and shared study resources.';

  @override
  String get onboardingPage2Title => 'Get to\nKnow';

  @override
  String get onboardingPage2Body =>
      'Find your institution, explore its schools and departments, and move quickly into the right courses and materials.';

  @override
  String get onboardingPage3Title => 'Study\nTogether';

  @override
  String get onboardingPage3Body =>
      'Use department pages, group chat, notes, and shared content to collaborate with classmates without friction.';

  @override
  String get onboardingPage4Title => 'Learn\nSmarter';

  @override
  String get onboardingPage4Body =>
      'Track tasks, prepare for exams, use AI support, and stay organized with tools designed for an academic workflow.';

  @override
  String get signInWelcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to continue your academic journey.';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get emailAddressHint => 'Email Address';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get minimumSixCharacters => 'Minimum 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signInButton => 'Sign In';

  @override
  String get orDivider => 'OR';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get registerTitle => 'Student Registration';

  @override
  String get registerSubtitle =>
      'Create your account in four guided steps designed for the academic workflow.';

  @override
  String registerStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get registerBack => 'Back';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerComplete => 'Complete Registration';

  @override
  String get registerVerificationRequired => 'VERIFICATION REQUIRED';

  @override
  String get alreadyRegistered => 'Already registered?';

  @override
  String get signInToPortal => 'Sign In to Portal';

  @override
  String get accountStepTitle => 'Account';

  @override
  String get accountStepDescription =>
      'Secure your academic profile with a strong email and password.';

  @override
  String get accountCredentialsTitle => 'Account credentials';

  @override
  String get accountCredentialsSubtitle =>
      'This section protects your portal access and your study records.';

  @override
  String get academicEmailLabel => 'Academic Email';

  @override
  String get academicEmailHint => 'student@university.edu';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get securePasswordLabel => 'Secure Password';

  @override
  String get enterStrongPasswordHint => 'Enter strong password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get minimumEightCharacters => 'Minimum 8 characters';

  @override
  String get addUppercaseLetter => 'Add at least one uppercase letter';

  @override
  String get addDigit => 'Add at least one digit';

  @override
  String get addSpecialCharacter => 'Add a special character';

  @override
  String get passwordSecurityLabel => 'Password Security';

  @override
  String get passwordStrengthHint =>
      'Use a mix of uppercase letters, numbers, and symbols.';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get repeatPasswordHint => 'Repeat password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get identityStepTitle => 'Identity';

  @override
  String get identityStepDescription =>
      'Add your real name and contact details so the community can identify you.';

  @override
  String get personalIdentityTitle => 'Personal identity';

  @override
  String get personalIdentitySubtitle =>
      'This section makes your profile recognizable to classmates and admins.';

  @override
  String get fullLegalNameLabel => 'Full Legal Name';

  @override
  String get firstLastNameHint => 'First and Last Name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get phoneContactLabel => 'Phone Contact';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get academicStepTitle => 'Academic';

  @override
  String get academicStepDescription =>
      'Add your matricule and academic level to unlock the right resources.';

  @override
  String get academicAffiliationTitle => 'Academic affiliation';

  @override
  String get academicAffiliationSubtitle =>
      'This links your account to the correct educational track.';

  @override
  String get studentMatriculeLabel => 'Student Matricule';

  @override
  String get officialUniversityIdHint => 'Official University ID';

  @override
  String get matriculeRequired => 'Matricule is required';

  @override
  String get currentAcademicLevelLabel => 'Current Academic Level';

  @override
  String get selectYourLevelHint => 'Select your level';

  @override
  String get pleaseSelectLevel => 'Please select a level';

  @override
  String get academicLevelResit => 'Resit';

  @override
  String get finalizeStepTitle => 'Finalize';

  @override
  String get finalizeStepDescription =>
      'Add a short academic bio and accept our terms to complete your profile.';

  @override
  String get finalizeProfileTitle => 'Finalize profile';

  @override
  String get finalizeProfileSubtitle =>
      'This is the last step before your study account is ready.';

  @override
  String get academicBioLabel => 'Academic Bio';

  @override
  String get academicBioHint => 'Briefly describe your academic interests...';

  @override
  String get agreeToTermsPrefix => 'I agree to the ';

  @override
  String get termsOfServiceLink => 'Terms of Service';

  @override
  String get andSeparator => ' and ';

  @override
  String get privacyPolicyLink => 'Privacy Policy';

  @override
  String get agreeToTermsRequired =>
      'You must accept the Terms of Service and Privacy Policy to continue';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountProfileTitle => 'Account Profile';

  @override
  String get accountProfileSubtitle =>
      'View and edit your personal information';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminDashboardSubtitle => 'Manage users, roles, and departments';

  @override
  String get aiCreditsPlansTitle => 'AI Credits & Plans';

  @override
  String aiCreditsRemaining(int count) {
    return '$count Credits remaining';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Manage your alerts and message preferences';

  @override
  String get darkModeTitle => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Switch between light and dark themes';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we protect and use your data';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'The rules for using GO Study';

  @override
  String get supportGoStudyTitle => 'Support Go Study';

  @override
  String get supportGoStudySubtitle =>
      'Sponsor development or volunteer to help';

  @override
  String get supportOptionsDialogBody =>
      'Choose how you\'d like to support development.';

  @override
  String get chatOnWhatsAppButton => 'Chat on WhatsApp';

  @override
  String get donateViaAppButton => 'Donate via App';

  @override
  String get sendFeedbackTitle => 'Send Feedback';

  @override
  String get sendFeedbackSubtitle => 'Report a bug or suggest an improvement';

  @override
  String get developerInformationTitle => 'Developer Information';

  @override
  String get developerInformationSubtitle =>
      'App version, build, and engineering details';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutSubtitle => 'Learn more about the application ';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountDialogTitle => 'Delete your account?';

  @override
  String get deleteAccountDialogBody =>
      'This permanently deletes your account and all your data — profile, tasks, grades, exams, payment history, and chat history. This cannot be undone.';

  @override
  String get deleteAccountTypeToConfirm => 'Type DELETE to confirm.';

  @override
  String get deleteAccountConfirmButton => 'Delete Forever';

  @override
  String deleteAccountFailed(String error) {
    return 'Couldn\'t delete your account: $error';
  }

  @override
  String get appLanguageTitle => 'Language';

  @override
  String get appLanguageSubtitle => 'Choose your preferred app language';

  @override
  String get languageSystemDefault => 'System Default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get homeToolAiStudy => 'AI Study';

  @override
  String get homeToolExamSchedule => 'Exam Schedule';

  @override
  String get homeToolPerformance => 'Performance';

  @override
  String get homeToolLibrary => 'Library';

  @override
  String get homeToolNews => 'News';

  @override
  String get homeToolMarketplace => 'Marketplace';

  @override
  String get homeToolTaskManager => 'Task Manager';

  @override
  String get homeToolFocusTimer => 'Focus Timer';

  @override
  String get homeToolTranscripts => 'Transcripts';

  @override
  String get homeToolPortal => 'PORTAL';

  @override
  String get homeToolSupportBot => 'UB Support Bot';

  @override
  String get homeToolOfflineAi => 'Offline AI';

  @override
  String get gemmaChatTitle => 'Offline AI Chat';

  @override
  String get gemmaChatDownloadTitle => 'Chat offline, for free';

  @override
  String get gemmaChatDownloadBody =>
      'Download a one-time AI model (~530 MB) to chat with an AI tutor with no internet connection and no AI credits used. Wi-Fi is recommended.';

  @override
  String get gemmaChatDownloadButton => 'Download';

  @override
  String gemmaChatDownloadProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gemmaChatDownloadCancelButton => 'Cancel';

  @override
  String gemmaChatDownloadFailedBody(String error) {
    return 'Download failed: $error';
  }

  @override
  String get gemmaChatRetryButton => 'Retry';

  @override
  String get gemmaChatRemoveModelTitle => 'Remove offline AI?';

  @override
  String get gemmaChatRemoveModelBody =>
      'This deletes the downloaded model from your device. You can download it again anytime.';

  @override
  String get gemmaChatRemoveButton => 'Remove';

  @override
  String get gemmaChatRemoveMenuLabel => 'Remove downloaded model';

  @override
  String get gemmaChatEmptyStateTitle => 'Ask me anything, offline';

  @override
  String get gemmaChatEmptyStateBody => 'No internet needed. No credits used.';

  @override
  String get gemmaChatInputHint => 'Message offline AI…';

  @override
  String get gemmaChatUnavailableTitle => 'Not available on this device';

  @override
  String get gemmaChatUnavailableBody =>
      'Offline AI currently requires Android. iOS support is planned.';

  @override
  String get gemmaChatInfoDialogTitle => 'Before you download';

  @override
  String get gemmaChatInfoDialogConfirm => 'I understand, download';

  @override
  String get gemmaChatInfoStorageTitle => 'Storage';

  @override
  String get gemmaChatInfoStorageBody =>
      'Uses about 530 MB of your phone\'s storage, permanently, until you remove it from this screen.';

  @override
  String get gemmaChatInfoRamTitle => 'Memory (RAM)';

  @override
  String get gemmaChatInfoRamBody =>
      'Needs extra memory while you\'re chatting — works best on phones with at least 4 GB of RAM. Older or low-RAM phones may slow down while offline AI is in use.';

  @override
  String get gemmaChatInfoPerformanceTitle => 'Performance';

  @override
  String get gemmaChatInfoPerformanceBody =>
      'Responses are generated on your phone\'s own processor, so replies can be slower than the online AI tutor and may use more battery while chatting.';

  @override
  String get gemmaChatInfoAccuracyTitle => 'Accuracy';

  @override
  String get gemmaChatInfoAccuracyBody =>
      'This is a smaller, lighter AI model built to run offline. Its answers can sometimes be incomplete or incorrect — always double-check anything important.';

  @override
  String get gemmaChatInfoDeviceTitle => 'Is your phone ready?';

  @override
  String get gemmaChatInfoDeviceBody =>
      'Only download this if your phone is a reasonably recent, mid-range or higher device with enough free storage. On older or budget phones, offline AI may run slowly or affect the rest of the app\'s performance.';

  @override
  String get sectionUniversities => 'Universities';

  @override
  String get noUniversitiesAvailable => 'No universities available yet.';

  @override
  String get switchUniversityTitle => 'Switch university?';

  @override
  String switchUniversityBody(String name) {
    return 'Switching to $name will change your available departments and course content. Continue?';
  }

  @override
  String get switchUniversityConfirmButton => 'Switch';

  @override
  String aboutInstitutionTooltip(String name) {
    return 'About $name';
  }

  @override
  String get institutionTypeUniversityBadge => 'University';

  @override
  String get seeAllButton => 'See all';

  @override
  String get sectionDepartmentsFaculties => 'Departments & Faculties';

  @override
  String get sectionTools => 'TOOLS';

  @override
  String get noDepartmentsAvailable => 'No departments available yet.';

  @override
  String get exploreResources => 'Explore Resources';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String get scholarFallbackName => 'Scholar';

  @override
  String homeTrialLabel(String time) {
    return 'Trial: $time';
  }

  @override
  String get resumeLearningLabel => 'Resume Learning';

  @override
  String get studentFallbackName => 'Student';

  @override
  String get unifiedAcademicPortal => 'Unified Academic Portal';

  @override
  String get noConnectionTitle => 'No Connection';

  @override
  String get noConnectionBody => 'Please check your internet and try again.';

  @override
  String get retryButton => 'Retry';

  @override
  String get globalChatTooltip => 'Global Chat';

  @override
  String get examSchedulePleaseSignIn =>
      'Please sign in to view your schedule.';

  @override
  String get allEventsListTitle => 'All Events List';

  @override
  String get noEventsScheduled => 'No events scheduled yet.';

  @override
  String get tbd => 'TBD';

  @override
  String get pleaseSignInMessage => 'Please sign in';

  @override
  String get addTaskDialogTitle => 'Add Task';

  @override
  String get newTaskTitle => 'New Task';

  @override
  String get newTaskSubtitle => 'What needs to be done?';

  @override
  String get taskNameLabel => 'Task Name';

  @override
  String get taskNameHint => 'e.g. Study Physics';

  @override
  String get taskDescriptionLabel => 'Description';

  @override
  String get taskDescriptionHint => 'Brief details...';

  @override
  String get deadlineLabel => 'Deadline';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String taskProgressLabel(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get priorityLabel => 'Priority';

  @override
  String get selectPriorityHint => 'Select priority';

  @override
  String get categoryLabel => 'Category';

  @override
  String get selectCategoryHint => 'Select category';

  @override
  String get createTaskButton => 'Create Task';

  @override
  String get taskReminderNotifTitle => 'Task Reminder';

  @override
  String taskReminderNotifBody(String title) {
    return 'Don\'t forget: $title';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryAcademic => 'Academic';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryResearch => 'Research';

  @override
  String get categorySideProjects => 'Side projects';

  @override
  String get toDoListTitle => 'To-Do List';

  @override
  String get searchTasksHint => 'Search tasks...';

  @override
  String get noTasksFound => 'No tasks found';

  @override
  String get taskGroupOverdue => 'Overdue';

  @override
  String get taskGroupToday => 'Today';

  @override
  String get taskGroupUpcoming => 'Upcoming';

  @override
  String get taskGroupCompleted => 'Completed';

  @override
  String get noDeadlineLabel => 'No Deadline';

  @override
  String deadlineDisplay(String date) {
    return 'Deadline: $date';
  }

  @override
  String get focusCompleteNotifTitle => 'Focus Complete!';

  @override
  String get focusCompleteNotifBody => 'Great job! Take a short break.';

  @override
  String get focusModeTitle => 'Focus Mode';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get focusStatusFocusing => 'FOCUSING';

  @override
  String get focusStatusIdle => 'IDLE';

  @override
  String get focusPause => 'PAUSE';

  @override
  String get focusEngage => 'ENGAGE';

  @override
  String get focusReset => 'RESET';

  @override
  String get customizeTimerTitle => 'Customize Timer';

  @override
  String get quickPresetsLabel => 'QUICK PRESETS';

  @override
  String get customDurationLabel => 'CUSTOM DURATION';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get applyAndClose => 'Apply & Close';

  @override
  String get offlineLibraryTitle => 'Offline Library';

  @override
  String get offlineLibraryEmptyTitle => 'Your offline library is empty.';

  @override
  String get offlineLibraryEmptyBody =>
      'Download materials to access them without data.';

  @override
  String localCopySuffix(String category) {
    return '$category • Local Copy';
  }

  @override
  String get offlineFormatNotSupported =>
      'Format not supported for offline viewing yet';

  @override
  String get deleteOfflineCopyTitle => 'Delete Offline Copy?';

  @override
  String get removeFromDeviceSubtitle => 'Remove from device';

  @override
  String deleteOfflineCopyBody(String title) {
    return 'This will remove the secured copy of \'$title\' from your device. You can re-download it anytime you\'re online.';
  }

  @override
  String get deleteNowButton => 'Delete Now';

  @override
  String get universityNewsTitle => 'University News';

  @override
  String get refreshNewsTooltip => 'Refresh News';

  @override
  String get couldntFetchNews => 'Couldn\'t fetch news';

  @override
  String get unexpectedErrorTryLater =>
      'An unexpected error occurred. Please try again later.';

  @override
  String get noAnnouncementsYet => 'No announcements yet.';

  @override
  String get readFullArticle => 'Read Full Article';

  @override
  String get performanceTrackerTitle => 'Performance Tracker';

  @override
  String get switchToListTooltip => 'Switch to List';

  @override
  String get switchToPredictorTooltip => 'Switch to Predictor';

  @override
  String get addGradeButton => 'Add Grade';

  @override
  String get currentGpaLabel => 'Current GPA';

  @override
  String get totalCreditsLabel => 'Total Credits';

  @override
  String get gradePredictorTitle => 'Grade Predictor';

  @override
  String get targetGpaLabel => 'Target GPA';

  @override
  String get plannedCreditsLabel => 'Planned Credits';

  @override
  String get adviceImpossibleTarget =>
      'Mathematically impossible this semester. Try a lower target.';

  @override
  String get adviceOnTrack =>
      'You\'re doing great! Even a low grade will maintain your goal.';

  @override
  String adviceNeedAverage(String grade, String target) {
    return 'You need an average of $grade to reach $target.';
  }

  @override
  String get semesterResultsTitle => 'Semester Results';

  @override
  String coursesCount(int count) {
    return '$count Courses';
  }

  @override
  String get noGradesSavedYet =>
      'No grades saved yet. Use the \'+\' button to add your results.';

  @override
  String creditsAndSemester(int credits, String semester) {
    return '$credits Credits • $semester';
  }

  @override
  String get unknownSemester => 'Unknown Semester';

  @override
  String get addResultDialogTitle => 'Add Result';

  @override
  String get addResultDialogSubtitle => 'Record your academic success';

  @override
  String get courseNameLabel => 'Course Name';

  @override
  String get courseNameHint => 'e.g. CSC 201';

  @override
  String get creditsLabel => 'Credits';

  @override
  String get selectCreditsHint => 'Select credits';

  @override
  String get gradeLabel => 'Grade';

  @override
  String get selectGradeHint => 'Select grade';

  @override
  String get semesterLabel => 'Semester';

  @override
  String get selectSemesterHint => 'Select semester';

  @override
  String get firstSemester => 'First Semester';

  @override
  String get secondSemester => 'Second Semester';

  @override
  String get saveResultButton => 'Save Result';

  @override
  String get aiStudyPlanTitle => 'AI Study Plan';

  @override
  String get regeneratePlanTooltip => 'Regenerate Plan';

  @override
  String get aiAnalyzingSchedule => 'AI is analyzing your schedule...';

  @override
  String get readyForSmarterStudyTitle => 'Ready for a Smarter Study Session?';

  @override
  String get readyForSmarterStudyBody =>
      'I\'ll analyze your pending tasks and upcoming exams to create a balanced routine just for you.';

  @override
  String get generateMyPlanButton => 'GENERATE MY PLAN';

  @override
  String get aiPlanDisclaimer =>
      'This plan is AI-generated and for guidance only.';

  @override
  String get supportBotWelcomeMessage =>
      'Welcome to the University of Buea Support Center! I am your UB Support Bot. How can I help you with university-related inquiries today?';

  @override
  String get supportBotConnectionTrouble =>
      'I\'m sorry, I\'m having trouble connecting right now. Please check your internet or try again later.';

  @override
  String get connectionInterrupted => 'Connection interrupted.';

  @override
  String get universityOfBueaAssistant => 'University of Buea Assistant';

  @override
  String get manageKnowledgeTooltip => 'Manage Knowledge';

  @override
  String get askBasedOnDataHint => 'Ask based on your data...';

  @override
  String get failedToLoadChatHistory =>
      'Failed to load chat history. Please check your connection.';

  @override
  String get newFileAnalysisTitle => 'New File Analysis';

  @override
  String get messageSyncFailed =>
      'Message sync failed. Local history may be out of date.';

  @override
  String get outOfAiCreditsMessage => 'You are out of AI credits.';

  @override
  String get aiThinkingPlaceholder =>
      'I\'m analyzing your request and processing the information to provide a comprehensive answer...';

  @override
  String sorryEncounteredError(String error) {
    return 'Sorry, I encountered an error: $error';
  }

  @override
  String sorryEncounteredCriticalError(String error) {
    return 'Sorry, I encountered a critical error: $error';
  }

  @override
  String get deleteChatDialogTitle => 'Delete Chat';

  @override
  String get deleteChatDialogSubtitle => 'This action cannot be undone';

  @override
  String get deleteChatConfirmBody =>
      'Are you sure you want to delete this conversation? All messages will be permanently removed.';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get howCanIHelpTodayMessage => 'How can I help you today?';

  @override
  String get quickStarterFlashcards => 'Create flashcards from a file';

  @override
  String get quickStarterExplainConcept => 'Explain a concept';

  @override
  String get quickStarterLearningSession => 'Start a learning session';

  @override
  String get thinkingLabel => 'Thinking';

  @override
  String get stopButton => 'Stop';

  @override
  String get askAiHint => 'Ask AI';

  @override
  String get newChatButton => 'New Chat';

  @override
  String get noRecentChats => 'No recent chats';

  @override
  String get clearAllChatsListTile => 'Clear all chats';

  @override
  String get clearAllChatsDialogTitle => 'Clear All Chats';

  @override
  String get clearAllChatsDialogSubtitle => 'Start with a clean slate';

  @override
  String get clearAllChatsConfirmBody =>
      'Are you sure you want to delete all conversations? This action will permanently remove your entire chat history.';

  @override
  String get clearAllButton => 'Clear All';

  @override
  String get showThinkingLabel => 'Show Thinking';

  @override
  String get assistantBetaBadge => 'BETA';

  @override
  String get assistantStatusActive => 'Active';

  @override
  String get assistantStatusOffline => 'Not downloaded';

  @override
  String get assistantStudyHint => 'What do you want to study?';

  @override
  String get assistantChatHistoryLabel => 'Chat history';

  @override
  String get assistantWelcomeGreeting =>
      'Hi! How can I help you today? You can create flashcards, review your material, or learn something new.';

  @override
  String assistantMessagesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can send up to $count more messages',
      one: 'You can send 1 more message',
    );
    return '$_temp0';
  }

  @override
  String get codeCopiedToClipboard => 'Code copied to clipboard';

  @override
  String get copyButton => 'Copy';

  @override
  String get privateChatTitle => 'Private Chat';

  @override
  String get privateMessageSubtitle => 'Private Message';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get tryAgainButton => 'Try Again';

  @override
  String get noQuestionsFound => 'No questions found.';

  @override
  String correctAnswerLabel(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get reloadButton => 'Reload';

  @override
  String get navHomeLabel => 'Home';

  @override
  String get navDepartmentsLabel => 'Departments';

  @override
  String get navAiAssistantLabel => 'AI Assistant';

  @override
  String get navMessagesLabel => 'Messages';

  @override
  String get navSettingsLabel => 'Settings';

  @override
  String get studentPortalTitle => 'Student Portal';

  @override
  String get syncingAcademicDataLabel => 'Syncing Academic Data...';

  @override
  String get reloadPageMenuItem => 'Reload Page';

  @override
  String get copyPortalLinkMenuItem => 'Copy Portal Link';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get openInExternalBrowserMenuItem => 'Open in External Browser';

  @override
  String get allDepartmentsTitle => 'All Departments';

  @override
  String get allToolsTitle => 'All Tools';

  @override
  String get searchForDepartmentHint => 'Search for a department...';

  @override
  String get newDeptButton => 'New Dept';

  @override
  String get findFriendsTitle => 'Find Friends';

  @override
  String get searchByNameHint => 'Search by name…';

  @override
  String get searchForStudentsToAdd => 'Search for students to add';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get friendsStatusChip => 'Friends';

  @override
  String get pendingStatusChip => 'Pending';

  @override
  String get requestedYouStatusChip => 'Requested you';

  @override
  String get addFriendButton => 'Add';

  @override
  String get unknownUserName => 'Unknown';

  @override
  String get findFriendsTooltip => 'Find friends';

  @override
  String pendingCountLabel(int count) {
    return '$count pending';
  }

  @override
  String get friendRequestsLabel => 'Friend Requests';

  @override
  String get noFriendsYetTitle => 'No friends yet';

  @override
  String get tapIconToFindFriends =>
      'Tap the icon above to find\nand add fellow students';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get sendMessageLabel => 'Send Message';

  @override
  String get removeFriendLabel => 'Remove Friend';

  @override
  String get noMessagesYetLabel => 'No messages yet';

  @override
  String get acceptTooltip => 'Accept';

  @override
  String get declineTooltip => 'Decline';

  @override
  String get profileTitle => 'Profile';

  @override
  String get defaultUserName => 'User';

  @override
  String get betaMemberBadge => 'BETA MEMBER';

  @override
  String get openAdminDashboardButton => 'Open Admin Dashboard';

  @override
  String trialEndsInLabel(String time) {
    return 'Trial Ends in: $time';
  }

  @override
  String get personalInformationTitle => 'Personal Information';

  @override
  String get notSetValue => 'Not set';

  @override
  String get matriculeLabel => 'Matricule';

  @override
  String get notProvidedValue => 'Not provided';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get currentLevelLabel => 'Current Level';

  @override
  String get departmentLabel => 'Department';

  @override
  String get bioLabel => 'Bio';

  @override
  String get noBioYetValue => 'No bio yet';

  @override
  String get unlimitedAccessTitle => 'Unlimited Access';

  @override
  String get unlimitedAccessSubtitle =>
      'You can now upload and download everything for free.';

  @override
  String get signOutTitle => 'Sign Out';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get changeAvatarTitle => 'Change Avatar';

  @override
  String get galleryOption => 'Gallery';

  @override
  String get cameraOption => 'Camera';

  @override
  String get appAppearanceTitle => 'App Appearance';

  @override
  String get accentColorLabel => 'Accent Color';

  @override
  String get roleAdmin => 'ADMIN';

  @override
  String get roleContributor => 'CONTRIBUTOR';

  @override
  String get roleViewer => 'VIEWER';

  @override
  String get adminAccessRequired => 'Admin access required.';

  @override
  String get manageDepartmentsTitle => 'Manage departments';

  @override
  String get manageUsersTitle => 'Manage users';

  @override
  String get adminAccessLabel => 'Admin access';

  @override
  String get administratorFallback => 'Administrator';

  @override
  String get institutionFallback => 'Institution';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get reviewYourAccountSubtitle => 'Review your account';

  @override
  String get noDepartmentsAvailableYet => 'No departments available yet.';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String schoolLabel(String schoolId) {
    return 'School: $schoolId';
  }

  @override
  String get schoolNotSet => 'School not set';

  @override
  String get searchNameMatriculeHint => 'Search name, matricule, or department';

  @override
  String get searchForUserLabel => 'Search for a user';

  @override
  String get unknownUserFallback => 'Unknown User';

  @override
  String get noMatriculeFallback => 'No matricule';

  @override
  String get roleLabelAdmin => 'Admin';

  @override
  String get roleLabelContributor => 'Contributor';

  @override
  String promoteToRoleTitle(String role) {
    return 'Promote to $role';
  }

  @override
  String promoteUserConfirmBody(String name, String role) {
    return 'Promote $name to $role?';
  }

  @override
  String get thisUserFallback => 'this user';

  @override
  String get promoteButton => 'Promote';

  @override
  String userIsNowRoleLabel(String name, String role) {
    return '$name is now a $role';
  }

  @override
  String get globalChatTitle => 'Global Chat';

  @override
  String get activeNowLabel => 'Active Now';

  @override
  String get aboutGlobalChatLabel => 'About Global Chat';

  @override
  String get connectWithPeersSubtitle => 'Connect with your peers';

  @override
  String get globalChatDescription =>
      'This is a real-time chat room for all users of GO-Study specific for this course. Please be respectful and follow community guidelines.';

  @override
  String get gotItButton => 'Got it';

  @override
  String errorLoadingMessages(String error) {
    return 'Error: $error';
  }

  @override
  String get noMessagesYetSayHi => 'No messages yet. Say hi!';

  @override
  String get todayLabel => 'Today';

  @override
  String get sendAMessageHint => 'Send a message';

  @override
  String replyingToLabel(String name) {
    return 'Replying to $name';
  }

  @override
  String get anonymousFallback => 'Anonymous';

  @override
  String get quickReviewTitle => 'Quick Review';

  @override
  String get aiGeneratedSummarySubtitle => 'AI-generated document summary';

  @override
  String get predictQuestionsBarrierLabel => 'Predict Questions';

  @override
  String get predictExamQuestionsTitle => 'Predict Exam Questions';

  @override
  String get generatePracticeQuizSubtitle =>
      'Generate a practice quiz from this document';

  @override
  String get chooseDifficultyLevel => 'Choose a difficulty level';

  @override
  String get generateQuizButton => 'Generate Quiz';

  @override
  String get tableOfContentsTitle => 'Table of Contents';

  @override
  String get navigateThroughDocumentSubtitle => 'Navigate through the document';

  @override
  String get noBookmarksFoundMessage => 'No bookmarks found in this document';

  @override
  String get searchInDocumentHint => 'Search in document...';

  @override
  String get searchTooltip => 'Search';

  @override
  String get chatWithPdfTooltip => 'Chat with PDF';

  @override
  String get downloadTooltip => 'Download';

  @override
  String get askAnythingAboutDocumentHint =>
      'Ask anything about this document...';

  @override
  String get joinDiscussionTooltip => 'Join Discussion';

  @override
  String courseDiscussionTitle(String code) {
    return '$code Discussion';
  }

  @override
  String get courseDiscussionRoomSubtitle => 'Course Discussion Room';

  @override
  String get noMaterialsYetMessage => 'No materials for this course yet.';

  @override
  String get generalResourcesHeader => 'General Resources';

  @override
  String get pastQuestionsAndAnswersHeader => 'Past Questions & Answers';

  @override
  String get pqBadge => 'PQ';

  @override
  String get ansBadge => 'ANS';

  @override
  String get docBadge => 'DOC';

  @override
  String get deleteMaterialDialogTitle => 'Delete Material?';

  @override
  String confirmDeleteMaterialBody(String title) {
    return 'Are you sure you want to delete $title? This cannot be undone.';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get materialDeletedMessage => 'Material deleted';

  @override
  String get downloadMenuItem => 'Download';

  @override
  String get materialSecuredOfflineMessage =>
      'Material secured for offline access! 🔒';

  @override
  String pastQuestionAnswersCountSubtitle(int count) {
    return 'Past Question • $count Answers';
  }

  @override
  String get deletePastQuestionDialogTitle => 'Delete Past Question?';

  @override
  String get pastQuestionDeletedMessage => 'Past Question deleted';

  @override
  String get noAnswersUploadedYet => 'No answers uploaded yet';

  @override
  String verifiedAnswerFeeSubtitle(int fee) {
    return 'Verified Answer • $fee XAF';
  }

  @override
  String get onlyContributorsCanUploadMessage =>
      'Only administrators can upload content.';

  @override
  String get addMaterialTitle => 'Add Material';

  @override
  String get shareResourcesSubtitle => 'Share resources with your peers';

  @override
  String get generalMaterialOption => 'General Material';

  @override
  String get pastQuestionOption => 'Past Question';

  @override
  String get answerOption => 'Answer';

  @override
  String get linkToQuestionLabel => 'Link to Question';

  @override
  String get selectTheQuestionHint => 'Select the question';

  @override
  String get requiredValidator => 'Required';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHintExample => 'e.g. Intro to Java Notes';

  @override
  String get descriptionOptionalLabel => 'Description (Optional)';

  @override
  String get brieflyDescribeContentHint => 'Briefly describe the content';

  @override
  String get selectMaterialFileLabel => 'Select Material File';

  @override
  String get fileSelectedSuccessfully => 'File selected successfully';

  @override
  String get uploadPdfOrWordHint => 'Upload PDF or Word';

  @override
  String get supportsPdfDocImagesHint => 'Supports PDF, DOC, Images';

  @override
  String get uploadMaterialButton => 'Upload Material';

  @override
  String get pleaseSelectFileMessage => 'Please select a file';

  @override
  String get uploadSuccessfulMessage => 'Upload successful!';

  @override
  String get selectMaterialTypeSubtitle =>
      'Select the type of material you want to share';

  @override
  String get lectureNotesSubtitle => 'Lecture notes, summaries, textbooks';

  @override
  String get previousExamPapersSubtitle => 'Previous exam or test papers';

  @override
  String get solutionsToPastQuestionsSubtitle => 'Solutions to past questions';

  @override
  String get verifiedAnswerTitle => 'Verified Answer';

  @override
  String get communityContributionCodeTitle => 'Community Contribution Code';

  @override
  String get guidelineReadableContent =>
      'Ensure content is readable, correct, and fit for study.';

  @override
  String get guidelineCheckDuplicate =>
      'Check if this resource is already uploaded.';

  @override
  String get guidelineAcademicOnly =>
      'Upload only academic and educational materials.';

  @override
  String get deleteDepartmentDialogTitle => 'Delete Department?';

  @override
  String confirmDeleteDepartmentBody(String name) {
    return 'Are you sure you want to delete $name? This will delete all courses and materials within it. This action cannot be undone.';
  }

  @override
  String get departmentDeletedMessage => 'Department deleted';

  @override
  String get deleteDepartmentMenuItem => 'Delete Department';

  @override
  String get aboutTabLabel => 'About';

  @override
  String get coursesTabLabel => 'Courses';

  @override
  String get docsTabLabel => 'Docs';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String departmentGroupTitle(String name) {
    return '$name Group';
  }

  @override
  String get departmentalStudyGroupSubtitle => 'Departmental Study Group';

  @override
  String get uploadButton => 'Upload';

  @override
  String get aboutDepartmentHeader => 'About Department';

  @override
  String get descriptionHeader => 'Description';

  @override
  String get departmentDescriptionPlaceholder =>
      'Details and descriptions about this department will appear here. Students can find general information, faculty details, and more.';

  @override
  String get noCoursesFoundMessage => 'No courses found!';

  @override
  String levelHeader(String level) {
    return 'Level $level';
  }

  @override
  String get otherCoursesHeader => 'Other Courses';

  @override
  String get courseDeletedMessage => 'Course deleted';

  @override
  String get deleteCourseMenuItem => 'Delete Course';

  @override
  String get courseMaterialsTooltip => 'Course Materials';

  @override
  String get noMaterialsYetShort => 'No materials yet';

  @override
  String get noResourcesAvailableMessage => 'No resources available';

  @override
  String get noPastQuestionsAvailableMessage => 'No past questions available';

  @override
  String get downloadMaterialTitle => 'Download Material';

  @override
  String get secureAccessSubtitle => 'Secure access to study resources';

  @override
  String downloadFeeNotice(String title, String category, int fee) {
    return 'To download \"$title\" ($category), a fee of $fee XAF is required.';
  }

  @override
  String get paymentPhoneLabel => 'Payment Phone';

  @override
  String get paymentPhoneHint => '6xxxxxxxx (MTN/Orange)';

  @override
  String get payAndDownloadButton => 'Pay & Download';

  @override
  String get beFirstToContributeMessage =>
      'Be the first to contribute to this department\'s resources!';

  @override
  String get addNewButton => 'Add New';

  @override
  String get addNewCourseMenuItem => 'Add New Course';

  @override
  String get uploadDepartmentResourceMenuItem => 'Upload Department Resource';

  @override
  String get uploadCourseMaterialMenuItem => 'Upload Course Material';

  @override
  String get addCourseFirstMessage => 'Add a course first!';

  @override
  String get uploadPastQuestionMenuItem => 'Upload Past Question';

  @override
  String get uploadAnswerMenuItem => 'Upload Answer';

  @override
  String get selectCourseTitle => 'Select Course';

  @override
  String get whichCourseSubtitle => 'Which course is this for?';

  @override
  String courseLevelCodeSubtitle(String level, String code) {
    return 'Level $level • $code';
  }

  @override
  String get deptResourceTitle => 'Dept Resource';

  @override
  String get shareFacultyWideDocsSubtitle => 'Share faculty-wide documents';

  @override
  String addResourcesForCourseSubtitle(String name) {
    return 'Add resources for $name';
  }

  @override
  String get courseFallback => 'Course';

  @override
  String courseLabelPrefix(String name) {
    return 'Course: $name';
  }

  @override
  String get generalOption => 'General';

  @override
  String get resourceTitleHintExample => 'e.g. Exam Prep Notes';

  @override
  String get briefResourceDetailsHint => 'Brief details about the resource';

  @override
  String get selectResourceFileLabel => 'Select Resource File';

  @override
  String get readyForUploadLabel => 'Ready for upload';

  @override
  String get pdfDocImagesOnlyHint => 'PDF, DOC, or Images only';

  @override
  String get uploadResourceButton => 'Upload Resource';

  @override
  String get onlyAdminsCanAddCoursesMessage =>
      'Only administrators can add new courses.';

  @override
  String get deleteCourseDialogTitle => 'Delete Course?';

  @override
  String get aiCreditsRequiredTitle => 'AI Credits Required';

  @override
  String get outOfAiCreditsBody =>
      'You have run out of AI credits. Upgrade to a premium plan or top up your credits to continue using Gemini Academic.';

  @override
  String get get50CreditsTitle => 'Get 50 Credits';

  @override
  String get only500XafSubtitle => 'Only 500 XAF';

  @override
  String get notNowButton => 'Not Now';

  @override
  String get topUpButton => 'Top Up';

  @override
  String get rateUsBarrierLabel => 'Rate Us';

  @override
  String get rateUsTitle => 'Rate Us!';

  @override
  String get helpUsImproveSubtitle => 'Help us improve Ub-Hub';

  @override
  String get rateUsBody =>
      'If you enjoy using Ub-Hub, please take a moment to rate us. Your feedback is invaluable!';

  @override
  String get laterButton => 'Later';

  @override
  String get rateNowButton => 'Rate Now';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get loveToHearFromYouTitle => 'We\'d love to hear from you!';

  @override
  String get feedbackBodyText =>
      'Found a bug? Have a suggestion? Send us an email and help us make Ub-Hub better.';

  @override
  String get sendEmailButton => 'Send Email';

  @override
  String get trialPeriodEndedTitle => 'Trial Period Ended';

  @override
  String get trialExpiredBody =>
      'Your 4-day free access to  GoStudy has expired. Upgrade to a premium plan to unlock your academic dashboard, UB Support Bot, and unlimited materials.';

  @override
  String get viewUpgradePlansButton => 'View Upgrade Plans';

  @override
  String get addCourseTitle => 'Add Course';

  @override
  String get organizeAcademicContentSubtitle =>
      'Organize your academic content';

  @override
  String get courseNameHintExample => 'e.g. Data Structures';

  @override
  String get pleaseEnterCourseName => 'Please enter a course name';

  @override
  String get courseCodeLabel => 'Course Code';

  @override
  String get courseCodeHintExample => 'e.g. CS201';

  @override
  String get pleaseEnterCourseCode => 'Please enter a course code';

  @override
  String get levelLabel => 'Level';

  @override
  String get selectAcademicLevelHint => 'Select academic level';

  @override
  String get userNotAuthenticatedMessage => 'User not authenticated';

  @override
  String get aboutAppTitle => 'About App';

  @override
  String get appDescriptionBody =>
      'GO-Study is your ultimate academic companion, specifically tailored for the University of Buea student community. From AI-driven study plans to real-time exam schedules and global peer collaboration, we empower you with the technical tools needed to navigate your academic journey with excellence and ease.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get licensesLegalTitle => 'Licenses & Legal';

  @override
  String get openSourceLibrariesSubtitle =>
      'Open source libraries and legal info';

  @override
  String get appLegaleseCopyright => '© 2026 Jovial Studio';

  @override
  String get aboutDialogDescription =>
      'GO-Study is an academic companion designed for students at the University of Buea. It provides easy access to resources, AI-powered study assistance, course management, and peer collaboration tools to help you excel in your academic journey.';

  @override
  String get eventsCalendarTitle => 'Events Calendar';

  @override
  String get eventIdLabel => 'Event ID';

  @override
  String get eventNameLabel => 'Event Name';

  @override
  String get eventCategoryLabel => 'Event Category';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get noDescriptionProvided => 'No description provided.';

  @override
  String get venueLabel => 'Venue';

  @override
  String get tbdValue => 'TBD';

  @override
  String get eventStartTimeLabel => 'Event Start Time';

  @override
  String get eventEndTimeLabel => 'Event End Time';

  @override
  String get eventStatusLabel => 'Event Status';

  @override
  String get eventImageLabel => 'Event Image';

  @override
  String get addCommentButton => 'Add Comment';

  @override
  String get deleteEventTitle => 'Delete Event';

  @override
  String get confirmDeleteEventBody =>
      'Are you sure you want to delete this event? All associated data will be permanently removed.';

  @override
  String get messageSellerButton => 'Message Seller';

  @override
  String get buyNowButton => 'Buy Now';

  @override
  String get digitalPurchaseComingSoonMessage =>
      'Purchase flow for specific listings is coming soon!';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get noQuestionsInQuiz => 'No questions found in this quiz.';

  @override
  String get resultsTitle => 'Results';

  @override
  String questionCounterTitle(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get submitAnswerButton => 'SUBMIT ANSWER';

  @override
  String get greatJobTitle => 'Great Job!';

  @override
  String get keepStudyingTitle => 'Keep Studying!';

  @override
  String youScoredOutOfLabel(int score, int total) {
    return 'You scored $score out of $total';
  }

  @override
  String accuracyPercentLabel(int percent) {
    return '$percent% Accuracy';
  }

  @override
  String get backToGeneratorButton => 'BACK TO GENERATOR';

  @override
  String get generateFlashcardsButton => 'Generate flashcards';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get flashcardCountQuestion => 'How many cards?';

  @override
  String get generatingFlashcardsMessage => 'Generating flashcards…';

  @override
  String get flashcardGenerationFailed =>
      'Couldn\'t generate flashcards. Please try again.';

  @override
  String get flashcardServiceUnavailable =>
      'The AI service is unavailable right now. Please try again in a moment.';

  @override
  String get aiServiceUnavailable =>
      'The AI service is unavailable right now. Please try again in a moment.';

  @override
  String get flashcardsPdfOnlyMessage =>
      'Flashcards can only be generated from PDF materials';

  @override
  String get flashcardQuestionLabel => 'QUESTION';

  @override
  String get flashcardAnswerLabel => 'ANSWER';

  @override
  String get tapToFlipHint => 'Tap the card to flip';

  @override
  String get stillLearningButton => 'Still learning';

  @override
  String get studyAgainButton => 'Study again';

  @override
  String flashcardsMasteredLabel(int mastered, int total) {
    return 'You mastered $mastered of $total';
  }

  @override
  String deckCardCountLabel(int count) {
    return '$count cards';
  }

  @override
  String get deleteDeckDialogTitle => 'Delete deck?';

  @override
  String confirmDeleteDeckBody(String title) {
    return 'Delete the deck \"$title\"? This cannot be undone.';
  }

  @override
  String get materialsTabLabel => 'Materials';

  @override
  String get practiceTabLabel => 'Practice';

  @override
  String get selectLevelLabel => 'Select a level';

  @override
  String get startLessonButton => 'Start Lesson';

  @override
  String get checkAnswerButton => 'Check';

  @override
  String get continueButton => 'Continue';

  @override
  String get doneButton => 'Done';

  @override
  String get matchingInstructionLabel =>
      'Tap a word on the left, then its match on the right.';

  @override
  String get frenchForEnglishSpeakersTitle => 'French for English Speakers';

  @override
  String get englishForFrenchSpeakersTitle => 'English for French Speakers';

  @override
  String get supportDeveloperBarrierLabel => 'Support Developer';

  @override
  String get supportTheDeveloperTitle => 'Support the Developer';

  @override
  String get helpKeepProjectAliveSubtitle =>
      'Help keep the project alive and growing';

  @override
  String get supportDialogBody =>
      'Your support helps us maintain the infrastructure and add new features. Any amount is appreciated! ❤️';

  @override
  String get amountXafLabel => 'Amount (XAF)';

  @override
  String get amountHintExample => 'e.g. 500';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get phoneNumberHintPlain => '6xxxxxxxx';

  @override
  String get phoneNumberRequired => 'Phone number required';

  @override
  String get enterValidCameroonPhone => 'Enter a valid Cameroon phone number';

  @override
  String get supportButton => 'Support';

  @override
  String get thankYouForSupportMessage =>
      'Thank you for your generous support! ❤️';

  @override
  String get couldNotOpenWhatsappMessage =>
      'Could not open WhatsApp. Please ensure WhatsApp is installed.';

  @override
  String get transcriptApplicationTitle => 'Transcript Application';

  @override
  String get applyNowTitle => 'Apply Now';

  @override
  String get requestTranscriptSubtitle =>
      'Fill in the details below to request your academic transcript.';

  @override
  String get personalInformationSectionTitle => 'Personal Information';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get enterYourNameValidator => 'Enter your name';

  @override
  String get whatsappNumberHint => 'WhatsApp Number (e.g. 6xxxxxxxx)';

  @override
  String get enterValidPhoneValidator => 'Enter a valid phone number';

  @override
  String get enterValidEmailValidator => 'Enter a valid email';

  @override
  String get academicDetailsSectionTitle => 'Academic Details';

  @override
  String get matriculeNumberHint => 'Matricule Number';

  @override
  String get enterYourMatriculeValidator => 'Enter your matricule';

  @override
  String get facultyHint => 'Faculty';

  @override
  String get enterYourFacultyValidator => 'Enter your faculty';

  @override
  String get departmentHint => 'Department';

  @override
  String get enterYourDepartmentValidator => 'Enter your department';

  @override
  String get applicationOptionsSectionTitle => 'Application Options';

  @override
  String get modeOfApplicationHint => 'Mode of Application';

  @override
  String get selectAModeValidator => 'Select a mode';

  @override
  String get studentStatusHint => 'Student Status';

  @override
  String get selectYourStatusValidator => 'Select your status';

  @override
  String get submitApplicationButton => 'Submit Application';

  @override
  String get modeNormal => 'Normal Mode (1200 XAF)';

  @override
  String get modeFast => 'Fast Mode (2500 XAF)';

  @override
  String get modeSuperFast => 'Super Fast Mode (3500 XAF)';

  @override
  String get chooseDeliveryMethodTitle => 'Choose Delivery Method';

  @override
  String get chooseDeliveryMethodSubtitle =>
      'How would you like to receive your transcript?';

  @override
  String get deliveryMethodPdfLabel => 'PDF (Soft Copy)';

  @override
  String get deliveryMethodPdfSubtitle =>
      'Receive a digital copy by email/WhatsApp';

  @override
  String get deliveryMethodOnsiteLabel => 'Onsite (Physical Pickup)';

  @override
  String get deliveryMethodOnsiteSubtitle => 'Pick up a printed copy in person';

  @override
  String get acceptButton => 'Accept';

  @override
  String get payToSubmitApplicationSubtitle => 'Pay to submit your application';

  @override
  String get applicationSubmittedMessage =>
      'Application submitted! Redirecting to WhatsApp...';

  @override
  String get statusCurrentStudent => 'Current Student';

  @override
  String get statusFormerStudent => 'Former Student';

  @override
  String get ubKnowledgeBaseTitle => 'UB Knowledge Base';

  @override
  String get noUbKnowledgeYet => 'No UB knowledge added yet';

  @override
  String get addUniversityFactsSubtitle =>
      'Add university facts for the bot to learn!';

  @override
  String get processingLabel => 'Processing...';

  @override
  String get uploadUbPdfButton => 'Upload UB PDF';

  @override
  String get addUbInfoButton => 'Add UB Info';

  @override
  String get knowledgeScopeTitle => 'Knowledge Scope';

  @override
  String get knowledgeScopeBody =>
      'Should this information be available to all students (Global) or just you (Personal)?';

  @override
  String get personalOption => 'Personal';

  @override
  String get globalOption => 'Global';

  @override
  String pdfTitlePrefix(String name) {
    return 'PDF: $name';
  }

  @override
  String get pdfProcessedMessage =>
      'PDF processed and added to knowledge base!';

  @override
  String get addUbKnowledgeBarrierLabel => 'Add UB Knowledge';

  @override
  String get newUniversityInfoTitle => 'New University Info';

  @override
  String get topicLabel => 'Topic (e.g. Admission)';

  @override
  String get topicHintExample => 'e.g. Faculty of Arts';

  @override
  String get detailsLabel => 'Details';

  @override
  String get provideUniversityInfoHint => 'Provide university-specific info...';

  @override
  String get makeGlobalLabel => 'Make Global';

  @override
  String get visibleToAllUsersSubtitle => 'Visible to all users';

  @override
  String get saveButton => 'Save';

  @override
  String get addDepartmentBarrierLabel => 'Add Department';

  @override
  String get newDepartmentTitle => 'New Department';

  @override
  String get expandAcademicEcosystemSubtitle =>
      'Expand your academic ecosystem';

  @override
  String get departmentNameLabel => 'Department Name';

  @override
  String get departmentNameHintExample => 'e.g. Computer Science';

  @override
  String get nameRequiredValidator => 'Name required';

  @override
  String get schoolIdLabel => 'School ID';

  @override
  String get identifyParentSchoolHint => 'Identify the parent school';

  @override
  String get schoolIdRequiredValidator => 'School ID required';

  @override
  String get whatMakesDeptUniqueHint => 'What makes this department unique?';

  @override
  String get descriptionRequiredValidator => 'Description required';

  @override
  String get departmentIdentityLabel => 'Department Identity';

  @override
  String get uploadCoverPhotoLabel => 'Upload cover photo';

  @override
  String get createDepartmentButton => 'Create Department';

  @override
  String get developerInfoTitle => 'Developer Info';

  @override
  String get leadDeveloperAtJovialLaps => 'Lead Developer @ Jovial Laps';

  @override
  String get engineeringDetailsSection => 'Engineering Details';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get buildNumberLabel => 'Build Number';

  @override
  String get frameworkLabel => 'Framework';

  @override
  String get connectSection => 'Connect';

  @override
  String get githubLabel => 'GitHub';

  @override
  String get linkedinLabel => 'LinkedIn';

  @override
  String get professionalProfileSubtitle => 'Professional Profile';

  @override
  String get contactEmailLabel => 'Contact Email';

  @override
  String get directLineLabel => 'Direct Line';

  @override
  String get builtWithLoveForUbStudents => 'Built with ❤️ for UB Students';

  @override
  String get clearAllNotificationsTitle => 'Clear All Notifications';

  @override
  String get confirmClearAllNotificationsBody =>
      'Are you sure you want to delete all notifications? This will permanently remove your recent activity history.';

  @override
  String get clearAllButtonShort => 'Clear All';

  @override
  String get pushNotificationsTitle => 'Push Notifications';

  @override
  String get receiveAlertsNewCoursesSubtitle =>
      'Receive alerts for new courses';

  @override
  String get emailUpdatesTitle => 'Email Updates';

  @override
  String get receiveDigestEmailsSubtitle => 'Receive digest emails';

  @override
  String get studyRemindersTitle => 'Study Reminders';

  @override
  String get dailyReminderSubtitle => 'Daily reminder to stay on track';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get noNotificationsFound => 'No notifications found';

  @override
  String get createNewEventTitle => 'Create New Event';

  @override
  String get editEventTitle => 'Edit Event';

  @override
  String get eventNameHintExample => 'e.g. Computer Science Final';

  @override
  String get venueHintExample => 'e.g. Amphi 700';

  @override
  String get eventDescriptionLabel => 'Event Description';

  @override
  String get addAdditionalDetailsHint => 'Add any additional details...';

  @override
  String get submitButton => 'Submit';

  @override
  String upcomingExamNotificationTitle(String name) {
    return 'Upcoming Exam: $name';
  }

  @override
  String examVenueTimeNotificationBody(String venue, String time) {
    return 'Venue: $venue @ $time';
  }

  @override
  String get categoryMidterm => 'Midterm';

  @override
  String get categoryFinal => 'Final';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categoryAssignment => 'Assignment';

  @override
  String get categoryPractical => 'Practical';

  @override
  String get categoryPresentation => 'Presentation';

  @override
  String get unlimitedLabel => 'Unlimited';

  @override
  String daysRemainingLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get endingTodayLabel => 'Ending today';

  @override
  String get currentBalanceLabel => 'Current Balance';

  @override
  String creditsCountLabel(int credits) {
    return '$credits Credits';
  }

  @override
  String get topUpAiCreditsTitle => 'Top up AI Credits';

  @override
  String get creditsUsageSubtitle =>
      'Credits are used for Gemini AI interactions. Core academic tools remain free for everyone.';

  @override
  String get fapshiTestModeLabel => 'FAPSHI TEST MODE';

  @override
  String get fapshiTestModeBody =>
      'Test payment integration with the Fapshi Sandbox (100 XAF). Adds 10 test credits.';

  @override
  String get pay100XafTestButton => 'Pay 100 XAF (Test)';

  @override
  String get starterPackTitle => 'Starter Pack';

  @override
  String get studentPackTitle => 'Student Pack';

  @override
  String get mostPopularLabel => 'MOST POPULAR';

  @override
  String creditsCountAiLabel(int credits) {
    return '$credits AI Credits';
  }

  @override
  String get unlimitedAiSubscriptionsTitle => 'Unlimited AI Subscriptions';

  @override
  String get unlimitedMonthlyTitle => 'Unlimited Monthly';

  @override
  String get unlimitedYearlyTitle => 'Unlimited Yearly';

  @override
  String get featureUnlimitedGeminiChat => 'Unlimited Gemini AI Chat';

  @override
  String get featureUnlimitedPdfSummaries => 'Unlimited PDF Summaries';

  @override
  String get featurePriorityAiResponse => 'Priority AI Response';

  @override
  String get featureAiStudyPlanGenerator => 'AI Study Plan Generator';

  @override
  String get featureStructureQuizGenerator => 'Structure Quiz Generator';

  @override
  String get appPlanTitle => 'App Plan';

  @override
  String get appPlanSubtitle =>
      'Unlimited downloads and priority support. Separate from AI credits/subscription above.';

  @override
  String pricePerMonthLabel(int price) {
    return '$price XAF / month';
  }

  @override
  String pricePerYearLabel(int price) {
    return '$price XAF / year';
  }

  @override
  String get currentPlanButton => 'Current Plan';

  @override
  String get getUnlimitedButton => 'Get Unlimited';

  @override
  String trialActiveLeftBadge(String time) {
    return 'TRIAL ACTIVE • $time LEFT';
  }

  @override
  String get currentPlanBadge => 'CURRENT PLAN';

  @override
  String get firstMonthFreeBadge => 'FIRST MONTH FREE';

  @override
  String get startFreeTrialButton => 'Start Free Trial';

  @override
  String get subscribeButton => 'Subscribe';

  @override
  String freeMonthThenPriceLabel(int price) {
    return 'Free for 1 month, then $price XAF / month';
  }

  @override
  String get aiFeaturesBilledSeparatelyShort =>
      'AI features are billed separately and not included.';

  @override
  String get startYourFreeMonthTitle => 'Start Your Free Month';

  @override
  String get noPaymentRequiredTodaySubtitle => 'No payment required today';

  @override
  String freeTrialTermsBody(int price) {
    return 'Your App Plan is free for the first 30 days, then renews at $price XAF/month. AI features are billed separately and are not included in this trial.';
  }

  @override
  String get freeTrialActivatedMessage => 'Free trial activated!';

  @override
  String get buyCreditsBarrierLabel => 'Buy Credits';

  @override
  String buyPackTitle(String packName) {
    return 'Buy $packName';
  }

  @override
  String addCreditsToBalanceSubtitle(int credits) {
    return 'Add $credits credits to your balance';
  }

  @override
  String enterMomoNumberToPayBody(int amount) {
    return 'Enter your MoMo/OM number to pay $amount XAF.';
  }

  @override
  String get phoneNumberHintUppercase => '6XXXXXXXX';

  @override
  String get payNowButton => 'Pay Now';

  @override
  String get completePaymentInBrowserShort => 'Complete payment in browser...';

  @override
  String get waitingForApprovalMessage => 'Waiting for approval...';

  @override
  String creditsAddedSuccessfullyMessage(int credits) {
    return '$credits credits added successfully!';
  }

  @override
  String get contributorBadge => 'CONTRIBUTOR';

  @override
  String get beACreatorTitle => 'Be a Creator';

  @override
  String get contributorUploadBody =>
      'Upload your own materials, earn from downloads, and unlock everything forever.';

  @override
  String get includedWithAdminContributor => 'Included with Admin/Contributor';

  @override
  String get oneTimePayment5000Xaf => 'One-time Payment 5000 XAF';

  @override
  String subscribeToTierTitle(String tierName) {
    return 'Subscribe to $tierName';
  }

  @override
  String get unlockPremiumToolsSubtitle => 'Unlock premium academic tools';

  @override
  String enterMomoForDaysBody(int amount, int days) {
    return 'Enter your Mobile Money number to pay $amount XAF for $days days of access.';
  }

  @override
  String get completePaymentBrowserTip =>
      'Complete payment in the browser window.\n\nTip: Stay on the Fapshi page until the USSD prompt appears on your phone.';

  @override
  String get checkPhoneMomoPromptTip =>
      'Check your phone for a MoMo prompt.\n\nMTN: Keep screen unlocked.\nOrange: Dial #150*50# if prompted for an OTP.';

  @override
  String get subscriptionActivatedMessage => 'Subscription activated!';

  @override
  String get upgradeToContributorTitle => 'Upgrade to Contributor';

  @override
  String get unlockEverythingForeverSubtitle => 'Unlock everything forever';

  @override
  String get contributorUpgradeTermsBody =>
      'Pay 5000 XAF once to unlock unlimited downloads, uploads, and all premium features forever.';

  @override
  String get momoOmNumberLabel => 'Momo/OM Number';

  @override
  String get youAreNowContributorMessage => 'You are now a Contributor!';

  @override
  String get testCreditsPackTitle => 'Test Credits';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionNotifications => 'Push Notifications';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get editButton => 'Edit';

  @override
  String get newsAdminNewPostButton => 'New Post';

  @override
  String get newsAuthorFallback => 'Announcement';

  @override
  String get newsComposerNewTitle => 'New Post';

  @override
  String get newsComposerEditTitle => 'Edit Post';

  @override
  String get newsTitleFieldLabel => 'Title';

  @override
  String get newsTitleFieldHint => 'A short, clear headline';

  @override
  String get newsTitleRequiredValidator => 'A title is required';

  @override
  String get newsBodyFieldLabel => 'Details';

  @override
  String get newsBodyFieldHint => 'Write the announcement…';

  @override
  String get newsBodyRequiredValidator => 'Some details are required';

  @override
  String get newsUploadCoverLabel => 'Cover image (optional)';

  @override
  String get newsPublishButton => 'Publish';

  @override
  String get newsPostPublishedSnack => 'Post published';

  @override
  String get newsPostUpdatedSnack => 'Post updated';

  @override
  String get newsAdminOnlyMessage => 'Only admins can post news.';

  @override
  String get newsDeletePostTitle => 'Delete this post?';

  @override
  String get newsDeletePostBody =>
      'The post and all of its likes and comments will be permanently removed.';

  @override
  String get newsDeleteCommentTitle => 'Delete comment?';

  @override
  String get newsDeleteCommentBody =>
      'This comment will be permanently removed.';

  @override
  String get newsNoCommentsYet => 'No comments yet. Be the first.';

  @override
  String get newsCommentHintText => 'Add a comment…';

  @override
  String get newsSendCommentTooltip => 'Send';

  @override
  String newsCommentsHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'Comments',
    );
    return '$_temp0';
  }

  @override
  String weeklyProgressWeekRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get weeklyProgressTodayPill => 'Today';

  @override
  String get weeklyProgressTodayPillTooltip => 'Back to this week';

  @override
  String get weeklyProgressPrevWeekTooltip => 'Previous week';

  @override
  String get weeklyProgressNextWeekTooltip => 'Next week';

  @override
  String weeklyProgressNextExam(String date) {
    return 'Next exam on $date';
  }

  @override
  String get weeklyProgressNoUpcomingExams => 'No upcoming exams';

  @override
  String get weeklyProgressExamRowFallbackSubtitle => 'Tap to schedule one';

  @override
  String weeklyProgressTasksRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks remaining today',
      one: '1 task remaining today',
      zero: 'All tasks done for today',
    );
    return '$_temp0';
  }

  @override
  String get weeklyProgressNoTasksToday => 'No tasks due today';

  @override
  String weeklyProgressCompletedYesterday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks completed yesterday',
      one: '1 task completed yesterday',
      zero: 'No tasks completed yesterday',
    );
    return '$_temp0';
  }

  @override
  String get weeklyProgressNoTasksYesterday => 'No tasks were due yesterday';

  @override
  String weeklyProgressDueTomorrow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks due tomorrow',
      one: '1 task due tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get weeklyProgressNothingTomorrow => 'Nothing scheduled for tomorrow';

  @override
  String weeklyProgressCompletedOnPastDate(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks completed on $day',
      one: '1 task completed on $day',
      zero: 'No tasks completed on $day',
    );
    return '$_temp0';
  }

  @override
  String weeklyProgressNoTasksOnPastDate(String day) {
    return 'No tasks were due on $day';
  }

  @override
  String weeklyProgressDueOnFutureDate(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks due on $day',
      one: '1 task due on $day',
    );
    return '$_temp0';
  }

  @override
  String weeklyProgressNothingOnFutureDate(String day) {
    return 'Nothing scheduled for $day';
  }
}
