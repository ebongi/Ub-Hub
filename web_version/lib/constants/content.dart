/// Static marketing copy for the GoStudy website, mirrored from the
/// "GoStudy Website" design canvas.
library;

class StripItem {
  final String n;
  final String title;
  final String sub;
  const StripItem(this.n, this.title, this.sub);
}

class Shot {
  final String n;
  final String tab;
  final String src;
  final String title;
  final String body;
  const Shot(this.n, this.tab, this.src, this.title, this.body);
}

class FeatureBlock {
  final String n;
  final String title;
  final String body;
  final List<String> items;
  const FeatureBlock(this.n, this.title, this.body, this.items);
}

class WhyItem {
  final String n;
  final String title;
  final String body;
  const WhyItem(this.n, this.title, this.body);
}

class Faq {
  final String q;
  final String a;
  const Faq(this.q, this.a);
}

class LegalSection {
  final String n;
  final String title;
  final String hint;
  const LegalSection(this.n, this.title, this.hint);
}

class Processor {
  final String name;
  final String role;
  const Processor(this.name, this.role);
}

const supportEmail = 'sumeebong7@gmail.com';
const whatsappNumber = '+237 682 397 481';
const whatsappUrl = 'https://wa.me/237682397481';
const playPackage = 'com.ebongsume.gostudy';
const playStoreUrl = 'https://play.google.com/store/apps/details?id=$playPackage';
const playLabel = 'ANDROID · GOOGLE PLAY · COM.EBONGSUME.GOSTUDY';
const deletionDays = 7;

const shots = [
  Shot('01', 'HOME', 'images/shot-home.png', 'Your day, the moment you open it',
      'Tasks due, the next exam, where you left off in a course and the week at a glance — the home screen answers "what do I need to do today" before you go looking.'),
  Shot('02', 'AI ASSISTANT', 'images/shot-ai.png', 'Ask the Study Assistant anything',
      'Gemini-powered explanations that show their working. Ask in plain language, get an answer pitched at your level, and keep the thread for revision later.'),
  Shot('03', 'ALL TOOLS', 'images/shot-tools.png', 'Twelve tools, one grid',
      'AI Study, Exam Scheduler, Performance, Library, News, Marketplace, Task Manager, Focus Timer, Transcripts, PORTAL, UB Support Bot and Offline AI — all one tap from anywhere.'),
  Shot('04', 'MESSAGES', 'images/shot-dm.png', 'Your class, in one thread',
      'Global Chat for the whole campus and direct messages gated behind friend requests, so your inbox stays people you actually know.'),
  Shot('05', 'COURSES', 'images/shot-courses.png', 'Every UB course, structured',
      'Browse by faculty, department and level. Course docs, past papers and a chat per course — read the PDFs in-app and keep them offline for when the data runs out.'),
  Shot('06', 'STUDY PLAN', 'images/shot-studyplan.png', 'A revision plan built around your deadlines',
      'GoStudy reads your pending tasks and upcoming exams and lays out a balanced routine — so revision week is a schedule, not a panic.'),
  Shot('07', 'LEADERBOARD', 'images/shot-leaderboard.png', 'Study streaks worth defending',
      'Points for consistency, a level ladder and a campus-wide board. Friendly pressure from your own department beats a motivational quote.'),
];

const strip = [
  StripItem('01', 'AI Study Assistant', 'Explanations on demand'),
  StripItem('02', 'Course Materials', 'Offline library, in-app PDFs'),
  StripItem('03', 'Global Chat & DMs', 'Your campus, your class'),
  StripItem('04', 'Campus Marketplace', 'Buy, sell, swap on campus'),
  StripItem('05', 'Exams & Focus Timer', 'Plan it, then sit down to it'),
  StripItem('06', 'Language Practice', 'Lessons, cloze, word banks'),
  StripItem('07', 'Transcript Requests', 'Official, without the queue'),
];

const features = [
  FeatureBlock('F.01', 'AI study tools', 'A study partner that is awake at 2am and knows your syllabus.', [
    'Gemini-powered Study Assistant',
    'UB Support Bot for university-specific questions',
    'Offline AI chat when the data runs out',
    'AI-generated study plans',
    'Flashcards and auto-generated quizzes',
    'Language practice: lessons, cloze, matching, word banks',
  ]),
  FeatureBlock('F.02', 'Courses & materials', 'The whole UB course tree, and the documents that go with it.', [
    'Browse faculties, departments and courses',
    'Built-in PDF viewer',
    'Offline library for saved materials',
    'Performance tracking across the semester',
  ]),
  FeatureBlock('F.03', 'Productivity', 'Deadlines stop being a surprise.', [
    'Exam scheduler with reminders',
    'Focus timer for real study sessions',
    'Task manager tied to your courses',
  ]),
  FeatureBlock('F.04', 'Community', 'Campus life, minus the twelve group chats.', [
    'Global Chat for the whole campus',
    'Direct messages gated by friend requests',
    'Study leaderboard and levels',
    'Marketplace for physical and digital listings',
  ]),
  FeatureBlock('F.05', 'News', 'Official campus announcements, posted by admins.', [
    'Verified announcements only',
    'Push notification when something matters',
    'Searchable archive',
  ]),
  FeatureBlock('F.06', 'Student services', 'The paperwork, handled from your phone.', [
    'Official transcript requests',
    'Choose your delivery method',
    'Payment and status tracking end to end',
  ]),
];

