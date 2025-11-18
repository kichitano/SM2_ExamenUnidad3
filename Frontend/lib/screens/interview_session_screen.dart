import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/interview_provider.dart';
import '../providers/lives_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/interview_robot_head.dart';

class InterviewSessionScreen extends StatefulWidget {
  const InterviewSessionScreen({super.key});

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  final TextEditingController _answerController = TextEditingController();
  final GlobalKey<InterviewRobotHeadState> _robotHeadKey = GlobalKey<InterviewRobotHeadState>();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  bool _hasSpeakingStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  /// Initialize TTS service
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      setState(() {
        _isInitialized = true;
      });
      debugPrint('✅ Flutter TTS initialized');
    } catch (e) {
      debugPrint('❌ Error initializing TTS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS initialization failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Speak the question text and trigger robot animation
  Future<void> _speakQuestion(String questionText) async {
    if (!_isInitialized) {
      debugPrint('⚠️ TTS not initialized yet');
      return;
    }

    if (_hasSpeakingStarted) {
      debugPrint('⚠️ Already speaking, skipping...');
      return;
    }

    setState(() {
      _hasSpeakingStarted = true;
    });

    try {
      debugPrint('🎙️ Starting to speak question: $questionText');

      // Start robot animation
      _robotHeadKey.currentState?.playSpeakingAnimation();

      // Speak the question using Flutter TTS
      await _flutterTts.speak(questionText);

      debugPrint('✅ Finished speaking');
    } catch (e) {
      debugPrint('❌ Error speaking question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to speak question: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Trigger robot speaking animation
  void _triggerRobotSpeaking() {
    _robotHeadKey.currentState?.playSpeakingAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InterviewProvider>(
      builder: (context, provider, child) {
        if (provider.state == InterviewState.sessionCompleted && provider.finalScore != null) {
          return _buildFinalScoreScreen(context, provider);
        }

        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.interviewDash(provider.activeSession?.topicName ?? "")),
            actions: [
              // Lives counter
              Consumer<LivesProvider>(
                builder: (context, livesProvider, child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: List.generate(livesProvider.currentLives, (index) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              // Question counter
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${provider.questionsAnswered}/${provider.totalQuestions}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: provider.currentQuestion == null
              ? const Center(child: CircularProgressIndicator())
              : provider.latestEvaluation != null
                  ? _buildEvaluationView(context, provider)
                  : _buildQuestionView(context, provider),
        );
      },
    );
  }

  Widget _buildQuestionView(BuildContext context, InterviewProvider provider) {
    final question = provider.currentQuestion!;
    final l10n = AppLocalizations.of(context)!;

    // Trigger TTS when question loads (only once per question)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSpeakingStarted && _isInitialized) {
        _speakQuestion(question.question);
      }
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(question.id),
        children: [
          // Progress bar at top
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: provider.progressPercentage / 100),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return LinearProgressIndicator(value: value);
            },
          ),

          // 3D Robot Head - Expanded to take maximum space
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: InterviewRobotHead(
                      key: _robotHeadKey,
                      autoPlaySpeaking: true,
                      speakingDuration: const Duration(seconds: 5),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom controls section - Fixed at bottom
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category badge
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          question.categoryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Question text
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Voice recording indicator (compact)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none, size: 24, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        l10n.voiceRecordingComingSoon,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button - Themed
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.state == InterviewState.submittingAnswer
                        ? null
                        : () {
                            if (_answerController.text.trim().isEmpty) {
                              _showTemporaryTextInputDialog(context, provider, l10n);
                            } else {
                              provider.submitAnswer(_answerController.text.trim());
                              _answerController.clear();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: provider.state == InterviewState.submittingAnswer
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                l10n.submitAnswer,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Temporary method to show text input dialog (until voice recording is implemented)
  void _showTemporaryTextInputDialog(BuildContext context, InterviewProvider provider, dynamic l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.yourAnswer),
        content: TextField(
          controller: _answerController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: l10n.typeYourAnswerHere,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_answerController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterAnswer)),
                );
                return;
              }
              Navigator.pop(dialogContext);
              provider.submitAnswer(_answerController.text.trim());
              _answerController.clear();
            },
            child: Text(l10n.submitAnswer),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationView(BuildContext context, InterviewProvider provider) {
    final eval = provider.latestEvaluation!;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.answerEvaluation, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Overall score
          if (eval.overallQuestionScore != null) ...[
            Card(
              color: _getScoreColor(eval.overallQuestionScore!),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 40, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.score, style: const TextStyle(color: Colors.white70)),
                          Text(
                            '${eval.overallQuestionScore!.toStringAsFixed(1)}/100',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Feedback
          if (eval.aiFeedback != null) ...[
            _buildSection(l10n.feedback, eval.aiFeedback!),
            const SizedBox(height: 16),
          ],
          // Score breakdown
          _buildScoreBreakdown(context, eval),
          const SizedBox(height: 24),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Reset speaking flag for next question
                setState(() {
                  _hasSpeakingStarted = false;
                });
                provider.moveToNextQuestion();
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(provider.currentQuestionIndex < provider.totalQuestions - 1
                  ? l10n.nextQuestion
                  : l10n.viewFinalResults),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreScreen(BuildContext context, InterviewProvider provider) {
    final score = provider.finalScore!;
    final l10n = AppLocalizations.of(context)!;
    final highScore = score.scores.overallScore >= 85;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interviewComplete)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Animated icon with scale effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    score.passed ? Icons.check_circle : Icons.cancel,
                    size: 80,
                    color: score.passed ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Animated text
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    score.passed ? l10n.congratulations : l10n.keepPracticing,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Animated score with count-up effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: score.scores.overallScore),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  l10n.overallScore(value.toStringAsFixed(1)),
                  style: TextStyle(
                    fontSize: 24,
                    color: highScore ? Colors.green.shade700 : null,
                    fontWeight: highScore ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Confetti effect for high scores
            if (highScore)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.orange.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Excellent performance! 🎉',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (highScore) const SizedBox(height: 24),
            // Feedback with fade-in
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(score.finalFeedback, textAlign: TextAlign.center),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.reset();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(l10n.backToTopics),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content),
      ],
    );
  }

  Widget _buildScoreBreakdown(BuildContext context, eval) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.scoreBreakdown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (eval.fluencyScore != null) _buildScoreRow(l10n.fluency, eval.fluencyScore!),
            if (eval.grammarScore != null) _buildScoreRow(l10n.grammar, eval.grammarScore!),
            if (eval.vocabularyScore != null) _buildScoreRow(l10n.vocabulary_skill, eval.vocabularyScore!),
            if (eval.pronunciationScore != null) _buildScoreRow(l10n.pronunciation, eval.pronunciationScore!),
            if (eval.coherenceScore != null) _buildScoreRow(l10n.coherence, eval.coherenceScore!),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(value: score / 100, minHeight: 8),
          ),
          const SizedBox(width: 8),
          Text(score.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}
