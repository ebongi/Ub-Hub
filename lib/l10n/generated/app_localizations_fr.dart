// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingPage1Title => 'C\'est\nparti';

  @override
  String get onboardingPage1Body =>
      'Organisez votre parcours académique dans un espace structuré conçu pour les étudiants, les départements et le partage de ressources d\'étude.';

  @override
  String get onboardingPage2Title => 'Faites\nconnaissance';

  @override
  String get onboardingPage2Body =>
      'Trouvez votre établissement, explorez ses écoles et départements, et accédez rapidement aux bons cours et supports.';

  @override
  String get onboardingPage3Title => 'Étudiez\nensemble';

  @override
  String get onboardingPage3Body =>
      'Utilisez les pages de département, le chat de groupe, les notes et le contenu partagé pour collaborer facilement avec vos camarades.';

  @override
  String get onboardingPage4Title => 'Apprenez\nmieux';

  @override
  String get onboardingPage4Body =>
      'Suivez vos tâches, préparez vos examens, utilisez l\'assistance IA et restez organisé grâce à des outils pensés pour le travail académique.';

  @override
  String get signInWelcomeBack => 'Content de vous revoir';

  @override
  String get signInSubtitle =>
      'Connectez-vous pour continuer votre parcours académique.';

  @override
  String get emailAddressLabel => 'Adresse e-mail';

  @override
  String get emailAddressHint => 'Adresse e-mail';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get minimumSixCharacters => 'Minimum 6 caractères';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get orDivider => 'OU';

  @override
  String get noAccountPrompt => 'Vous n\'avez pas de compte ?';

  @override
  String get signUpLink => 'S\'inscrire';

  @override
  String get registerTitle => 'Inscription étudiante';

  @override
  String get registerSubtitle =>
      'Créez votre compte en quatre étapes guidées conçues pour le parcours académique.';

  @override
  String registerStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get registerBack => 'Retour';

  @override
  String get registerContinue => 'Continuer';

  @override
  String get registerComplete => 'Terminer l\'inscription';

  @override
  String get registerVerificationRequired => 'VÉRIFICATION REQUISE';

  @override
  String get alreadyRegistered => 'Déjà inscrit ?';

  @override
  String get signInToPortal => 'Se connecter au portail';

  @override
  String get accountStepTitle => 'Compte';

  @override
  String get accountStepDescription =>
      'Sécurisez votre profil académique avec un e-mail et un mot de passe robustes.';

  @override
  String get accountCredentialsTitle => 'Identifiants du compte';

  @override
  String get accountCredentialsSubtitle =>
      'Cette section protège l\'accès à votre portail et vos données d\'études.';

  @override
  String get academicEmailLabel => 'E-mail académique';

  @override
  String get academicEmailHint => 'etudiant@universite.edu';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get securePasswordLabel => 'Mot de passe sécurisé';

  @override
  String get enterStrongPasswordHint => 'Entrez un mot de passe robuste';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get minimumEightCharacters => 'Minimum 8 caractères';

  @override
  String get addUppercaseLetter => 'Ajoutez au moins une majuscule';

  @override
  String get addDigit => 'Ajoutez au moins un chiffre';

  @override
  String get addSpecialCharacter => 'Ajoutez un caractère spécial';

  @override
  String get passwordSecurityLabel => 'Sécurité du mot de passe';

  @override
  String get passwordStrengthHint =>
      'Utilisez un mélange de majuscules, de chiffres et de symboles.';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthFair => 'Correct';

  @override
  String get passwordStrengthGood => 'Bon';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get repeatPasswordHint => 'Répétez le mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get identityStepTitle => 'Identité';

  @override
  String get identityStepDescription =>
      'Ajoutez votre nom réel et vos coordonnées pour que la communauté puisse vous identifier.';

  @override
  String get personalIdentityTitle => 'Identité personnelle';

  @override
  String get personalIdentitySubtitle =>
      'Cette section rend votre profil reconnaissable par vos camarades et les administrateurs.';

  @override
  String get fullLegalNameLabel => 'Nom complet';

  @override
  String get firstLastNameHint => 'Prénom et nom';

  @override
  String get fullNameRequired => 'Le nom complet est requis';

  @override
  String get phoneContactLabel => 'Numéro de téléphone';

  @override
  String get phoneRequired => 'Le numéro de téléphone est requis';

  @override
  String get academicStepTitle => 'Académique';

  @override
  String get academicStepDescription =>
      'Renseignez votre université, votre matricule et votre niveau d\'étude pour accéder aux bonnes ressources.';

  @override
  String get academicAffiliationTitle => 'Affiliation académique';

  @override
  String get academicAffiliationSubtitle =>
      'Cela relie votre compte à la bonne filière d\'études.';

  @override
  String get studentMatriculeLabel => 'Matricule étudiant';

  @override
  String get officialUniversityIdHint => 'Identifiant universitaire officiel';

  @override
  String get matriculeRequired => 'Le matricule est requis';

  @override
  String get currentAcademicLevelLabel => 'Niveau académique actuel';

  @override
  String get selectYourLevelHint => 'Sélectionnez votre niveau';

  @override
  String get pleaseSelectLevel => 'Veuillez sélectionner un niveau';

  @override
  String get assignedInstitutionLabel => 'Établissement assigné';

  @override
  String get selectYourUniversityHint => 'Sélectionnez votre université';

  @override
  String get pleaseSelectUniversity => 'Veuillez sélectionner votre université';

  @override
  String get academicLevelResit => 'Rattrapage';

  @override
  String get finalizeStepTitle => 'Finalisation';

  @override
  String get finalizeStepDescription =>
      'Complétez votre profil avec votre département et une courte bio académique.';

  @override
  String get finalizeProfileTitle => 'Finaliser le profil';

  @override
  String get finalizeProfileSubtitle =>
      'C\'est la dernière étape avant que votre compte étudiant soit prêt.';

  @override
  String get academicBioLabel => 'Bio académique';

  @override
  String get academicBioHint =>
      'Décrivez brièvement vos centres d\'intérêt académiques...';

  @override
  String get academicDepartmentLabel => 'Département académique';

  @override
  String get selectInstitutionFirstHint =>
      'Sélectionnez un établissement à l\'étape précédente pour charger les départements.';

  @override
  String get chooseYourDepartmentHint => 'Choisissez votre département';

  @override
  String get pleaseSelectDepartment =>
      'Veuillez sélectionner votre département';

  @override
  String get noDepartmentsFound =>
      'Aucun département trouvé pour cet établissement.';

  @override
  String get agreeToTermsPrefix => 'J\'accepte les ';

  @override
  String get termsOfServiceLink => 'Conditions d\'utilisation';

  @override
  String get andSeparator => ' et la ';

  @override
  String get privacyPolicyLink => 'Politique de confidentialité';

  @override
  String get agreeToTermsRequired =>
      'Vous devez accepter les Conditions d\'utilisation et la Politique de confidentialité pour continuer';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get accountProfileTitle => 'Profil du compte';

  @override
  String get accountProfileSubtitle =>
      'Consultez et modifiez vos informations personnelles';

  @override
  String get adminDashboardTitle => 'Tableau de bord admin';

  @override
  String get adminDashboardSubtitle =>
      'Gérez les utilisateurs, rôles et départements';

  @override
  String get aiCreditsPlansTitle => 'Crédits IA et forfaits';

  @override
  String aiCreditsRemaining(int count) {
    return '$count crédits restants';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Gérez vos alertes et préférences de messages';

  @override
  String get darkModeTitle => 'Mode sombre';

  @override
  String get darkModeSubtitle => 'Basculez entre les thèmes clair et sombre';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get privacyPolicySubtitle =>
      'Comment nous protégeons et utilisons vos données';

  @override
  String get termsOfServiceTitle => 'Conditions d\'utilisation';

  @override
  String get termsOfServiceSubtitle => 'Les règles d\'utilisation de GO Study';

  @override
  String get supportGoStudyTitle => 'Soutenir Go Study';

  @override
  String get supportGoStudySubtitle =>
      'Sponsorisez le développement ou proposez votre aide';

  @override
  String get sendFeedbackTitle => 'Envoyer un avis';

  @override
  String get sendFeedbackSubtitle =>
      'Signalez un bug ou proposez une amélioration';

  @override
  String get developerInformationTitle => 'Informations développeur';

  @override
  String get developerInformationSubtitle =>
      'Version de l\'application, build et détails techniques';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutSubtitle => 'En savoir plus sur l\'application ';

  @override
  String get logout => 'Déconnexion';

  @override
  String get appLanguageTitle => 'Langue';

  @override
  String get appLanguageSubtitle => 'Choisissez la langue de l\'application';

  @override
  String get languageSystemDefault => 'Par défaut du système';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get homeToolAiStudy => 'Étude IA';

  @override
  String get homeToolExamSchedule => 'Calendrier d\'examens';

  @override
  String get homeToolPerformance => 'Performance';

  @override
  String get homeToolLibrary => 'Bibliothèque';

  @override
  String get homeToolNews => 'Actualités';

  @override
  String get homeToolMarketplace => 'Marché';

  @override
  String get homeToolTaskManager => 'Gestion des tâches';

  @override
  String get homeToolFocusTimer => 'Minuteur de concentration';

  @override
  String get homeToolTranscripts => 'Relevés de notes';

  @override
  String get homeToolPortal => 'PORTAIL';

  @override
  String get homeToolSupportBot => 'Bot d\'assistance UB';

  @override
  String get sectionDepartmentsFaculties => 'Départements et facultés';

  @override
  String get sectionTools => 'OUTILS';

  @override
  String get noDepartmentsAvailable =>
      'Aucun département disponible pour le moment.';

  @override
  String get exploreResources => 'Explorer les ressources';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get scholarFallbackName => 'Étudiant';

  @override
  String homeTrialLabel(String time) {
    return 'Essai : $time';
  }

  @override
  String get resumeLearningLabel => 'Reprendre l\'apprentissage';

  @override
  String get studentFallbackName => 'Étudiant';

  @override
  String get unifiedAcademicPortal => 'Portail académique unifié';

  @override
  String get noConnectionTitle => 'Pas de connexion';

  @override
  String get noConnectionBody =>
      'Veuillez vérifier votre connexion internet et réessayer.';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get globalChatTooltip => 'Chat global';

  @override
  String get examSchedulePleaseSignIn =>
      'Veuillez vous connecter pour voir votre calendrier.';

  @override
  String get allEventsListTitle => 'Liste de tous les événements';

  @override
  String get noEventsScheduled => 'Aucun événement programmé pour le moment.';

  @override
  String get tbd => 'À déterminer';

  @override
  String get pleaseSignInMessage => 'Veuillez vous connecter';

  @override
  String get addTaskDialogTitle => 'Ajouter une tâche';

  @override
  String get newTaskTitle => 'Nouvelle tâche';

  @override
  String get newTaskSubtitle => 'Que faut-il faire ?';

  @override
  String get taskNameLabel => 'Nom de la tâche';

  @override
  String get taskNameHint => 'ex. Étudier la physique';

  @override
  String get taskDescriptionLabel => 'Description';

  @override
  String get taskDescriptionHint => 'Brefs détails...';

  @override
  String get deadlineLabel => 'Échéance';

  @override
  String get reminderLabel => 'Rappel';

  @override
  String taskProgressLabel(int percent) {
    return 'Progression : $percent%';
  }

  @override
  String get priorityLabel => 'Priorité';

  @override
  String get selectPriorityHint => 'Sélectionnez la priorité';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get selectCategoryHint => 'Sélectionner une catégorie';

  @override
  String get createTaskButton => 'Créer la tâche';

  @override
  String get taskReminderNotifTitle => 'Rappel de tâche';

  @override
  String taskReminderNotifBody(String title) {
    return 'N\'oubliez pas : $title';
  }

  @override
  String get setLabel => 'Définir';

  @override
  String get priorityLow => 'Faible';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityHigh => 'Élevée';

  @override
  String get categoryAll => 'Toutes';

  @override
  String get categoryAcademic => 'Académique';

  @override
  String get categoryPersonal => 'Personnel';

  @override
  String get categoryResearch => 'Recherche';

  @override
  String get categorySideProjects => 'Projets personnels';

  @override
  String get toDoListTitle => 'Liste de tâches';

  @override
  String get searchTasksHint => 'Rechercher des tâches...';

  @override
  String get noTasksFound => 'Aucune tâche trouvée';

  @override
  String get taskGroupOverdue => 'En retard';

  @override
  String get taskGroupToday => 'Aujourd\'hui';

  @override
  String get taskGroupUpcoming => 'À venir';

  @override
  String get taskGroupCompleted => 'Terminées';

  @override
  String get noDeadlineLabel => 'Aucune échéance';

  @override
  String deadlineDisplay(String date) {
    return 'Échéance : $date';
  }

  @override
  String get focusCompleteNotifTitle => 'Concentration terminée !';

  @override
  String get focusCompleteNotifBody => 'Bon travail ! Prenez une courte pause.';

  @override
  String get focusModeTitle => 'Mode concentration';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get focusStatusFocusing => 'CONCENTRATION';

  @override
  String get focusStatusIdle => 'INACTIF';

  @override
  String get focusPause => 'PAUSE';

  @override
  String get focusEngage => 'DÉMARRER';

  @override
  String get focusReset => 'RÉINITIALISER';

  @override
  String get customizeTimerTitle => 'Personnaliser le minuteur';

  @override
  String get quickPresetsLabel => 'PRÉRÉGLAGES RAPIDES';

  @override
  String get customDurationLabel => 'DURÉE PERSONNALISÉE';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get applyAndClose => 'Appliquer et fermer';

  @override
  String get offlineLibraryTitle => 'Bibliothèque hors ligne';

  @override
  String get offlineLibraryEmptyTitle =>
      'Votre bibliothèque hors ligne est vide.';

  @override
  String get offlineLibraryEmptyBody =>
      'Téléchargez des supports pour y accéder sans connexion.';

  @override
  String localCopySuffix(String category) {
    return '$category • Copie locale';
  }

  @override
  String get offlineFormatNotSupported =>
      'Format non pris en charge pour la consultation hors ligne pour le moment';

  @override
  String get deleteOfflineCopyTitle => 'Supprimer la copie hors ligne ?';

  @override
  String get removeFromDeviceSubtitle => 'Retirer de l\'appareil';

  @override
  String deleteOfflineCopyBody(String title) {
    return 'Cela supprimera la copie sécurisée de « $title » de votre appareil. Vous pourrez la retélécharger dès que vous serez en ligne.';
  }

  @override
  String get deleteNowButton => 'Supprimer maintenant';

  @override
  String get universityNewsTitle => 'Actualités universitaires';

  @override
  String get refreshNewsTooltip => 'Actualiser';

  @override
  String get couldntFetchNews => 'Impossible de récupérer les actualités';

  @override
  String get unexpectedErrorTryLater =>
      'Une erreur inattendue s\'est produite. Veuillez réessayer plus tard.';

  @override
  String get noAnnouncementsYet => 'Aucune annonce pour le moment.';

  @override
  String get readFullArticle => 'Lire l\'article complet';

  @override
  String get performanceTrackerTitle => 'Suivi de performance';

  @override
  String get switchToListTooltip => 'Basculer vers la liste';

  @override
  String get switchToPredictorTooltip => 'Basculer vers le prédicteur';

  @override
  String get addGradeButton => 'Ajouter une note';

  @override
  String get currentGpaLabel => 'Moyenne actuelle';

  @override
  String get totalCreditsLabel => 'Total des crédits';

  @override
  String get gradePredictorTitle => 'Prédicteur de notes';

  @override
  String get targetGpaLabel => 'Moyenne cible';

  @override
  String get plannedCreditsLabel => 'Crédits prévus';

  @override
  String get adviceImpossibleTarget =>
      'Mathématiquement impossible ce semestre. Essayez un objectif plus bas.';

  @override
  String get adviceOnTrack =>
      'Vous vous en sortez très bien ! Même une note basse maintiendra votre objectif.';

  @override
  String adviceNeedAverage(String grade, String target) {
    return 'Vous avez besoin d\'une moyenne de $grade pour atteindre $target.';
  }

  @override
  String get semesterResultsTitle => 'Résultats du semestre';

  @override
  String coursesCount(int count) {
    return '$count cours';
  }

  @override
  String get noGradesSavedYet =>
      'Aucune note enregistrée pour le moment. Utilisez le bouton « + » pour ajouter vos résultats.';

  @override
  String creditsAndSemester(int credits, String semester) {
    return '$credits crédits • $semester';
  }

  @override
  String get unknownSemester => 'Semestre inconnu';

  @override
  String get addResultDialogTitle => 'Ajouter un résultat';

  @override
  String get addResultDialogSubtitle => 'Enregistrez votre réussite académique';

  @override
  String get courseNameLabel => 'Nom du cours';

  @override
  String get courseNameHint => 'ex. CSC 201';

  @override
  String get creditsLabel => 'Crédits';

  @override
  String get selectCreditsHint => 'Sélectionnez les crédits';

  @override
  String get gradeLabel => 'Note';

  @override
  String get selectGradeHint => 'Sélectionnez la note';

  @override
  String get semesterLabel => 'Semestre';

  @override
  String get selectSemesterHint => 'Sélectionnez le semestre';

  @override
  String get firstSemester => 'Premier semestre';

  @override
  String get secondSemester => 'Deuxième semestre';

  @override
  String get saveResultButton => 'Enregistrer le résultat';

  @override
  String get aiStudyPlanTitle => 'Plan d\'étude IA';

  @override
  String get regeneratePlanTooltip => 'Régénérer le plan';

  @override
  String get aiAnalyzingSchedule => 'L\'IA analyse votre emploi du temps...';

  @override
  String get readyForSmarterStudyTitle =>
      'Prêt pour une session d\'étude plus intelligente ?';

  @override
  String get readyForSmarterStudyBody =>
      'J\'analyserai vos tâches en attente et vos examens à venir pour créer une routine équilibrée rien que pour vous.';

  @override
  String get generateMyPlanButton => 'GÉNÉRER MON PLAN';

  @override
  String get aiPlanDisclaimer =>
      'Ce plan est généré par IA et fourni à titre indicatif uniquement.';

  @override
  String get supportBotWelcomeMessage =>
      'Bienvenue au centre d\'assistance de l\'Université de Buea ! Je suis votre bot d\'assistance UB. Comment puis-je vous aider avec vos questions universitaires aujourd\'hui ?';

  @override
  String get supportBotConnectionTrouble =>
      'Désolé, j\'ai des difficultés à me connecter en ce moment. Veuillez vérifier votre connexion internet ou réessayer plus tard.';

  @override
  String get connectionInterrupted => 'Connexion interrompue.';

  @override
  String get universityOfBueaAssistant => 'Assistant de l\'Université de Buea';

  @override
  String get manageKnowledgeTooltip => 'Gérer les connaissances';

  @override
  String get askBasedOnDataHint =>
      'Posez une question basée sur vos données...';

  @override
  String get failedToLoadChatHistory =>
      'Impossible de charger l\'historique des discussions. Veuillez vérifier votre connexion.';

  @override
  String get newFileAnalysisTitle => 'Nouvelle analyse de fichier';

  @override
  String get messageSyncFailed =>
      'Échec de la synchronisation du message. L\'historique local peut être obsolète.';

  @override
  String get outOfAiCreditsMessage => 'Vous n\'avez plus de crédits IA.';

  @override
  String get aiThinkingPlaceholder =>
      'J\'analyse votre demande et je traite les informations pour fournir une réponse complète...';

  @override
  String sorryEncounteredError(String error) {
    return 'Désolé, j\'ai rencontré une erreur : $error';
  }

  @override
  String sorryEncounteredCriticalError(String error) {
    return 'Désolé, j\'ai rencontré une erreur critique : $error';
  }

  @override
  String get deleteChatDialogTitle => 'Supprimer la discussion';

  @override
  String get deleteChatDialogSubtitle => 'Cette action est irréversible';

  @override
  String get deleteChatConfirmBody =>
      'Êtes-vous sûr de vouloir supprimer cette conversation ? Tous les messages seront définitivement supprimés.';

  @override
  String get aiAssistantTitle => 'Assistant IA';

  @override
  String get howCanIHelpTodayMessage =>
      'Comment puis-je vous aider aujourd\'hui ?';

  @override
  String get quickStarterCalculus => '📈 Aide-moi avec le calcul';

  @override
  String get quickStarterStudyPlan => '📝 Rédiger un plan d\'étude';

  @override
  String get quickStarterProjectIdeas => '💡 Idées de projets';

  @override
  String get quickStarterSummarizeNotes => '📚 Résumer des notes';

  @override
  String get thinkingLabel => 'Réflexion';

  @override
  String get stopButton => 'Arrêter';

  @override
  String get askAiHint => 'Demander à l\'IA';

  @override
  String get newChatButton => 'Nouvelle discussion';

  @override
  String get noRecentChats => 'Aucune discussion récente';

  @override
  String get clearAllChatsListTile => 'Effacer toutes les discussions';

  @override
  String get clearAllChatsDialogTitle => 'Effacer toutes les discussions';

  @override
  String get clearAllChatsDialogSubtitle => 'Repartir sur une base saine';

  @override
  String get clearAllChatsConfirmBody =>
      'Êtes-vous sûr de vouloir supprimer toutes les conversations ? Cette action supprimera définitivement tout votre historique de discussions.';

  @override
  String get clearAllButton => 'Tout effacer';

  @override
  String get showThinkingLabel => 'Afficher la réflexion';

  @override
  String get codeCopiedToClipboard => 'Code copié dans le presse-papiers';

  @override
  String get copyButton => 'Copier';

  @override
  String get privateChatTitle => 'Discussion privée';

  @override
  String get privateMessageSubtitle => 'Message privé';

  @override
  String get loadingLabel => 'Chargement...';

  @override
  String get tryAgainButton => 'Réessayer';

  @override
  String get noQuestionsFound => 'Aucune question trouvée.';

  @override
  String correctAnswerLabel(String answer) {
    return 'Bonne réponse : $answer';
  }

  @override
  String get reloadButton => 'Recharger';

  @override
  String get navHomeLabel => 'Accueil';

  @override
  String get navDepartmentsLabel => 'Départements';

  @override
  String get navAiAssistantLabel => 'Assistant IA';

  @override
  String get navMessagesLabel => 'Messages';

  @override
  String get navSettingsLabel => 'Paramètres';

  @override
  String get studentPortalTitle => 'Portail étudiant';

  @override
  String get syncingAcademicDataLabel =>
      'Synchronisation des données académiques...';

  @override
  String get reloadPageMenuItem => 'Recharger la page';

  @override
  String get copyPortalLinkMenuItem => 'Copier le lien du portail';

  @override
  String get linkCopiedToClipboard => 'Lien copié dans le presse-papiers';

  @override
  String get openInExternalBrowserMenuItem =>
      'Ouvrir dans le navigateur externe';

  @override
  String get allDepartmentsTitle => 'Tous les départements';

  @override
  String get searchForDepartmentHint => 'Rechercher un département...';

  @override
  String get newDeptButton => 'Nouveau départ.';

  @override
  String get findFriendsTitle => 'Trouver des amis';

  @override
  String get searchByNameHint => 'Rechercher par nom…';

  @override
  String get searchForStudentsToAdd => 'Rechercher des étudiants à ajouter';

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get friendsStatusChip => 'Amis';

  @override
  String get pendingStatusChip => 'En attente';

  @override
  String get requestedYouStatusChip => 'Vous a demandé';

  @override
  String get addFriendButton => 'Ajouter';

  @override
  String get unknownUserName => 'Inconnu';

  @override
  String get findFriendsTooltip => 'Trouver des amis';

  @override
  String pendingCountLabel(int count) {
    return '$count en attente';
  }

  @override
  String get friendRequestsLabel => 'Demandes d\'amis';

  @override
  String get noFriendsYetTitle => 'Pas encore d\'amis';

  @override
  String get tapIconToFindFriends =>
      'Appuyez sur l\'icône ci-dessus pour trouver\net ajouter des camarades étudiants';

  @override
  String get yesterdayLabel => 'Hier';

  @override
  String get sendMessageLabel => 'Envoyer un message';

  @override
  String get removeFriendLabel => 'Retirer l\'ami';

  @override
  String get noMessagesYetLabel => 'Aucun message pour le moment';

  @override
  String get acceptTooltip => 'Accepter';

  @override
  String get declineTooltip => 'Refuser';

  @override
  String get profileTitle => 'Profil';

  @override
  String get defaultUserName => 'Utilisateur';

  @override
  String get betaMemberBadge => 'MEMBRE BÊTA';

  @override
  String get openAdminDashboardButton => 'Ouvrir le tableau de bord admin';

  @override
  String trialEndsInLabel(String time) {
    return 'L\'essai se termine dans : $time';
  }

  @override
  String get personalInformationTitle => 'Informations personnelles';

  @override
  String get notSetValue => 'Non défini';

  @override
  String get matriculeLabel => 'Matricule';

  @override
  String get notProvidedValue => 'Non fourni';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get currentLevelLabel => 'Niveau actuel';

  @override
  String get departmentLabel => 'Département';

  @override
  String get bioLabel => 'Bio';

  @override
  String get noBioYetValue => 'Pas encore de bio';

  @override
  String get unlimitedAccessTitle => 'Accès illimité';

  @override
  String get unlimitedAccessSubtitle =>
      'Vous pouvez désormais tout téléverser et télécharger gratuitement.';

  @override
  String get signOutTitle => 'Se déconnecter';

  @override
  String get signOutConfirmBody =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get changeAvatarTitle => 'Changer l\'avatar';

  @override
  String get galleryOption => 'Galerie';

  @override
  String get cameraOption => 'Appareil photo';

  @override
  String get appAppearanceTitle => 'Apparence de l\'application';

  @override
  String get accentColorLabel => 'Couleur d\'accentuation';

  @override
  String get roleAdmin => 'ADMIN';

  @override
  String get roleContributor => 'CONTRIBUTEUR';

  @override
  String get roleViewer => 'VISITEUR';

  @override
  String get adminAccessRequired => 'Accès administrateur requis.';

  @override
  String get manageDepartmentsTitle => 'Gérer les départements';

  @override
  String get manageUsersTitle => 'Gérer les utilisateurs';

  @override
  String get adminAccessLabel => 'Accès administrateur';

  @override
  String get administratorFallback => 'Administrateur';

  @override
  String get institutionFallback => 'Institution';

  @override
  String get myProfileTitle => 'Mon profil';

  @override
  String get reviewYourAccountSubtitle => 'Consulter votre compte';

  @override
  String get noDepartmentsAvailableYet =>
      'Aucun département disponible pour le moment.';

  @override
  String get noDescriptionAvailable => 'Aucune description disponible.';

  @override
  String schoolLabel(String schoolId) {
    return 'École : $schoolId';
  }

  @override
  String get schoolNotSet => 'École non définie';

  @override
  String get searchNameMatriculeHint =>
      'Rechercher par nom, matricule ou département';

  @override
  String get searchForUserLabel => 'Rechercher un utilisateur';

  @override
  String get unknownUserFallback => 'Utilisateur inconnu';

  @override
  String get noMatriculeFallback => 'Aucun matricule';

  @override
  String get roleLabelAdmin => 'Admin';

  @override
  String get roleLabelContributor => 'Contributeur';

  @override
  String promoteToRoleTitle(String role) {
    return 'Promouvoir en $role';
  }

  @override
  String promoteUserConfirmBody(String name, String role) {
    return 'Promouvoir $name en $role ?';
  }

  @override
  String get thisUserFallback => 'cet utilisateur';

  @override
  String get promoteButton => 'Promouvoir';

  @override
  String userIsNowRoleLabel(String name, String role) {
    return '$name est maintenant $role';
  }

  @override
  String get globalChatTitle => 'Discussion globale';

  @override
  String get activeNowLabel => 'Actif maintenant';

  @override
  String get aboutGlobalChatLabel => 'À propos de la discussion globale';

  @override
  String get connectWithPeersSubtitle => 'Connectez-vous avec vos pairs';

  @override
  String get globalChatDescription =>
      'Il s\'agit d\'un salon de discussion en temps réel pour tous les utilisateurs de GO-Study spécifique à ce cours. Veuillez être respectueux et suivre les règles de la communauté.';

  @override
  String get gotItButton => 'Compris';

  @override
  String errorLoadingMessages(String error) {
    return 'Erreur : $error';
  }

  @override
  String get noMessagesYetSayHi => 'Pas encore de messages. Dites bonjour !';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get sendAMessageHint => 'Envoyer un message';

  @override
  String replyingToLabel(String name) {
    return 'Réponse à $name';
  }

  @override
  String get anonymousFallback => 'Anonyme';

  @override
  String get quickReviewTitle => 'Aperçu rapide';

  @override
  String get aiGeneratedSummarySubtitle => 'Résumé du document généré par IA';

  @override
  String get predictQuestionsBarrierLabel => 'Prédire des questions';

  @override
  String get predictExamQuestionsTitle => 'Prédire les questions d\'examen';

  @override
  String get generatePracticeQuizSubtitle =>
      'Générer un quiz d\'entraînement à partir de ce document';

  @override
  String get chooseDifficultyLevel => 'Choisissez un niveau de difficulté';

  @override
  String get generateQuizButton => 'Générer le quiz';

  @override
  String get tableOfContentsTitle => 'Table des matières';

  @override
  String get navigateThroughDocumentSubtitle => 'Naviguer dans le document';

  @override
  String get noBookmarksFoundMessage => 'Aucun signet trouvé dans ce document';

  @override
  String get searchInDocumentHint => 'Rechercher dans le document...';

  @override
  String get searchTooltip => 'Rechercher';

  @override
  String get chatWithPdfTooltip => 'Discuter avec le PDF';

  @override
  String get downloadTooltip => 'Télécharger';

  @override
  String get askAnythingAboutDocumentHint =>
      'Posez une question sur ce document...';

  @override
  String get joinDiscussionTooltip => 'Rejoindre la discussion';

  @override
  String courseDiscussionTitle(String code) {
    return 'Discussion $code';
  }

  @override
  String get courseDiscussionRoomSubtitle => 'Salon de discussion du cours';

  @override
  String get noMaterialsYetMessage =>
      'Aucun document pour ce cours pour le moment.';

  @override
  String get generalResourcesHeader => 'Ressources générales';

  @override
  String get pastQuestionsAndAnswersHeader => 'Questions et réponses passées';

  @override
  String get pqBadge => 'QP';

  @override
  String get ansBadge => 'RÉP';

  @override
  String get docBadge => 'DOC';

  @override
  String get deleteMaterialDialogTitle => 'Supprimer le document ?';

  @override
  String confirmDeleteMaterialBody(String title) {
    return 'Êtes-vous sûr de vouloir supprimer $title ? Cette action est irréversible.';
  }

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get materialDeletedMessage => 'Document supprimé';

  @override
  String get downloadMenuItem => 'Télécharger';

  @override
  String get materialSecuredOfflineMessage =>
      'Document sécurisé pour un accès hors ligne ! 🔒';

  @override
  String pastQuestionAnswersCountSubtitle(int count) {
    return 'Question passée • $count réponses';
  }

  @override
  String get deletePastQuestionDialogTitle => 'Supprimer la question passée ?';

  @override
  String get pastQuestionDeletedMessage => 'Question passée supprimée';

  @override
  String get noAnswersUploadedYet => 'Aucune réponse téléversée pour le moment';

  @override
  String verifiedAnswerFeeSubtitle(int fee) {
    return 'Réponse vérifiée • $fee XAF';
  }

  @override
  String get onlyContributorsCanUploadMessage =>
      'Seuls les contributeurs et administrateurs peuvent téléverser du contenu.';

  @override
  String get addMaterialTitle => 'Ajouter un document';

  @override
  String get shareResourcesSubtitle => 'Partagez des ressources avec vos pairs';

  @override
  String get generalMaterialOption => 'Document général';

  @override
  String get pastQuestionOption => 'Question passée';

  @override
  String get answerOption => 'Réponse';

  @override
  String get linkToQuestionLabel => 'Lier à une question';

  @override
  String get selectTheQuestionHint => 'Sélectionner la question';

  @override
  String get requiredValidator => 'Requis';

  @override
  String get titleLabel => 'Titre';

  @override
  String get titleHintExample => 'ex. Notes d\'introduction à Java';

  @override
  String get descriptionOptionalLabel => 'Description (Optionnel)';

  @override
  String get brieflyDescribeContentHint => 'Décrivez brièvement le contenu';

  @override
  String get selectMaterialFileLabel => 'Sélectionner le fichier';

  @override
  String get fileSelectedSuccessfully => 'Fichier sélectionné avec succès';

  @override
  String get uploadPdfOrWordHint => 'Téléverser un PDF ou Word';

  @override
  String get supportsPdfDocImagesHint => 'Prend en charge PDF, DOC, Images';

  @override
  String get uploadMaterialButton => 'Téléverser le document';

  @override
  String get pleaseSelectFileMessage => 'Veuillez sélectionner un fichier';

  @override
  String get uploadSuccessfulMessage => 'Téléversement réussi !';

  @override
  String get selectMaterialTypeSubtitle =>
      'Sélectionnez le type de document que vous souhaitez partager';

  @override
  String get lectureNotesSubtitle => 'Notes de cours, résumés, manuels';

  @override
  String get previousExamPapersSubtitle =>
      'Anciens sujets d\'examen ou de test';

  @override
  String get solutionsToPastQuestionsSubtitle =>
      'Solutions aux questions passées';

  @override
  String get verifiedAnswerTitle => 'Réponse vérifiée';

  @override
  String get communityContributionCodeTitle =>
      'Code de contribution communautaire';

  @override
  String get guidelineReadableContent =>
      'Assurez-vous que le contenu est lisible, correct et adapté à l\'étude.';

  @override
  String get guidelineCheckDuplicate =>
      'Vérifiez si cette ressource a déjà été téléversée.';

  @override
  String get guidelineAcademicOnly =>
      'Ne téléversez que des documents académiques et éducatifs.';

  @override
  String get deleteDepartmentDialogTitle => 'Supprimer le département ?';

  @override
  String confirmDeleteDepartmentBody(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name ? Cela supprimera tous les cours et documents qu\'il contient. Cette action est irréversible.';
  }

  @override
  String get departmentDeletedMessage => 'Département supprimé';

  @override
  String get deleteDepartmentMenuItem => 'Supprimer le département';

  @override
  String get aboutTabLabel => 'À propos';

  @override
  String get coursesTabLabel => 'Cours';

  @override
  String get docsTabLabel => 'Docs';

  @override
  String get chatTabLabel => 'Discussion';

  @override
  String departmentGroupTitle(String name) {
    return 'Groupe $name';
  }

  @override
  String get departmentalStudyGroupSubtitle => 'Groupe d\'étude départemental';

  @override
  String get uploadButton => 'Téléverser';

  @override
  String get aboutDepartmentHeader => 'À propos du département';

  @override
  String get descriptionHeader => 'Description';

  @override
  String get departmentDescriptionPlaceholder =>
      'Les détails et descriptions de ce département apparaîtront ici. Les étudiants peuvent trouver des informations générales, des détails sur le corps enseignant, et plus encore.';

  @override
  String get noCoursesFoundMessage => 'Aucun cours trouvé !';

  @override
  String levelHeader(String level) {
    return 'Niveau $level';
  }

  @override
  String get otherCoursesHeader => 'Autres cours';

  @override
  String get courseDeletedMessage => 'Cours supprimé';

  @override
  String get deleteCourseMenuItem => 'Supprimer le cours';

  @override
  String get courseMaterialsTooltip => 'Documents du cours';

  @override
  String get noMaterialsYetShort => 'Aucun document pour le moment';

  @override
  String get noResourcesAvailableMessage => 'Aucune ressource disponible';

  @override
  String get noPastQuestionsAvailableMessage =>
      'Aucune question passée disponible';

  @override
  String get downloadMaterialTitle => 'Télécharger le document';

  @override
  String get secureAccessSubtitle => 'Accès sécurisé aux ressources d\'étude';

  @override
  String downloadFeeNotice(String title, String category, int fee) {
    return 'Pour télécharger \"$title\" ($category), des frais de $fee XAF sont requis.';
  }

  @override
  String get paymentPhoneLabel => 'Téléphone de paiement';

  @override
  String get paymentPhoneHint => '6xxxxxxxx (MTN/Orange)';

  @override
  String get payAndDownloadButton => 'Payer et télécharger';

  @override
  String get beFirstToContributeMessage =>
      'Soyez le premier à contribuer aux ressources de ce département !';

  @override
  String get addNewButton => 'Ajouter';

  @override
  String get addNewCourseMenuItem => 'Ajouter un nouveau cours';

  @override
  String get uploadDepartmentResourceMenuItem =>
      'Téléverser une ressource du département';

  @override
  String get uploadCourseMaterialMenuItem => 'Téléverser un document de cours';

  @override
  String get addCourseFirstMessage => 'Ajoutez d\'abord un cours !';

  @override
  String get uploadPastQuestionMenuItem => 'Téléverser une question passée';

  @override
  String get uploadAnswerMenuItem => 'Téléverser une réponse';

  @override
  String get selectCourseTitle => 'Sélectionner un cours';

  @override
  String get whichCourseSubtitle => 'Pour quel cours est-ce ?';

  @override
  String courseLevelCodeSubtitle(String level, String code) {
    return 'Niveau $level • $code';
  }

  @override
  String get deptResourceTitle => 'Ressource du département';

  @override
  String get shareFacultyWideDocsSubtitle =>
      'Partager des documents à l\'échelle de la faculté';

  @override
  String addResourcesForCourseSubtitle(String name) {
    return 'Ajouter des ressources pour $name';
  }

  @override
  String get courseFallback => 'Cours';

  @override
  String courseLabelPrefix(String name) {
    return 'Cours : $name';
  }

  @override
  String get generalOption => 'Général';

  @override
  String get resourceTitleHintExample => 'ex. Notes de révision d\'examen';

  @override
  String get briefResourceDetailsHint => 'Détails brefs sur la ressource';

  @override
  String get selectResourceFileLabel => 'Sélectionner le fichier de ressource';

  @override
  String get readyForUploadLabel => 'Prêt à être téléversé';

  @override
  String get pdfDocImagesOnlyHint => 'PDF, DOC ou Images uniquement';

  @override
  String get uploadResourceButton => 'Téléverser la ressource';

  @override
  String get onlyAdminsCanAddCoursesMessage =>
      'Seuls les administrateurs peuvent ajouter de nouveaux cours.';

  @override
  String get deleteCourseDialogTitle => 'Supprimer le cours ?';

  @override
  String get aiCreditsRequiredTitle => 'Crédits IA requis';

  @override
  String get outOfAiCreditsBody =>
      'Vous n\'avez plus de crédits IA. Passez à un forfait premium ou rechargez vos crédits pour continuer à utiliser Gemini Academic.';

  @override
  String get get50CreditsTitle => 'Obtenir 50 crédits';

  @override
  String get only500XafSubtitle => 'Seulement 500 XAF';

  @override
  String get notNowButton => 'Pas maintenant';

  @override
  String get topUpButton => 'Recharger';

  @override
  String get rateUsBarrierLabel => 'Notez-nous';

  @override
  String get rateUsTitle => 'Notez-nous !';

  @override
  String get helpUsImproveSubtitle => 'Aidez-nous à améliorer Ub-Hub';

  @override
  String get rateUsBody =>
      'Si vous aimez utiliser Ub-Hub, prenez un moment pour nous noter. Votre avis est précieux !';

  @override
  String get laterButton => 'Plus tard';

  @override
  String get rateNowButton => 'Noter maintenant';

  @override
  String get feedbackTitle => 'Retour d\'expérience';

  @override
  String get loveToHearFromYouTitle =>
      'Nous aimerions avoir de vos nouvelles !';

  @override
  String get feedbackBodyText =>
      'Vous avez trouvé un bug ? Une suggestion ? Envoyez-nous un e-mail et aidez-nous à améliorer Ub-Hub.';

  @override
  String get sendEmailButton => 'Envoyer un e-mail';

  @override
  String get trialPeriodEndedTitle => 'Période d\'essai terminée';

  @override
  String get trialExpiredBody =>
      'Votre accès gratuit de 4 jours à GoStudy a expiré. Passez à un forfait premium pour débloquer votre tableau de bord académique, le bot d\'assistance UB et des ressources illimitées.';

  @override
  String get viewUpgradePlansButton => 'Voir les forfaits';

  @override
  String get addCourseTitle => 'Ajouter un cours';

  @override
  String get organizeAcademicContentSubtitle =>
      'Organisez votre contenu académique';

  @override
  String get courseNameHintExample => 'ex. Structures de données';

  @override
  String get pleaseEnterCourseName => 'Veuillez saisir un nom de cours';

  @override
  String get courseCodeLabel => 'Code du cours';

  @override
  String get courseCodeHintExample => 'ex. CS201';

  @override
  String get pleaseEnterCourseCode => 'Veuillez saisir un code de cours';

  @override
  String get levelLabel => 'Niveau';

  @override
  String get selectAcademicLevelHint => 'Sélectionner un niveau académique';

  @override
  String get userNotAuthenticatedMessage => 'Utilisateur non authentifié';

  @override
  String get aboutAppTitle => 'À propos de l\'application';

  @override
  String get appDescriptionBody =>
      'GO-Study est votre compagnon académique ultime, spécialement conçu pour la communauté étudiante de l\'Université de Buea. Des plans d\'étude pilotés par IA aux calendriers d\'examens en temps réel et à la collaboration mondiale entre pairs, nous vous donnons les outils techniques nécessaires pour naviguer votre parcours académique avec excellence et facilité.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get licensesLegalTitle => 'Licences et mentions légales';

  @override
  String get openSourceLibrariesSubtitle =>
      'Bibliothèques open source et informations légales';

  @override
  String get appLegaleseCopyright => '© 2026 Jovial Studio';

  @override
  String get aboutDialogDescription =>
      'GO-Study est un compagnon académique conçu pour les étudiants de l\'Université de Buea. Il offre un accès facile aux ressources, à l\'assistance d\'étude par IA, à la gestion des cours et à des outils de collaboration entre pairs pour vous aider à exceller dans votre parcours académique.';

  @override
  String get eventsCalendarTitle => 'Calendrier des événements';

  @override
  String get eventIdLabel => 'ID de l\'événement';

  @override
  String get eventNameLabel => 'Nom de l\'événement';

  @override
  String get eventCategoryLabel => 'Catégorie de l\'événement';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get noDescriptionProvided => 'Aucune description fournie.';

  @override
  String get venueLabel => 'Lieu';

  @override
  String get tbdValue => 'À déterminer';

  @override
  String get eventStartTimeLabel => 'Heure de début';

  @override
  String get eventEndTimeLabel => 'Heure de fin';

  @override
  String get eventStatusLabel => 'Statut de l\'événement';

  @override
  String get eventImageLabel => 'Image de l\'événement';

  @override
  String get addCommentButton => 'Ajouter un commentaire';

  @override
  String get deleteEventTitle => 'Supprimer l\'événement';

  @override
  String get confirmDeleteEventBody =>
      'Êtes-vous sûr de vouloir supprimer cet événement ? Toutes les données associées seront définitivement supprimées.';

  @override
  String get messageSellerButton => 'Message au vendeur';

  @override
  String get buyNowButton => 'Acheter maintenant';

  @override
  String get digitalPurchaseComingSoonMessage =>
      'Le processus d\'achat pour ces annonces arrive bientôt !';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get noQuestionsInQuiz => 'Aucune question trouvée dans ce quiz.';

  @override
  String get resultsTitle => 'Résultats';

  @override
  String questionCounterTitle(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get submitAnswerButton => 'VALIDER LA RÉPONSE';

  @override
  String get greatJobTitle => 'Excellent travail !';

  @override
  String get keepStudyingTitle => 'Continuez à étudier !';

  @override
  String youScoredOutOfLabel(int score, int total) {
    return 'Vous avez obtenu $score sur $total';
  }

  @override
  String accuracyPercentLabel(int percent) {
    return '$percent % de précision';
  }

  @override
  String get backToGeneratorButton => 'RETOUR AU GÉNÉRATEUR';

  @override
  String get supportDeveloperBarrierLabel => 'Soutenir le développeur';

  @override
  String get supportTheDeveloperTitle => 'Soutenir le développeur';

  @override
  String get helpKeepProjectAliveSubtitle =>
      'Aidez à maintenir le projet vivant et en croissance';

  @override
  String get supportDialogBody =>
      'Votre soutien nous aide à maintenir l\'infrastructure et à ajouter de nouvelles fonctionnalités. Tout montant est apprécié ! ❤️';

  @override
  String get amountXafLabel => 'Montant (XAF)';

  @override
  String get amountHintExample => 'ex. 500';

  @override
  String get pleaseEnterAmount => 'Veuillez saisir un montant';

  @override
  String get pleaseEnterValidAmount => 'Veuillez saisir un montant valide';

  @override
  String get phoneNumberHintPlain => '6xxxxxxxx';

  @override
  String get phoneNumberRequired => 'Numéro de téléphone requis';

  @override
  String get enterValidCameroonPhone =>
      'Saisissez un numéro de téléphone camerounais valide';

  @override
  String get supportButton => 'Soutenir';

  @override
  String get thankYouForSupportMessage =>
      'Merci pour votre généreux soutien ! ❤️';

  @override
  String get confirmApplicationTitle => 'Confirmer la demande';

  @override
  String get redirectToWhatsappBody =>
      'Vous serez redirigé vers WhatsApp pour finaliser votre demande avec notre équipe de support.';

  @override
  String get couldNotOpenWhatsappMessage =>
      'Impossible d\'ouvrir WhatsApp. Veuillez vous assurer que WhatsApp est installé.';

  @override
  String get continueToWhatsappButton => 'Continuer vers WhatsApp';

  @override
  String get transcriptApplicationTitle => 'Demande de relevé de notes';

  @override
  String get applyNowTitle => 'Postuler maintenant';

  @override
  String get requestTranscriptSubtitle =>
      'Remplissez les détails ci-dessous pour demander votre relevé de notes académique.';

  @override
  String get personalInformationSectionTitle => 'Informations personnelles';

  @override
  String get fullNameHint => 'Nom complet';

  @override
  String get enterYourNameValidator => 'Entrez votre nom';

  @override
  String get whatsappNumberHint => 'Numéro WhatsApp (ex. 6xxxxxxxx)';

  @override
  String get enterValidPhoneValidator => 'Entrez un numéro de téléphone valide';

  @override
  String get enterValidEmailValidator => 'Entrez une adresse e-mail valide';

  @override
  String get academicDetailsSectionTitle => 'Détails académiques';

  @override
  String get matriculeNumberHint => 'Numéro de matricule';

  @override
  String get enterYourMatriculeValidator => 'Entrez votre matricule';

  @override
  String get facultyHint => 'Faculté';

  @override
  String get enterYourFacultyValidator => 'Entrez votre faculté';

  @override
  String get departmentHint => 'Département';

  @override
  String get enterYourDepartmentValidator => 'Entrez votre département';

  @override
  String get applicationOptionsSectionTitle => 'Options de la demande';

  @override
  String get modeOfApplicationHint => 'Mode de demande';

  @override
  String get selectAModeValidator => 'Sélectionnez un mode';

  @override
  String get studentStatusHint => 'Statut de l\'étudiant';

  @override
  String get selectYourStatusValidator => 'Sélectionnez votre statut';

  @override
  String get submitApplicationButton => 'Soumettre la demande';

  @override
  String get modeNormal => 'Mode normal (1200 XAF)';

  @override
  String get modeFast => 'Mode rapide (2500 XAF)';

  @override
  String get modeSuperFast => 'Mode super rapide (3500 XAF)';

  @override
  String get statusCurrentStudent => 'Étudiant actuel';

  @override
  String get statusFormerStudent => 'Ancien étudiant';

  @override
  String get ubKnowledgeBaseTitle => 'Base de connaissances UB';

  @override
  String get noUbKnowledgeYet =>
      'Aucune connaissance UB ajoutée pour le moment';

  @override
  String get addUniversityFactsSubtitle =>
      'Ajoutez des faits universitaires pour que le bot les apprenne !';

  @override
  String get processingLabel => 'Traitement en cours...';

  @override
  String get uploadUbPdfButton => 'Téléverser un PDF UB';

  @override
  String get addUbInfoButton => 'Ajouter des infos UB';

  @override
  String get knowledgeScopeTitle => 'Portée des connaissances';

  @override
  String get knowledgeScopeBody =>
      'Cette information doit-elle être disponible pour tous les étudiants (Global) ou seulement pour vous (Personnel) ?';

  @override
  String get personalOption => 'Personnel';

  @override
  String get globalOption => 'Global';

  @override
  String pdfTitlePrefix(String name) {
    return 'PDF : $name';
  }

  @override
  String get pdfProcessedMessage =>
      'PDF traité et ajouté à la base de connaissances !';

  @override
  String get addUbKnowledgeBarrierLabel => 'Ajouter des connaissances UB';

  @override
  String get newUniversityInfoTitle => 'Nouvelle information universitaire';

  @override
  String get topicLabel => 'Sujet (ex. Admission)';

  @override
  String get topicHintExample => 'ex. Faculté des Arts';

  @override
  String get detailsLabel => 'Détails';

  @override
  String get provideUniversityInfoHint =>
      'Fournissez des informations spécifiques à l\'université...';

  @override
  String get makeGlobalLabel => 'Rendre global';

  @override
  String get visibleToAllUsersSubtitle => 'Visible par tous les utilisateurs';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get addDepartmentBarrierLabel => 'Ajouter un département';

  @override
  String get newDepartmentTitle => 'Nouveau département';

  @override
  String get expandAcademicEcosystemSubtitle =>
      'Développez votre écosystème académique';

  @override
  String get departmentNameLabel => 'Nom du département';

  @override
  String get departmentNameHintExample => 'ex. Informatique';

  @override
  String get nameRequiredValidator => 'Nom requis';

  @override
  String get schoolIdLabel => 'ID de l\'école';

  @override
  String get identifyParentSchoolHint => 'Identifiez l\'école parente';

  @override
  String get schoolIdRequiredValidator => 'ID de l\'école requis';

  @override
  String get whatMakesDeptUniqueHint =>
      'Qu\'est-ce qui rend ce département unique ?';

  @override
  String get descriptionRequiredValidator => 'Description requise';

  @override
  String get departmentIdentityLabel => 'Identité du département';

  @override
  String get uploadCoverPhotoLabel => 'Téléverser une photo de couverture';

  @override
  String get createDepartmentButton => 'Créer le département';

  @override
  String get developerInfoTitle => 'Infos développeur';

  @override
  String get leadDeveloperAtJovialLaps => 'Développeur principal @ Jovial Laps';

  @override
  String get engineeringDetailsSection => 'Détails techniques';

  @override
  String get appVersionLabel => 'Version de l\'application';

  @override
  String get buildNumberLabel => 'Numéro de build';

  @override
  String get frameworkLabel => 'Framework';

  @override
  String get connectSection => 'Contact';

  @override
  String get githubLabel => 'GitHub';

  @override
  String get linkedinLabel => 'LinkedIn';

  @override
  String get professionalProfileSubtitle => 'Profil professionnel';

  @override
  String get contactEmailLabel => 'E-mail de contact';

  @override
  String get directLineLabel => 'Ligne directe';

  @override
  String get builtWithLoveForUbStudents =>
      'Conçu avec ❤️ pour les étudiants de l\'UB';

  @override
  String get clearAllNotificationsTitle => 'Effacer toutes les notifications';

  @override
  String get confirmClearAllNotificationsBody =>
      'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cela supprimera définitivement votre historique d\'activité récente.';

  @override
  String get clearAllButtonShort => 'Tout effacer';

  @override
  String get pushNotificationsTitle => 'Notifications push';

  @override
  String get receiveAlertsNewCoursesSubtitle =>
      'Recevoir des alertes pour les nouveaux cours';

  @override
  String get emailUpdatesTitle => 'Mises à jour par e-mail';

  @override
  String get receiveDigestEmailsSubtitle =>
      'Recevoir des e-mails récapitulatifs';

  @override
  String get studyRemindersTitle => 'Rappels d\'étude';

  @override
  String get dailyReminderSubtitle =>
      'Rappel quotidien pour rester sur la bonne voie';

  @override
  String get recentActivityTitle => 'Activité récente';

  @override
  String get noNotificationsFound => 'Aucune notification trouvée';

  @override
  String get createNewEventTitle => 'Créer un nouvel événement';

  @override
  String get editEventTitle => 'Modifier l\'événement';

  @override
  String get eventNameHintExample => 'ex. Final d\'informatique';

  @override
  String get venueHintExample => 'ex. Amphi 700';

  @override
  String get eventDescriptionLabel => 'Description de l\'événement';

  @override
  String get addAdditionalDetailsHint =>
      'Ajoutez des détails supplémentaires...';

  @override
  String get submitButton => 'Soumettre';

  @override
  String upcomingExamNotificationTitle(String name) {
    return 'Examen à venir : $name';
  }

  @override
  String examVenueTimeNotificationBody(String venue, String time) {
    return 'Lieu : $venue @ $time';
  }

  @override
  String get categoryMidterm => 'Mi-parcours';

  @override
  String get categoryFinal => 'Final';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categoryAssignment => 'Devoir';

  @override
  String get categoryPractical => 'Pratique';

  @override
  String get categoryPresentation => 'Présentation';

  @override
  String get unlimitedLabel => 'Illimité';

  @override
  String daysRemainingLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get endingTodayLabel => 'Se termine aujourd\'hui';

  @override
  String get currentBalanceLabel => 'Solde actuel';

  @override
  String creditsCountLabel(int credits) {
    return '$credits crédits';
  }

  @override
  String get topUpAiCreditsTitle => 'Recharger les crédits IA';

  @override
  String get creditsUsageSubtitle =>
      'Les crédits sont utilisés pour les interactions avec l\'IA Gemini. Les outils académiques principaux restent gratuits pour tous.';

  @override
  String get fapshiTestModeLabel => 'MODE TEST FAPSHI';

  @override
  String get fapshiTestModeBody =>
      'Testez l\'intégration de paiement avec le bac à sable Fapshi (100 XAF). Ajoute 10 crédits de test.';

  @override
  String get pay100XafTestButton => 'Payer 100 XAF (Test)';

  @override
  String get starterPackTitle => 'Pack Débutant';

  @override
  String get studentPackTitle => 'Pack Étudiant';

  @override
  String get mostPopularLabel => 'LE PLUS POPULAIRE';

  @override
  String creditsCountAiLabel(int credits) {
    return '$credits crédits IA';
  }

  @override
  String get unlimitedAiSubscriptionsTitle => 'Abonnements IA illimités';

  @override
  String get unlimitedMonthlyTitle => 'Illimité mensuel';

  @override
  String get featureUnlimitedGeminiChat => 'Discussion IA Gemini illimitée';

  @override
  String get featureUnlimitedPdfSummaries => 'Résumés PDF illimités';

  @override
  String get featurePriorityAiResponse => 'Réponse IA prioritaire';

  @override
  String get featureAiStudyPlanGenerator => 'Générateur de plan d\'étude IA';

  @override
  String get featureStructureQuizGenerator => 'Générateur de quiz structuré';

  @override
  String get appPlanTitle => 'Forfait application';

  @override
  String get appPlanSubtitle =>
      'Téléchargements illimités et support prioritaire. Séparé des crédits/abonnement IA ci-dessus.';

  @override
  String pricePerMonthLabel(int price) {
    return '$price XAF / mois';
  }

  @override
  String get currentPlanButton => 'Forfait actuel';

  @override
  String get getUnlimitedButton => 'Obtenir l\'illimité';

  @override
  String trialActiveLeftBadge(String time) {
    return 'ESSAI ACTIF • $time RESTANT';
  }

  @override
  String get currentPlanBadge => 'FORFAIT ACTUEL';

  @override
  String get firstMonthFreeBadge => 'PREMIER MOIS GRATUIT';

  @override
  String get startFreeTrialButton => 'Démarrer l\'essai gratuit';

  @override
  String get subscribeButton => 'S\'abonner';

  @override
  String freeMonthThenPriceLabel(int price) {
    return 'Gratuit pendant 1 mois, puis $price XAF / mois';
  }

  @override
  String get aiFeaturesBilledSeparatelyShort =>
      'Les fonctionnalités IA sont facturées séparément et non incluses.';

  @override
  String get startYourFreeMonthTitle => 'Démarrez votre mois gratuit';

  @override
  String get noPaymentRequiredTodaySubtitle =>
      'Aucun paiement requis aujourd\'hui';

  @override
  String freeTrialTermsBody(int price) {
    return 'Votre forfait application est gratuit pendant les 30 premiers jours, puis se renouvelle à $price XAF/mois. Les fonctionnalités IA sont facturées séparément et ne sont pas incluses dans cet essai.';
  }

  @override
  String get freeTrialActivatedMessage => 'Essai gratuit activé !';

  @override
  String get buyCreditsBarrierLabel => 'Acheter des crédits';

  @override
  String buyPackTitle(String packName) {
    return 'Acheter $packName';
  }

  @override
  String addCreditsToBalanceSubtitle(int credits) {
    return 'Ajouter $credits crédits à votre solde';
  }

  @override
  String enterMomoNumberToPayBody(int amount) {
    return 'Entrez votre numéro MoMo/OM pour payer $amount XAF.';
  }

  @override
  String get phoneNumberHintUppercase => '6XXXXXXXX';

  @override
  String get payNowButton => 'Payer maintenant';

  @override
  String get completePaymentInBrowserShort =>
      'Terminez le paiement dans le navigateur...';

  @override
  String get waitingForApprovalMessage => 'En attente d\'approbation...';

  @override
  String creditsAddedSuccessfullyMessage(int credits) {
    return '$credits crédits ajoutés avec succès !';
  }

  @override
  String get contributorBadge => 'CONTRIBUTEUR';

  @override
  String get beACreatorTitle => 'Devenez créateur';

  @override
  String get contributorUploadBody =>
      'Téléversez vos propres documents, gagnez sur les téléchargements et débloquez tout pour toujours.';

  @override
  String get includedWithAdminContributor => 'Inclus avec Admin/Contributeur';

  @override
  String get oneTimePayment5000Xaf => 'Paiement unique de 5000 XAF';

  @override
  String subscribeToTierTitle(String tierName) {
    return 'S\'abonner à $tierName';
  }

  @override
  String get unlockPremiumToolsSubtitle =>
      'Débloquez des outils académiques premium';

  @override
  String enterMomoForDaysBody(int amount, int days) {
    return 'Entrez votre numéro Mobile Money pour payer $amount XAF pour $days jours d\'accès.';
  }

  @override
  String get completePaymentBrowserTip =>
      'Terminez le paiement dans la fenêtre du navigateur.\n\nAstuce : Restez sur la page Fapshi jusqu\'à ce que l\'invite USSD apparaisse sur votre téléphone.';

  @override
  String get checkPhoneMomoPromptTip =>
      'Vérifiez votre téléphone pour une invite MoMo.\n\nMTN : Gardez l\'écran déverrouillé.\nOrange : Composez #150*50# si un OTP est demandé.';

  @override
  String get subscriptionActivatedMessage => 'Abonnement activé !';

  @override
  String get upgradeToContributorTitle => 'Passer contributeur';

  @override
  String get unlockEverythingForeverSubtitle => 'Débloquez tout pour toujours';

  @override
  String get contributorUpgradeTermsBody =>
      'Payez 5000 XAF une fois pour débloquer des téléchargements, téléversements et fonctionnalités premium illimités pour toujours.';

  @override
  String get momoOmNumberLabel => 'Numéro Momo/OM';

  @override
  String get youAreNowContributorMessage =>
      'Vous êtes maintenant contributeur !';

  @override
  String get testCreditsPackTitle => 'Crédits de test';
}