const why = [
  WhyItem('W.01', 'One app, not seven',
      'Notes, chat, deadlines, past papers and transcripts stop living in five different places and one lost WhatsApp thread.'),
  WhyItem('W.02', 'AI help on demand',
      'A study assistant that explains rather than just answers — and one that still works when your data bundle does not.'),
  WhyItem('W.03', 'Connect with your class',
      'Course-level chat and friend-gated DMs mean you reach the people on your own timetable, not strangers.'),
  WhyItem('W.04', 'Official services, no queue',
      'Request a transcript, choose delivery, track payment — from your phone instead of the counter.'),
];

const faqs = [
  Faq('How do I delete my account?',
      'In the app: Settings → Delete Account → confirm. That removes your account and all associated data immediately and permanently. Without the app installed, email $supportEmail from your registered address and we handle it within $deletionDays business days. Full detail on the Delete My Account page.'),
  Faq('How do I reset my password?',
      'Tap "Forgot password?" on the login screen and enter your registered email. You will get a reset link — it expires after an hour, so use it while you have signal.'),
  Faq('Is my payment information safe?',
      'Payments are processed by Fapshi through MTN Mobile Money and Orange Money. You approve each charge on your own handset and GoStudy never sees or stores your mobile money PIN.'),
  Faq('Does GoStudy work without data?',
      'Mostly, yes. Course materials you have opened stay in your offline library, and the offline AI chat answers without a connection. Chat, News and the Marketplace need data to sync.'),
];

const privacySections = [
  LegalSection('01', 'Information we collect',
      'Account details, profile information, content you post, and technical data collected automatically.'),
  LegalSection('02', 'How we use your information',
      'Delivering the service, personalising study content, processing payments, and safety enforcement.'),
  LegalSection('03', 'How your information is stored',
      'Where account data lives, how it is encrypted, and who inside GoStudy can reach it.'),
  LegalSection('04', 'AI features and your prompts',
      'What is sent to the AI provider when you use the Study Assistant, and whether it is retained.'),
  LegalSection('05', 'Data retention', 'How long each category of data is kept, and what happens when your account closes.'),
  LegalSection('06', 'Your rights and choices', 'Access, correction, export, deletion, and notification preferences.'),
  LegalSection('07', 'Children and student data', 'Minimum age, and how student status is handled.'),
];

const processors = [
  Processor('Supabase', 'Data storage and authentication — your account, profile, courses, messages and listings.'),
  Processor('Firebase', 'Push notifications — device token and delivery metadata only.'),
  Processor('Google Gemini', 'AI queries — the text and images you send to the Study Assistant.'),
  Processor('Fapshi', 'Payment processing for MTN Mobile Money and Orange Money transactions.'),
];

const termsSections = [
  LegalSection('01', 'Acceptance of terms', 'What creating an account commits you to.'),
  LegalSection('02', 'Eligibility and your account', 'Who may register, and your responsibility for credentials and activity.'),
  LegalSection('03', 'Acceptable use', 'Conduct rules for chat, DMs, the Marketplace and shared materials.'),
  LegalSection('04', 'Content and intellectual property', 'Who owns uploaded materials, and the licence you grant GoStudy.'),
  LegalSection('05', 'Subscriptions and payments', 'Billing, renewal, refunds and the mobile money flow.'),
  LegalSection('06', 'AI-generated content', 'That AI answers may be wrong and are not a substitute for course material or staff.'),
  LegalSection('07', 'Suspension and termination', 'When GoStudy may close an account, and how you close yours.'),
  LegalSection('08', 'Liability, changes and governing law', 'Limits of liability, how terms change, and the governing jurisdiction.'),
];

const deletedOnAccountDeletion = [
  'Your account and login credentials',
  'Your profile, avatar and study statistics',
  'Global Chat messages and direct messages you sent',
  'Saved course materials and offline library entries',
  'Marketplace listings, active and completed',
  'Tasks, exam schedule, study plans and quiz history',
];

const retainedOnAccountDeletion = [
  'Payment and transaction records, kept for accounting and tax obligations',
  'Transcript request records held by the university as official academic documents',
  'Minimal abuse records where an account was closed for a safety breach',
];
