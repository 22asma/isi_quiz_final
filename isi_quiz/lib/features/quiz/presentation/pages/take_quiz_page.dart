import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TakeQuizPage extends StatefulWidget {
  const TakeQuizPage({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  @override
  State<TakeQuizPage> createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends State<TakeQuizPage> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  int _timeLeft = 20;
  late int _totalTime;
  bool _quizStarted = false;
  bool _timerActive = false;

  // ── Multi-answer support ──────────────────────────────────────────────────
  // Stores comma-separated selected answer ids per question index.
  late List<String> _userAnswers;

  // Currently selected ids for the question being displayed.
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _totalTime = widget.quiz['time_limit'] as int? ?? 20;
    _timeLeft = _totalTime;
    _userAnswers = List.filled(_getQuestions().length, '');
  }

  @override
  void dispose() {
    _timerActive = false;
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getQuestions() {
    final questions = widget.quiz['questions'] as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(questions);
  }

  /// answer_limit > 1 means multiple answers allowed for the whole quiz.
  bool get _isMultipleAnswerQuiz {
    final limit = widget.quiz['answer_limit'] as int? ?? 1;
    return limit > 1;
  }

  /// How many correct answers exist for a given question.
  int _correctCountForQuestion(Map<String, dynamic> question) {
    final answers = question['answers'] as List<dynamic>? ?? [];
    return answers
        .where((a) => (a as Map<String, dynamic>)['is_correct'] == true)
        .length;
  }

  /// Whether this specific question requires multiple selections.
  bool _isMultipleQuestion(Map<String, dynamic> question) =>
      _isMultipleAnswerQuiz && _correctCountForQuestion(question) > 1;

  bool get _hasSelection => _selectedIds.isNotEmpty;

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _timerActive = true;
    });
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_timerActive) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        _tick();
      } else {
        _nextQuestion();
      }
    });
  }

  // ── Answer selection ──────────────────────────────────────────────────────

  void _toggleAnswer(String answerId, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        if (_selectedIds.contains(answerId)) {
          _selectedIds.remove(answerId);
        } else {
          _selectedIds.add(answerId);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(answerId);
      }
    });
  }

  void _saveCurrentSelection() {
    _userAnswers[_currentQuestionIndex] = _selectedIds.join(',');
  }

  void _loadSelectionForIndex(int index) {
    _selectedIds.clear();
    final saved = _userAnswers[index];
    if (saved.isNotEmpty) {
      _selectedIds.addAll(saved.split(',').where((s) => s.isNotEmpty));
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _nextQuestion() {
    _saveCurrentSelection();
    if (_currentQuestionIndex < _getQuestions().length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _loadSelectionForIndex(_currentQuestionIndex);
        _timeLeft = _totalTime;
      });
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _saveCurrentSelection();
      setState(() {
        _currentQuestionIndex--;
        _loadSelectionForIndex(_currentQuestionIndex);
        _timeLeft = _totalTime;
      });
    }
  }

  void _finishQuiz() async {
    _timerActive = false;
    _saveCurrentSelection();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/quiz-results',
        arguments: {
          'quiz': widget.quiz,
          'answers': _userAnswers,
        },
      );
    }
  }

  // ── Multimedia ────────────────────────────────────────────────────────────

  String? _getMediaType(Map<String, dynamic> q) =>
      (q['multimedia_type'] as String?)?.toLowerCase();

  String? _getMediaUrl(Map<String, dynamic> q) =>
      q['multimedia_url'] as String?;

  Widget _buildMultimedia(Map<String, dynamic> question) {
    final type = _getMediaType(question);
    final url = _getMediaUrl(question);
    if (type == null || url == null || url.isEmpty) return const SizedBox.shrink();
    switch (type) {
      case 'image':  return _buildImageMedia(url);
      case 'video':  return _buildVideoMedia(url);
      case 'code':   return _buildCodeMedia(url);
      default:       return const SizedBox.shrink();
    }
  }

  Widget _buildImageMedia(String path) {
    final isLocal = !path.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isLocal
          ? Image.file(File(path),
              height: 180, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _mediaError('Image introuvable'))
          : Image.network(path,
              height: 180, width: double.infinity, fit: BoxFit.cover,
              loadingBuilder: (_, child, prog) {
                if (prog == null) return child;
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: prog.expectedTotalBytes != null
                          ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _mediaError('Impossible de charger l\'image')),
    );
  }

  Widget _buildVideoMedia(String url) {
    String? youtubeId;
    final ytRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = ytRegex.firstMatch(url);
    if (match != null) youtubeId = match.group(1);

    return Container(
      height: 180,
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        if (youtubeId != null)
          Image.network(
            'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black.withOpacity(0.45)),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFFFF0000), size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              url.length > 40 ? '${url.substring(0, 40)}…' : url,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCodeMedia(String code) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A3E),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            _dot(const Color(0xFFFF5F57)),
            const SizedBox(width: 6),
            _dot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 6),
            _dot(const Color(0xFF28C840)),
            const Spacer(),
            const Text('code',
                style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SelectableText(code,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFCDD6F4),
                  height: 1.6)),
        ),
      ]),
    );
  }

  Widget _dot(Color color) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _mediaError(String msg) => Container(
      height: 80,
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!)),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(msg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questions = _getQuestions();
    final current =
        questions.isNotEmpty ? questions[_currentQuestionIndex] : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.quiz['title'] as String? ?? 'Quiz',
            style: const TextStyle(color: AppTheme.primaryColor)),
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          if (_quizStarted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeLeft <= 5 ? Colors.red : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$_timeLeft s',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
        ],
      ),
      body: !_quizStarted
          ? _buildStartScreen()
          : current != null
              ? _buildQuestionScreen(current)
              : const Center(child: Text('Aucune question disponible')),
    );
  }

  // ── Start screen ──────────────────────────────────────────────────────────

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60)),
            child: const Icon(Icons.play_arrow_rounded,
                size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(widget.quiz['title'] as String? ?? 'Quiz',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
              '${_getQuestions().length} questions • $_totalTime s par question',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          if (_isMultipleAnswerQuiz) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_box_outlined,
                    size: 16, color: Color(0xFF8B5CF6)),
                SizedBox(width: 6),
                Text('Certaines questions ont plusieurs réponses correctes',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: const Text('Commencer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Question screen ───────────────────────────────────────────────────────

  Widget _buildQuestionScreen(Map<String, dynamic> question) {
    final answers = question['answers'] as List<dynamic>? ?? [];
    final quizType = widget.quiz['quiz_type'] as String? ?? 'Quiz';
    final hasMedia = _getMediaType(question) != null &&
        (_getMediaUrl(question) ?? '').isNotEmpty;

    final isMultiple = _isMultipleQuestion(question);
    final correctCount = _correctCountForQuestion(question);

    // Button accent color changes when in multiple mode
    final accentColor =
        isMultiple ? const Color(0xFF8B5CF6) : AppTheme.primaryColor;

    return Column(children: [
      // ── Progress bar ────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                'Question ${_currentQuestionIndex + 1}/${_getQuestions().length}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
            Text(quizType,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value:
                (_currentQuestionIndex + 1) / _getQuestions().length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ]),
      ),

      // ── Scrollable body ─────────────────────────────────────────────────
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Question card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          question['question_text'] as String? ?? 'Question',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      if (hasMedia) ...[
                        const SizedBox(height: 14),
                        _buildMultimedia(question),
                      ],
                    ]),
              ),
            ),

            const SizedBox(height: 10),

            // ── Multiple-answer notice ─────────────────────────────────────
            if (isMultiple)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.12),
                    const Color(0xFF6D28D9).withOpacity(0.06),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                ),
                child: Row(children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check_box_outlined,
                        size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 10),
                  // Text
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Plusieurs réponses correctes',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6))),
                      Text(
                          'Sélectionne $correctCount réponses parmi les propositions',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6D28D9))),
                    ]),
                  ),
                  // Live counter badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: _selectedIds.length == correctCount
                            ? Colors.green
                            : const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_selectedIds.length}/$correctCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),

            // ── Answer cards ───────────────────────────────────────────────
            ...List.generate(answers.length, (index) {
              final answer = answers[index] as Map<String, dynamic>;
              final answerId = answer['id'] as String?;
              final answerText =
                  answer['answer_text'] as String? ?? 'Réponse';
              final isSelected =
                  answerId != null && _selectedIds.contains(answerId);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: answerId != null
                      ? () => _toggleAnswer(answerId, isMultiple)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      // Checkbox (square) for multiple, Radio (circle) for single
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          borderRadius: isMultiple
                              ? BorderRadius.circular(5)
                              : BorderRadius.circular(11),
                          color: isSelected ? accentColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(answerText,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? accentColor
                                    : Colors.black87)),
                      ),
                    ]),
                  ),
                ),
              );
            }),
          ]),
        ),
      ),

      // ── Bottom nav bar ──────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2))
          ],
        ),
        child: Row(children: [
          if (_currentQuestionIndex > 0) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _hasSelection ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white)))
                  : Text(
                      _currentQuestionIndex < _getQuestions().length - 1
                          ? 'Suivant'
                          : 'Terminer',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
            ),
          ),
        ]),
      ),
    ]);
  }
}