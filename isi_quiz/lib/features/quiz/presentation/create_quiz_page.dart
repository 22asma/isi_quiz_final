import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum QuizType { quiz, vraiFaux }

extension QuizTypeLabel on QuizType {
  String get label => this == QuizType.quiz ? 'Quiz' : 'Vrai / Faux';
  String get serviceKey => this == QuizType.quiz ? 'Quiz' : 'Vrai/Faux';
}

enum AnswerLimitType { single, multiple }

enum PointsType {
  standard,
  double_,
  triple,
  none;

  String get label {
    switch (this) {
      case PointsType.standard: return 'Standard';
      case PointsType.double_:  return 'Double';
      case PointsType.triple:   return 'Triple';
      case PointsType.none:     return 'Aucun';
    }
  }

  String get serviceKey {
    switch (this) {
      case PointsType.standard: return 'Standard';
      case PointsType.double_:  return 'Double';
      case PointsType.triple:   return 'Triple';
      case PointsType.none:     return 'Aucun';
    }
  }

  int get multiplier {
    switch (this) {
      case PointsType.standard: return 1;
      case PointsType.double_:  return 2;
      case PointsType.triple:   return 3;
      case PointsType.none:     return 0;
    }
  }

  static PointsType fromString(String? v) {
    switch (v) {
      case 'Double':   return PointsType.double_;
      case 'Triple':   return PointsType.triple;
      case 'Aucun':    return PointsType.none;
      default:         return PointsType.standard;
    }
  }

  Color get color {
    switch (this) {
      case PointsType.standard: return const Color(0xFFF59E0B);
      case PointsType.double_:  return const Color(0xFF3B82F6);
      case PointsType.triple:   return const Color(0xFF8B5CF6);
      case PointsType.none:     return Colors.grey;
    }
  }
}

// ─── Media Type ───────────────────────────────────────────────────────────────

enum MediaType { none, image, video, code }

// ─── Answer Model ────────────────────────────────────────────────────────────

class _AnswerEntry {
  final TextEditingController controller;
  bool isCorrect;
  _AnswerEntry({String text = '', this.isCorrect = false})
      : controller = TextEditingController(text: text);
  void dispose() => controller.dispose();
}

// ─── Question Model ───────────────────────────────────────────────────────────

class _QuestionData {
  String text;
  List<Map<String, dynamic>> answers;
  PointsType pointsType;
  MediaType mediaType;
  String? mediaValue; // URL for video, code string for code, path for image
  File? imageFile;

  _QuestionData({
    this.text = '',
    List<Map<String, dynamic>>? answers,
    this.pointsType = PointsType.standard,
    this.mediaType = MediaType.none,
    this.mediaValue,
    this.imageFile,
  }) : answers = answers ?? [];
}

