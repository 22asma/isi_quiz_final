import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Quiz Type Enum ───────────────────────────────────────────────────────────

enum QuizType { quiz, vraiFaux }

extension QuizTypeLabel on QuizType {
  String get label {
    switch (this) {
      case QuizType.quiz:
        return 'Quiz';
      case QuizType.vraiFaux:
        return 'Vrai / Faux';
    }
  }

  String get serviceKey {
    switch (this) {
      case QuizType.quiz:
        return 'Quiz';
      case QuizType.vraiFaux:
        return 'Vrai/Faux';
    }
  }

  static QuizType fromString(String? value) {
    switch (value) {
      case 'Vrai/Faux':
        return QuizType.vraiFaux;
      case 'Quiz':
      default:
        return QuizType.quiz;
    }
  }
}

// ─── Answer Limit Enum ───────────────────────────────────────────────────────

enum AnswerLimitType { single, multiple }

// ─── Answer Model ────────────────────────────────────────────────────────────

class _AnswerEntry {
  final TextEditingController controller;
  bool isCorrect;

  _AnswerEntry({String text = '', this.isCorrect = false})
      : controller = TextEditingController(text: text);

  void dispose() => controller.dispose();
}

// ─── Page ────────────────────────────────────────────────────────────────────

class EditQuizPage extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const EditQuizPage({super.key, required this.quiz});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  // Controllers
  final _quizTitleController = TextEditingController();
  final _questionController = TextEditingController();
  
  // Answers (Quiz)
  final List<_AnswerEntry> _answers = [
    _AnswerEntry(isCorrect: true),
    _AnswerEntry(),
    _AnswerEntry(),
    _AnswerEntry(),
  ];

  // Multiple questions support
  final List<Map<String, dynamic>> _savedQuestions = [];
  int _currentQuestionIndex = 0;

  // Quiz settings
  QuizType _quizType = QuizType.quiz;
  AnswerLimitType _answerLimitType = AnswerLimitType.single;
  bool? _vraiFauxAnswer; // true = Vrai, false = Faux, null = not selected
  int _timeLimit = 20;
  String _pointsType = 'Standard';
  bool _isPublic = true;
  int _maxParticipants = 10; // Pour les quiz privés
  
  // Service / loading
  final QuizService _quizService = QuizService();
  bool _isLoading = false;
  bool _isInitialized = false;

  // ── Colors & Icons per answer slot ────────────────────────────────────────

  static const List<Color> _answerColors = [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  static const List<IconData> _answerIcons = [
    Icons.layers,
    Icons.shield,
    Icons.circle,
    Icons.star,
    Icons.favorite,
    Icons.square,
  ];

  Color _colorFor(int i) => _answerColors[i % _answerColors.length];
  IconData _iconFor(int i) => _answerIcons[i % _answerIcons.length];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeQuizData();
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    _questionController.dispose();
    for (final a in _answers) {
      a.dispose();
    }
    super.dispose();
  }

  // ── Initialization ────────────────────────────────────────────────────────

  void _initializeQuizData() {
    final quiz = widget.quiz;
    
    // Initialize quiz settings
    _quizTitleController.text = quiz['title'] as String? ?? '';
    _quizType = QuizTypeLabel.fromString(quiz['quiz_type'] as String?);
    _timeLimit = quiz['time_limit'] as int? ?? 20;
    _pointsType = quiz['points_type'] as String? ?? 'Standard';
    _isPublic = quiz['is_public'] == true;
    _maxParticipants = quiz['max_participants'] as int? ?? 10;
    
    // Determine answer limit type
    final answerLimit = quiz['answer_limit'] as int? ?? 1;
    _answerLimitType = answerLimit == 1 ? AnswerLimitType.single : AnswerLimitType.multiple;

    // Load existing questions
    if (quiz['questions'] != null) {
      final questions = quiz['questions'] as List;
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        final questionData = {
          'question_text': question['question_text'] as String? ?? '',
          'multimedia_url': question['multimedia_url'],
          'multimedia_type': question['multimedia_type'],
          'answers': _processExistingAnswers(question['answers'] as List? ?? []),
          'quiz_type': _quizType.serviceKey,
        };
        _savedQuestions.add(questionData);
      }
    }

    setState(() {
      _isInitialized = true;
      if (_savedQuestions.isNotEmpty) {
        _currentQuestionIndex = _savedQuestions.length;
      }
    });
  }

  List<Map<String, dynamic>> _processExistingAnswers(List answers) {
    return answers.map((answer) {
      final answerMap = answer as Map<String, dynamic>;
      return {
        'text': answerMap['answer_text'] as String? ?? '',
        'is_correct': answerMap['is_correct'] as bool? ?? false,
        'order': answerMap['answer_order'] as int? ?? 1,
      };
    }).toList();
  }

  // ── Answer management ─────────────────────────────────────────────────────

  void _addAnswer() {
    if (_answers.length >= 6) return;
    setState(() => _answers.add(_AnswerEntry()));
  }

  void _removeAnswer(int index) {
    if (_answers.length <= 2) return;
    setState(() {
      _answers[index].dispose();
      _answers.removeAt(index);
      // Ensure at least one correct in single mode
      if (_answerLimitType == AnswerLimitType.single &&
          !_answers.any((a) => a.isCorrect)) {
        _answers.first.isCorrect = true;
      }
    });
  }

  void _toggleCorrect(int index) {
    setState(() {
      if (_answerLimitType == AnswerLimitType.single) {
        for (int i = 0; i < _answers.length; i++) {
          _answers[i].isCorrect = i == index;
        }
      } else {
        _answers[index].isCorrect = !_answers[index].isCorrect;
      }
    });
  }

  // ─── Helper Methods ───────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Load question for editing
  void _loadQuestionForEditing(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= _savedQuestions.length) return;
    
    final question = _savedQuestions[questionIndex];
    _questionController.text = question['question_text'] as String? ?? '';
    
    // Clear and reset answers
    for (final a in _answers) {
      a.controller.clear();
      a.isCorrect = false;
    }
    
    // Load answers
    final answers = question['answers'] as List<Map<String, dynamic>>? ?? [];
    for (int i = 0; i < answers.length && i < _answers.length; i++) {
      final answer = answers[i];
      _answers[i].controller.text = answer['text'] as String? ?? '';
      _answers[i].isCorrect = answer['is_correct'] as bool? ?? false;
    }
    
    // Set vrai/faux answer if applicable
    if (_quizType == QuizType.vraiFaux && answers.isNotEmpty) {
      _vraiFauxAnswer = answers[0]['is_correct'] as bool? ?? false;
    }
    
    setState(() {
      _currentQuestionIndex = questionIndex;
    });
  }

  // Save current question and move to next
  void _saveCurrentQuestionAndNext() {
    if (!_validateCurrentQuestion()) {
      return;
    }

    final questionData = _getCurrentQuestionData();
    
    if (_currentQuestionIndex < _savedQuestions.length) {
      // Update existing question
      _savedQuestions[_currentQuestionIndex] = questionData;
    } else {
      // Add new question
      _savedQuestions.add(questionData);
    }
    
    setState(() {
      _currentQuestionIndex++;
      _clearCurrentQuestion();
    });

    _showSnack('Question ${_currentQuestionIndex} mise à jour !');
  }

  // Validate current question
  bool _validateCurrentQuestion() {
    if (_questionController.text.trim().isEmpty) {
      _showSnack('Veuillez entrer une question', isError: true);
      return false;
    }

    if (_quizType == QuizType.vraiFaux && _vraiFauxAnswer == null) {
      _showSnack('Veuillez sélectionner Vrai ou Faux', isError: true);
      return false;
    }

    if (_quizType == QuizType.quiz) {
      final filled = _answers
          .where((a) => a.controller.text.trim().isNotEmpty)
          .toList();
      if (filled.length < 2) {
        _showSnack('Veuillez ajouter au moins 2 réponses', isError: true);
        return false;
      }
      if (!_answers.any((a) => a.isCorrect)) {
        _showSnack('Veuillez sélectionner au moins une réponse correcte', isError: true);
        return false;
      }
    }

    return true;
  }

  // Get current question data
  Map<String, dynamic> _getCurrentQuestionData() {
    final List<Map<String, dynamic>> answersData;

    switch (_quizType) {
      case QuizType.vraiFaux:
        answersData = [
          {'text': 'Vrai', 'is_correct': _vraiFauxAnswer == true, 'order': 1},
          {'text': 'Faux', 'is_correct': _vraiFauxAnswer == false, 'order': 2},
        ];
        break;
      default:
        answersData = _answers
            .where((a) => a.controller.text.trim().isNotEmpty)
            .toList()
            .asMap()
            .entries
            .map((e) => {
                  'text': e.value.controller.text.trim(),
                  'is_correct': e.value.isCorrect,
                  'order': e.key + 1,
                })
            .toList();
    }

    return {
      'question_text': _questionController.text.trim(),
      'multimedia_url': null,
      'multimedia_type': null,
      'answers': answersData,
      'quiz_type': _quizType.serviceKey,
    };
  }

  // Clear current question inputs
  void _clearCurrentQuestion() {
    _questionController.clear();
    _vraiFauxAnswer = null;
    
    for (final a in _answers) {
      a.controller.clear();
      a.isCorrect = false;
    }
    _answers.first.isCorrect = true; // First answer is correct by default
  }

  // Finish quiz update
  void _finishQuizUpdate() async {
    if (_savedQuestions.isEmpty) {
      _showSnack('Veuillez ajouter au moins une question', isError: true);
      return;
    }

    // Add the last question if it's filled
    if (_questionController.text.trim().isNotEmpty && _validateCurrentQuestion()) {
      final questionData = _getCurrentQuestionData();
      if (_currentQuestionIndex < _savedQuestions.length) {
        _savedQuestions[_currentQuestionIndex] = questionData;
      } else {
        _savedQuestions.add(questionData);
      }
    }

    await _updateCompleteQuiz();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur est un instructor
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || !authState.user.isInstructor) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: const Text('Accès refusé',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Accès réservé aux instructors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Seuls les instructors peuvent modifier des quiz',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: const Text('Modifier le quiz',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeTabs(),
            const SizedBox(height: 12),
            _buildQuizTitleCard(),
            const SizedBox(height: 12),
            _buildQuestionSelector(),
            const SizedBox(height: 12),
            _buildQuestionCard(),
            const SizedBox(height: 12),
            _buildAnswerSection(),
            const SizedBox(height: 12),
            _buildParamsCard(),
            const SizedBox(height: 20),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      title: const Text('Modifier le quiz',
          style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, color: Colors.white),
          onPressed: () {
            // TODO: Preview
          },
        ),
      ],
    );
  }

  // ── Question Selector ─────────────────────────────────────────────────────

  Widget _buildQuestionSelector() {
    if (_savedQuestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.quiz, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Nouvelle question',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '0 ajoutée(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions existantes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(_savedQuestions.length, (index) {
              final isCurrent = _currentQuestionIndex == index;
              return ActionChip(
                label: Text('Q${index + 1}'),
                onPressed: () => _loadQuestionForEditing(index),
                backgroundColor: isCurrent ? AppTheme.primaryColor : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isCurrent ? Colors.white : Colors.black,
                  fontSize: 12,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          if (_currentQuestionIndex >= _savedQuestions.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nouvelle question',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Type tabs ─────────────────────────────────────────────────────────────

  Widget _buildTypeTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QuizType.values.map((type) {
          final active = _quizType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _quizType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryColor
                        : const Color(0xFFDDDDDD),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Quiz title card ────────────────────────────────────────────────────────

  Widget _buildQuizTitleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _quizTitleController,
        decoration: const InputDecoration(
          hintText: 'Titre du quiz...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              hintText: 'Écris ta question ici...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: null,
            style: const TextStyle(fontSize: 15),
          ),
          const Divider(height: 1),
          _buildMediaRow(),
        ],
      ),
    );
  }

  Widget _buildMediaRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _mediaBtn(Icons.image_outlined, 'Image'),
          const SizedBox(width: 8),
          _mediaBtn(Icons.videocam_outlined, 'Vidéo'),
          const SizedBox(width: 8),
          _mediaBtn(Icons.music_note_outlined, 'Musique'),
        ],
      ),
    );
  }

  Widget _mediaBtn(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Implement multimedia selection
        },
        icon: Icon(icon, size: 16, color: AppTheme.primaryColor),
        label: Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF666666))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ── Answer Section (switches by type) ────────────────────────────────────

  Widget _buildAnswerSection() {
    switch (_quizType) {
      case QuizType.vraiFaux:
        return _buildVraiFauxSection();
      case QuizType.quiz:
        return _buildAnswerList(showCorrect: true);
    }
  }

  // Vrai / Faux

  Widget _buildVraiFauxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _tfCard(true)),
            const SizedBox(width: 12),
            Expanded(child: _tfCard(false)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Sélectionne la bonne réponse',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _tfCard(bool value) {
    final selected = _vraiFauxAnswer == value;
    final isVrai = value;
    final selectedColor = isVrai ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () => setState(() => _vraiFauxAnswer = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isVrai ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 36,
              color: selected ? selectedColor : const Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 8),
            Text(
              isVrai ? 'Vrai' : 'Faux',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quiz answer list

  Widget _buildAnswerList({required bool showCorrect}) {
    final correctCount = _answers.where((a) => a.isCorrect).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_answers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildAnswerCard(i, showCorrect: showCorrect),
          );
        }),
        if (_answers.length < 6)
          TextButton.icon(
            onPressed: _addAnswer,
            icon: const Icon(Icons.add_circle_outline,
                color: AppTheme.primaryColor, size: 18),
            label: Text(
              'Ajouter une réponse',
              style: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
            ),
          ),
        if (showCorrect &&
            _answerLimitType == AnswerLimitType.multiple &&
            correctCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$correctCount réponse${correctCount > 1 ? 's' : ''} correcte${correctCount > 1 ? 's' : ''} sélectionnée${correctCount > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerCard(int index, {required bool showCorrect}) {
    final entry = _answers[index];
    final color = _colorFor(index);
    final icon = _iconFor(index);
    final isCorrect = entry.isCorrect;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (showCorrect && isCorrect)
              ? Colors.green
              : const Color(0xFFE8E8E8),
          width: (showCorrect && isCorrect) ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                bottomLeft: Radius.circular(11),
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: entry.controller,
              decoration: InputDecoration(
                hintText: 'Réponse ${index + 1}...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (showCorrect)
            GestureDetector(
              onTap: () => _toggleCorrect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCorrect ? Colors.green : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                ),
                child: isCorrect
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 15)
                    : null,
              ),
            ),
          if (_answers.length > 2)
            IconButton(
              onPressed: () => _removeAnswer(index),
              icon: const Icon(Icons.close, color: Color(0xFFCCCCCC), size: 18),
              padding: const EdgeInsets.only(right: 4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ── Parameters card ───────────────────────────────────────────────────────

  Widget _buildParamsCard() {
    final showAnswerLimit = _quizType == QuizType.quiz;
    final showPoints = true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _paramRow(
            'Temps imparti',
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(text: _timeLimit.toString()),
                    onChanged: (v) =>
                        _timeLimit = int.tryParse(v) ?? 20,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('s',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF888888))),
              ],
            ),
          ),
          if (showPoints) ...[
            const Divider(height: 1),
            _paramRow(
              'Points',
              Row(
                children: [
                  const Icon(Icons.star,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _pointsType,
                    isDense: true,
                    underline: const SizedBox(),
                    items: ['Standard', 'Double', 'Triple', 'Aucun']
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _pointsType = v!),
                  ),
                ],
              ),
            ),
          ],
          if (showAnswerLimit) ...[
            const Divider(height: 1),
            _paramRow(
              'Réponse correcte',
              Row(
                children: [
                  _limitToggle('Unique', AnswerLimitType.single),
                  const SizedBox(width: 6),
                  _limitToggle('Multiple', AnswerLimitType.multiple),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          _paramRow(
            'Visibilité',
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Row(
                children: [
                  _accessToggle('Public', true),
                  _accessToggle('Classe', false),
                ],
              ),
            ),
          ),
          if (!_isPublic) ...[
            const Divider(height: 1),
            _paramRow(
              'Participants max',
              Row(
                children: [
                  const Icon(Icons.people,
                      size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: _maxParticipants.toString()),
                      onChanged: (v) {
                        final value = int.tryParse(v);
                        if (value != null && value > 0) {
                          _maxParticipants = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paramRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
              letterSpacing: 0.5,
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _limitToggle(String label, AnswerLimitType type) {
    final active = _answerLimitType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _answerLimitType = type;
          // If switching to single, keep only first correct
          if (type == AnswerLimitType.single) {
            bool found = false;
            for (final a in _answers) {
              if (a.isCorrect && !found) {
                found = true;
              } else {
                a.isCorrect = false;
              }
            }
            if (!found) _answers.first.isCorrect = true;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primaryColor : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _accessToggle(String label, bool isPublic) {
    final active = _isPublic == isPublic;
    return GestureDetector(
      onTap: () => setState(() => _isPublic = isPublic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isPublic ? Icons.public : Icons.group,
              size: 14,
              color: active ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title & description
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF666666), size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Les quiz publiés seront accessibles par tous les étudiants',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCurrentQuestionAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Question suivante',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishQuizUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Mettre à jour',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Update logic ────────────────────────────────────────────────────────────

  Future<void> _updateCompleteQuiz() async {
    // Validate quiz title
    if (_quizTitleController.text.trim().isEmpty) {
      _showSnack('Veuillez entrer un titre pour le quiz', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      print('EditQuiz: Updating quiz ID: ${widget.quiz['id']}');
      print('EditQuiz: Quiz title: ${_quizTitleController.text.trim()}');
      print('EditQuiz: Number of questions: ${_savedQuestions.length}');

      final success = await _quizService.updateQuizWithQuestions(
        quizId: widget.quiz['id'],
        title: _quizTitleController.text.trim(),
        description: 'Quiz avec ${_savedQuestions.length} questions',
        quizType: _quizType.serviceKey,
        timeLimit: _timeLimit,
        pointsType: _pointsType,
        isPublic: _isPublic,
        maxParticipants: _isPublic ? null : _maxParticipants,
        answerLimit: _answerLimitType == AnswerLimitType.single ? 1 : _answers.length,
        questions: _savedQuestions,
      );

      print('EditQuiz: Quiz update result: $success');

      if (success) {
        _showSnack('Quiz mis à jour avec succès ! (${_savedQuestions.length} questions)');
        Navigator.pop(context, true); // Return true so list page can refresh
      } else {
        throw Exception('Échec de la mise à jour du quiz');
      }
    } catch (e) {
      print('Detailed error: $e');
      _showSnack('Erreur : $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
