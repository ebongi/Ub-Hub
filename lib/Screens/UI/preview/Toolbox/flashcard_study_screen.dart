import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/flashcard_model.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/level_service.dart';
import 'package:go_study/services/points_service.dart';

/// Flip-card study mode for a generated [FlashcardDeck]. Session-only: the
/// user swipes through the deck, taps a card to flip between question and
/// answer, and self-grades each card "Got it" or "Still learning" —
/// still-learning cards loop back to the end of the session. Nothing is
/// persisted; structured after `quiz_view_screen.dart`.
class FlashcardStudyScreen extends StatefulWidget {
  final FlashcardDeck deck;
  final List<Flashcard> cards;

  const FlashcardStudyScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  late List<Flashcard> _queue;
  int _index = 0;
  bool _flipped = false;
  int _masteredCount = 0;
  final List<Flashcard> _stillLearning = [];
  // Cards graded "still learning" at least once, so the results screen can
  // score first-attempt mastery — every card eventually lands in
  // _masteredCount once mastered, so that count alone can't distinguish a
  // clean run from one that took several passes.
  final Set<Flashcard> _everMissed = {};
  bool _completed = false;
  bool _pointsAwarded = false;
  int _awardedPoints = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.of(widget.cards);
  }

  void _restart() {
    setState(() {
      _queue = List.of(widget.cards);
      _index = 0;
      _flipped = false;
      _masteredCount = 0;
      _stillLearning.clear();
      _everMissed.clear();
      _completed = false;
      _pointsAwarded = false;
      _awardedPoints = 0;
    });
  }

  void _grade({required bool mastered}) {
    if (mastered) {
      _masteredCount++;
    } else {
      _stillLearning.add(_queue[_index]);
      _everMissed.add(_queue[_index]);
    }

    if (_index < _queue.length - 1) {
      setState(() {
        _index++;
        _flipped = false;
      });
    } else if (_stillLearning.isNotEmpty) {
      setState(() {
        _queue = List.of(_stillLearning);
        _stillLearning.clear();
        _index = 0;
        _flipped = false;
      });
    } else {
      setState(() => _completed = true);
      _awardFlashcardPoints();
    }
  }

  Future<void> _awardFlashcardPoints() async {
    if (_pointsAwarded) return;
    _pointsAwarded = true;

    final userModel = context.read<UserModel>();
    final pointsBefore = userModel.totalPoints;

    int awarded = 0;
    try {
      awarded = await PointsService().awardPoints(
        'flashcards_studied',
        metadata: {'mastered_count': _masteredCount},
      );
    } catch (_) {
      // Best-effort — a points hiccup shouldn't block showing results.
    }
    if (!mounted || awarded <= 0) return;

    setState(() => _awardedPoints = awarded);

    final levelBefore = LevelService.computeLevel(pointsBefore);
    final levelAfter = LevelService.computeLevel(pointsBefore + awarded);
    if (levelAfter.level > levelBefore.level && mounted) {
      _showLevelUpDialog(levelAfter);
    }
  }

  void _showLevelUpDialog(LevelInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Level Up! 🎉', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'You reached Level ${info.level} — ${info.title}!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nice!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.flashcardsTitle)),
        body: Center(child: Text(l10n.flashcardGenerationFailed)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _completed
              ? l10n.resultsTitle
              : '${widget.deck.title}  ·  ${_index + 1}/${_queue.length}',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _completed
          ? _buildResults(theme, l10n)
          : _buildStudyBody(theme, l10n),
    );
  }

  Widget _buildStudyBody(ThemeData theme, AppLocalizations l10n) {
    final card = _queue[_index];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / _queue.length,
            backgroundColor: theme.dividerColor,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildFace(
                  key: ValueKey('${_index}_$_flipped'),
                  theme: theme,
                  label: _flipped
                      ? l10n.flashcardAnswerLabel
                      : l10n.flashcardQuestionLabel,
                  text: _flipped ? card.answer : card.question,
                  isAnswer: _flipped,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tapToFlipHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _grade(mastered: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(l10n.stillLearningButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _grade(mastered: true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(l10n.gotItButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFace({
    required Key key,
    required ThemeData theme,
    required String label,
    required String text,
    required bool isAnswer,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final accent = isAnswer ? Colors.green.shade600 : theme.colorScheme.primary;

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: accent,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    final total = widget.cards.length;
    // Percent mastered on the first attempt — _masteredCount always equals
    // total by the time results render (every card is eventually mastered
    // to end the session), so it can't reflect how many passes it took.
    final pct = total == 0 ? 0.0 : ((total - _everMissed.length) / total) * 100;
    final good = pct >= 50;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            good ? Icons.emoji_events_rounded : Icons.psychology_rounded,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            good ? l10n.greatJobTitle : l10n.keepStudyingTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.flashcardsMasteredLabel(_masteredCount, total),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey),
          ),
          if (_awardedPoints > 0) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$_awardedPoints points',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _restart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(l10n.studyAgainButton),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.doneButton),
          ),
        ],
      ),
    );
  }
}