// ─── Page ────────────────────────────────────────────────────────────────────

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  // Controllers
  final _quizTitleController = TextEditingController();
  final _questionController   = TextEditingController();
  final _videoUrlController   = TextEditingController();
  final _codeController       = TextEditingController();

  // Answers
  final List<_AnswerEntry> _answers = [
    _AnswerEntry(isCorrect: true),
    _AnswerEntry(),
    _AnswerEntry(),
    _AnswerEntry(),
  ];

  // Questions list
  final List<_QuestionData> _questions = [];
  int _currentIndex = 0; // index en cours d'édition

  // Quiz settings
  QuizType       _quizType       = QuizType.quiz;
  AnswerLimitType _answerLimit   = AnswerLimitType.single;
  bool?          _vraiFauxAnswer;
  int            _timeLimit      = 20;
  PointsType     _pointsType     = PointsType.standard;
  bool           _isPublic       = true;
  int            _maxParticipants = 10;

  // Media
  MediaType _mediaType  = MediaType.none;
  File?     _imageFile;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  final QuizService _quizService = QuizService();

  // Colors / Icons
  static const List<Color>    _answerColors = [Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const List<IconData> _answerIcons  = [Icons.layers, Icons.shield, Icons.circle, Icons.star, Icons.favorite, Icons.square];
  Color    _colorFor(int i) => _answerColors[i % _answerColors.length];
  IconData _iconFor (int i) => _answerIcons [i % _answerIcons.length];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _quizTitleController.dispose();
    _questionController.dispose();
    _videoUrlController.dispose();
    _codeController.dispose();
    for (final a in _answers) a.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Media helpers ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _mediaType = MediaType.image;
      });
    }
  }

  void _setVideoMedia() {
    setState(() => _mediaType = MediaType.video);
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _setCodeMedia() {
    setState(() => _mediaType = MediaType.code);
  }

  void _clearMedia() {
    setState(() {
      _mediaType = MediaType.none;
      _imageFile = null;
      _videoUrlController.clear();
      _codeController.clear();
    });
  }

  // ── Answer management ─────────────────────────────────────────────────────

  void _addAnswer() {
    if (_answers.length >= 6) return;
    setState(() => _answers.add(_AnswerEntry()));
  }

  void _removeAnswer(int i) {
    if (_answers.length <= 2) return;
    setState(() {
      _answers[i].dispose();
      _answers.removeAt(i);
      if (_answerLimit == AnswerLimitType.single && !_answers.any((a) => a.isCorrect)) {
        _answers.first.isCorrect = true;
      }
    });
  }

  void _toggleCorrect(int i) {
    setState(() {
      if (_answerLimit == AnswerLimitType.single) {
        for (int j = 0; j < _answers.length; j++) _answers[j].isCorrect = j == i;
      } else {
        _answers[i].isCorrect = !_answers[i].isCorrect;
      }
    });
  }

  // ── Question data helpers ─────────────────────────────────────────────────

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
      final filled = _answers.where((a) => a.controller.text.trim().isNotEmpty).toList();
      if (filled.length < 2) { _showSnack('Ajoutez au moins 2 réponses', isError: true); return false; }
      if (!_answers.any((a) => a.isCorrect)) { _showSnack('Sélectionnez une réponse correcte', isError: true); return false; }
    }
    return true;
  }

  Map<String, dynamic> _buildQuestionMap() {
    List<Map<String, dynamic>> answersData;
    if (_quizType == QuizType.vraiFaux) {
      answersData = [
        {'text': 'Vrai', 'is_correct': _vraiFauxAnswer == true,  'order': 1},
        {'text': 'Faux', 'is_correct': _vraiFauxAnswer == false, 'order': 2},
      ];
    } else {
      answersData = _answers
          .where((a) => a.controller.text.trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((e) => {'text': e.value.controller.text.trim(), 'is_correct': e.value.isCorrect, 'order': e.key + 1})
          .toList();
    }

    String? multimediaUrl;
    String? multimediaType;
    if (_mediaType == MediaType.video && _videoUrlController.text.trim().isNotEmpty) {
      multimediaUrl  = _videoUrlController.text.trim();
      multimediaType = 'video';
    } else if (_mediaType == MediaType.code && _codeController.text.trim().isNotEmpty) {
      multimediaUrl  = _codeController.text.trim();
      multimediaType = 'code';
    } else if (_mediaType == MediaType.image && _imageFile != null) {
      multimediaUrl  = _imageFile!.path;
      multimediaType = 'image';
    }

    return {
      'question_text':  _questionController.text.trim(),
      'multimedia_url':  multimediaUrl,
      'multimedia_type': multimediaType,
      'points_type':     _pointsType.serviceKey,
      'answers':         answersData,
      'quiz_type':       _quizType.serviceKey,
    };
  }

  void _loadQuestionIntoForm(int index) {
    if (index < 0 || index >= _questions.length) {
      // Nouvelle question vierge
      _clearForm();
      setState(() => _currentIndex = _questions.length);
      return;
    }
    final q = _questions[index];
    _questionController.text = q.text;
    _pointsType = q.pointsType;
    _mediaType  = q.mediaType;
    _imageFile  = q.imageFile;

    if (q.mediaType == MediaType.video) _videoUrlController.text = q.mediaValue ?? '';
    if (q.mediaType == MediaType.code)  _codeController.text     = q.mediaValue ?? '';

    for (final a in _answers) { a.controller.clear(); a.isCorrect = false; }
    final ans = q.answers;
    for (int i = 0; i < ans.length; i++) {
      if (i < _answers.length) {
        _answers[i].controller.text = ans[i]['text'] as String? ?? '';
        _answers[i].isCorrect       = ans[i]['is_correct'] as bool? ?? false;
      }
    }
    if (_quizType == QuizType.vraiFaux && ans.isNotEmpty) {
      _vraiFauxAnswer = ans[0]['is_correct'] as bool?;
    }
    setState(() => _currentIndex = index);
  }

  void _saveCurrentToList() {
    final data = _buildQuestionMap();
    final qd   = _QuestionData(
      text:       data['question_text'] as String,
      answers:    List<Map<String,dynamic>>.from(data['answers'] as List),
      pointsType: _pointsType,
      mediaType:  _mediaType,
      mediaValue: data['multimedia_url'] as String?,
      imageFile:  _imageFile,
    );
    if (_currentIndex < _questions.length) {
      _questions[_currentIndex] = qd;
    } else {
      _questions.add(qd);
    }
  }

  void _clearForm() {
    _questionController.clear();
    _videoUrlController.clear();
    _codeController.clear();
    _vraiFauxAnswer = null;
    _mediaType      = MediaType.none;
    _imageFile      = null;
    _pointsType     = PointsType.standard;
    for (final a in _answers) { a.controller.clear(); a.isCorrect = false; }
    if (_answers.isNotEmpty) _answers.first.isCorrect = true;
  }

  // ── Navigation questions ──────────────────────────────────────────────────

  void _goToPrevious() {
    if (!_validateCurrentQuestion()) return;
    _saveCurrentToList();
    _loadQuestionIntoForm(_currentIndex - 1);
  }

  void _goToNext() {
    if (!_validateCurrentQuestion()) return;
    _saveCurrentToList();
    if (_currentIndex + 1 <= _questions.length) {
      _loadQuestionIntoForm(_currentIndex + 1);
    }
    setState(() {});
  }

  void _finishQuiz() async {
    if (!_validateCurrentQuestion()) return;
    _saveCurrentToList();

    if (_questions.isEmpty) {
      _showSnack('Ajoutez au moins une question', isError: true);
      return;
    }
    if (_quizTitleController.text.trim().isEmpty) {
      _showSnack('Entrez un titre pour le quiz', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) throw Exception('Non authentifié');

      // Calcul score /20
      final int totalPoints = _questions.fold(0, (sum, q) => sum + q.pointsType.multiplier);

      final questionsForService = _questions.map((q) => {
        'question_text':  q.text,
        'multimedia_url':  q.mediaValue,
        'multimedia_type': q.mediaType == MediaType.none ? null : q.mediaType.name,
        'points_type':     q.pointsType.serviceKey,
        'answers':         q.answers,
      }).toList();

      final success = await _quizService.saveCompleteQuiz(
        creatorId:       authState.user.id,
        title:           _quizTitleController.text.trim(),
        description:     'Quiz avec ${_questions.length} questions — Score sur 20',
        quizType:        _quizType.serviceKey,
        timeLimit:       _timeLimit,
        pointsType:      _pointsType.serviceKey,
        isPublic:        _isPublic,
        maxParticipants: _isPublic ? null : _maxParticipants,
        answerLimit:     _answerLimit == AnswerLimitType.single ? 1 : 6,
        questions:       questionsForService,
      );

      if (success) {
        _showSnack('Quiz créé ! (${_questions.length} questions, score /20)');
        Navigator.pop(context, true);
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Score /20 preview ─────────────────────────────────────────────────────

  double _computeMaxScore() {
    int totalMultipliers = _questions.fold(0, (s, q) => s + q.pointsType.multiplier);
    if (totalMultipliers == 0) return 0;
    return 20.0;
  }

  double _pointsToNote(int earnedPoints, int maxPoints) {
    if (maxPoints == 0) return 0;
    return (earnedPoints / maxPoints) * 20;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || !authState.user.isInstructor) {
      return _buildAccessDenied();
    }

    final bool hasPrev = _currentIndex > 0;
    final bool isEditing = _currentIndex < _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(isEditing),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeTabs(),
            const SizedBox(height: 10),
            _buildTitleCard(),
            const SizedBox(height: 10),
            _buildQuestionNav(hasPrev, isEditing),
            const SizedBox(height: 10),
            _buildQuestionCard(),
            const SizedBox(height: 10),
            _buildMediaSection(),
            const SizedBox(height: 10),
            _buildAnswerSection(),
            const SizedBox(height: 10),
            _buildPointsCard(),
            const SizedBox(height: 10),
            _buildParamsCard(),
            const SizedBox(height: 10),
            if (_questions.isNotEmpty) _buildScorePreview(),
            const SizedBox(height: 10),
            _buildBottomBar(hasPrev),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(bool isEditing) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      title: Text(
        isEditing ? 'Modifier Q${_currentIndex + 1}' : 'Créer un quiz',
        style: const TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ── Access denied ─────────────────────────────────────────────────────────

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Accès refusé', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.block, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Accès réservé aux instructeurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
      ),
    );
  }

  // ── Type tabs ─────────────────────────────────────────────────────────────

  Widget _buildTypeTabs() {
    return Row(
      children: QuizType.values.map((type) {
        final active = _quizType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _quizType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppTheme.primaryColor : const Color(0xFFDDDDDD), width: 1.5),
              ),
              child: Text(type.label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? Colors.white : const Color(0xFF666666))),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Title card ────────────────────────────────────────────────────────────

  Widget _buildTitleCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: _quizTitleController,
        decoration: const InputDecoration(
          hintText: 'Titre du quiz...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Question navigation ───────────────────────────────────────────────────

  Widget _buildQuestionNav(bool hasPrev, bool isEditing) {
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
          const SizedBox(width: 10),
          Text(
            isEditing
                ? 'Question ${_currentIndex + 1} / ${_questions.length}'
                : 'Nouvelle question (${_questions.length + 1})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
          const Spacer(),
          // Chips des questions
          // APRÈS
if (_questions.isNotEmpty)
  Flexible(
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(_questions.length, (i) {
        final isCur = _currentIndex == i;
        return GestureDetector(
          onTap: () {
            if (!_validateCurrentQuestion()) return;
            _saveCurrentToList();
            _loadQuestionIntoForm(i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCur ? AppTheme.primaryColor : const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Q${i + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCur ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
        );
      }),
    ),
  ),
        ],
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: _questionController,
        decoration: const InputDecoration(
          hintText: 'Écris ta question ici...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        maxLines: null,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  // ── Media section ─────────────────────────────────────────────────────────

  Widget _buildMediaSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // Boutons média
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _mediaBtn(Icons.image_outlined, 'Image', MediaType.image, onTap: _pickImage),
                const SizedBox(width: 8),
                _mediaBtn(Icons.videocam_outlined, 'Vidéo', MediaType.video, onTap: _setVideoMedia),
                const SizedBox(width: 8),
                _mediaBtn(Icons.code_rounded, 'Code', MediaType.code, onTap: _setCodeMedia),
              ],
            ),
          ),

          // Aperçu média
          if (_mediaType != MediaType.none) ...[
            const Divider(height: 1),
            _buildMediaPreview(),
          ],
        ],
      ),
    );
  }

  Widget _mediaBtn(IconData icon, String label, MediaType type, {required VoidCallback onTap}) {
    final active = _mediaType == type;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppTheme.primaryColor : const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? AppTheme.primaryColor : const Color(0xFF666666)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: active ? AppTheme.primaryColor : const Color(0xFF666666), fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _mediaType == MediaType.image ? 'Image attachée'
                    : _mediaType == MediaType.video ? 'URL de la vidéo'
                    : 'Bloc de code',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
              GestureDetector(
                onTap: _clearMedia,
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_mediaType == MediaType.image)
            _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  )
                : GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(color: const Color(0xFFF0F3F8), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDDD))),
                      child: const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppTheme.primaryColor)),
                    ),
                  ),

          if (_mediaType == MediaType.video)
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                prefixIcon: const Icon(Icons.link, size: 18),
              ),
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 13),
            ),

          if (_mediaType == MediaType.code)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5F57))),
                        Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFBD2E))),
                        Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF28C840))),
                        const Spacer(),
                        const Text('code', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _codeController,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFCDD6F4), height: 1.5),
                    decoration: const InputDecoration(
                      hintText: '// Écrivez votre code ici...',
                      hintStyle: TextStyle(color: Color(0xFF555577), fontFamily: 'monospace'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Answer section ────────────────────────────────────────────────────────

  Widget _buildAnswerSection() {
    if (_quizType == QuizType.vraiFaux) return _buildVraiFauxSection();
    return _buildAnswerList();
  }

  Widget _buildVraiFauxSection() {
    return Row(
      children: [
        Expanded(child: _tfCard(true)),
        const SizedBox(width: 12),
        Expanded(child: _tfCard(false)),
      ],
    );
  }

  Widget _tfCard(bool value) {
    final selected = _vraiFauxAnswer == value;
    final color = value ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () => setState(() => _vraiFauxAnswer = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : const Color(0xFFE0E0E0), width: 2),
        ),
        child: Column(
          children: [
            Icon(value ? Icons.check_circle_outline : Icons.cancel_outlined, size: 36, color: selected ? color : const Color(0xFFBBBBBB)),
            const SizedBox(height: 8),
            Text(value ? 'Vrai' : 'Faux', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? color : const Color(0xFF444444))),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_answers.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildAnswerCard(i),
        )),
        if (_answers.length < 6)
          TextButton.icon(
            onPressed: _addAnswer,
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 18),
            label: const Text('Ajouter une réponse', style: TextStyle(color: AppTheme.primaryColor)),
          ),
      ],
    );
  }

  Widget _buildAnswerCard(int i) {
    final entry = _answers[i];
    final color = _colorFor(i);
    final isCorrect = entry.isCorrect;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCorrect ? Colors.green : const Color(0xFFE8E8E8), width: isCorrect ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11))),
            child: Icon(_iconFor(i), color: color, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: entry.controller,
              decoration: InputDecoration(hintText: 'Réponse ${i + 1}...', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => _toggleCorrect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26, height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: isCorrect ? Colors.green : Colors.transparent, border: Border.all(color: isCorrect ? Colors.green : const Color(0xFFCCCCCC), width: 2)),
              child: isCorrect ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
            ),
          ),
          if (_answers.length > 2)
            IconButton(onPressed: () => _removeAnswer(i), icon: const Icon(Icons.close, color: Color(0xFFCCCCCC), size: 18), padding: const EdgeInsets.only(right: 4), constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  // ── Points card ───────────────────────────────────────────────────────────

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('POINTS DE CETTE QUESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Color(0xFF999999))),
          const SizedBox(height: 12),
          Row(
            children: PointsType.values.map((pt) {
              final active = _pointsType == pt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _pointsType = pt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? pt.color.withOpacity(0.12) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? pt.color : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.star_rounded, size: 22, color: active ? pt.color : const Color(0xFFCCCCCC)),
                        const SizedBox(height: 4),
                        Text(pt.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? pt.color : const Color(0xFF999999))),
                        Text(
                          pt.multiplier == 0 ? '0 pt' : '×${pt.multiplier}',
                          style: TextStyle(fontSize: 10, color: active ? pt.color.withOpacity(0.7) : const Color(0xFFBBBBBB)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Score preview ─────────────────────────────────────────────────────────

  Widget _buildScorePreview() {
    final totalMult = _questions.fold(0, (s, q) => s + q.pointsType.multiplier);
    final breakdown = <String>[];
    for (final pt in PointsType.values) {
      final count = _questions.where((q) => q.pointsType == pt).length;
      if (count > 0 && pt != PointsType.none) {
        breakdown.add('$count × ${pt.label}(×${pt.multiplier})');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text('Aperçu du score /20', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          ...breakdown.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('• $b', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total points bruts : $totalMult', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Note max : 20/20',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Formule : (points obtenus / $totalMult) × 20',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ── Params card ───────────────────────────────────────────────────────────

  Widget _buildParamsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _paramRow('Temps imparti',
            Row(children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), isDense: true),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _timeLimit.toString()),
                  onChanged: (v) => _timeLimit = int.tryParse(v) ?? 20,
                ),
              ),
              const SizedBox(width: 4),
              const Text('s', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ]),
          ),
          const Divider(height: 1),
          _paramRow('Réponse correcte',
            Row(children: [
              _limitToggle('Unique',   AnswerLimitType.single),
              const SizedBox(width: 6),
              _limitToggle('Multiple', AnswerLimitType.multiple),
            ]),
          ),
          const Divider(height: 1),
          _paramRow('Visibilité',
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDDDDDD))),
              child: Row(children: [_accessToggle('Public', true), _accessToggle('Classe', false)]),
            ),
          ),
          if (!_isPublic) ...[
            const Divider(height: 1),
            _paramRow('Participants max',
              Row(children: [
                const Icon(Icons.people, size: 16, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 60,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _maxParticipants.toString()),
                    onChanged: (v) { final val = int.tryParse(v); if (val != null && val > 0) _maxParticipants = val; },
                  ),
                ),
              ]),
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
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.5)),
          control,
        ],
      ),
    );
  }

  Widget _limitToggle(String label, AnswerLimitType type) {
    final active = _answerLimit == type;
    return GestureDetector(
      onTap: () => setState(() {
        _answerLimit = type;
        if (type == AnswerLimitType.single) {
          bool found = false;
          for (final a in _answers) { if (a.isCorrect && !found) { found = true; } else { a.isCorrect = false; } }
          if (!found && _answers.isNotEmpty) _answers.first.isCorrect = true;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: active ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppTheme.primaryColor : const Color(0xFFDDDDDD))),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF666666))),
      ),
    );
  }

  Widget _accessToggle(String label, bool pub) {
    final active = _isPublic == pub;
    return GestureDetector(
      onTap: () => setState(() => _isPublic = pub),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: active ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(pub ? Icons.public : Icons.group, size: 14, color: active ? Colors.white : const Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: active ? Colors.white : const Color(0xFF666666))),
        ]),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool hasPrev) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF666666), size: 16),
              const SizedBox(width: 6),
              const Expanded(child: Text('Sauvegardez chaque question avant de passer à la suivante', style: TextStyle(fontSize: 12, color: Color(0xFF666666)))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // ← Précédente
              if (hasPrev) ...[
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _goToPrevious,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Préc.', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5F70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Annuler
              if (!hasPrev)
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                  ),
                ),

              const SizedBox(width: 6),

              // → Suivante
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _goToNext,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Suivante', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ✓ Terminer
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Terminer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}