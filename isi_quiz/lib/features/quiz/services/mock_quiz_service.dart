import 'dart:math';
import '../models/quiz.dart';

class MockQuizService {
  static final MockQuizService _instance = MockQuizService._internal();
  factory MockQuizService() => _instance;
  MockQuizService._internal();

  static final List<Map<String, dynamic>> _mockQuizzes = [];
  static int _quizCounter = 1;

  Future<String?> createQuiz({
    required String instructorId,
    required String title,
    String? description,
    required String quizType,
    required int timeLimit,
    required String pointsType,
    required bool isPublic,
    required int answerLimit,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Mock: Creating quiz with instructorId: $instructorId');
      print('Mock: Current storage has ${_mockQuizzes.length} quizzes');
      
      // Generate 4-digit PIN code
      final pinCode = _generatePinCode();
      
      final quizId = 'quiz_${_quizCounter++}';
      
      final quizData = {
        'id': quizId,
        'instructor_id': instructorId,
        'title': title,
        'description': description,
        'quiz_type': quizType,
        'time_limit': timeLimit,
        'points_type': pointsType,
        'is_public': isPublic,
        'answer_limit': answerLimit,
        'pin_code': pinCode,
        'status': 'Brouillon',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _mockQuizzes.add(quizData);
      print('Mock quiz created successfully with ID: $quizId');
      print('Mock: Quiz data: $quizData');
      print('Mock: Total quizzes in storage after creation: ${_mockQuizzes.length}');
      
      return quizId;
    } catch (e) {
      print('Error creating mock quiz: $e');
      return null;
    }
  }

  Future<String?> createQuestion({
    required String quizId,
    required String questionText,
    String? multimediaUrl,
    String? multimediaType,
    required int questionOrder,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final questionId = 'question_${_mockQuizzes.length}_${questionOrder}';
      
      print('Mock question created successfully with ID: $questionId');
      
      return questionId;
    } catch (e) {
      print('Error creating mock question: $e');
      return null;
    }
  }

  Future<bool> createAnswers({
    required String questionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('Mock answers created successfully for question: $questionId');
      
      return true;
    } catch (e) {
      print('Error creating mock answers: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getInstructorQuizzes(String instructorId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('Mock: Fetching quizzes for instructor: $instructorId');
      print('Mock: Total quizzes in storage: ${_mockQuizzes.length}');
      print('Mock: All quizzes: $_mockQuizzes');
      
      final instructorQuizzes = _mockQuizzes
          .where((quiz) => quiz['instructor_id'] == instructorId)
          .toList();
      
      print('Mock: Found ${instructorQuizzes.length} quizzes for instructor');
      
      return instructorQuizzes;
    } catch (e) {
      print('Error fetching mock instructor quizzes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQuizByPinCode(String pinCode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final quiz = _mockQuizzes.firstWhere(
        (quiz) => quiz['pin_code'] == pinCode && quiz['is_public'] == true,
        orElse: () => {},
      );
      
      return quiz.isEmpty ? null : quiz;
    } catch (e) {
      print('Error fetching mock quiz by PIN: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPublicQuizzes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final publicQuizzes = _mockQuizzes
          .where((quiz) => quiz['is_public'] == true)
          .toList();
      
      return publicQuizzes;
    } catch (e) {
      print('Error fetching mock public quizzes: $e');
      return [];
    }
  }

  Future<bool> updateQuizStatus(String quizId, String status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final quizIndex = _mockQuizzes.indexWhere((quiz) => quiz['id'] == quizId);
      if (quizIndex != -1) {
        _mockQuizzes[quizIndex]['status'] = status;
        _mockQuizzes[quizIndex]['updated_at'] = DateTime.now().toIso8601String();
        print('Mock quiz status updated to: $status');
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating mock quiz status: $e');
      return false;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      _mockQuizzes.removeWhere((quiz) => quiz['id'] == quizId);
      print('Mock quiz deleted successfully: $quizId');
      
      return true;
    } catch (e) {
      print('Error deleting mock quiz: $e');
      return false;
    }
  }

  String _generatePinCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<bool> saveCompleteQuiz({
    required String instructorId,
    required String title,
    required String description,
    required String quizType,
    required int timeLimit,
    required String pointsType,
    required bool isPublic,
    required int answerLimit,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      print('Mock: Starting complete quiz save process...');
      
      // Create quiz
      final quizId = await createQuiz(
        instructorId: instructorId,
        title: title,
        description: description,
        quizType: quizType,
        timeLimit: timeLimit,
        pointsType: pointsType,
        isPublic: isPublic,
        answerLimit: answerLimit,
      );

      if (quizId == null) {
        print('Mock: Failed to create quiz');
        return false;
      }

      // Create questions and answers
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        
        final questionId = await createQuestion(
          quizId: quizId,
          questionText: question['question_text'],
          multimediaUrl: question['multimedia_url'],
          multimediaType: question['multimedia_type'],
          questionOrder: i + 1,
        );

        if (questionId == null) {
          print('Mock: Failed to create question');
          return false;
        }

        final answersSuccess = await createAnswers(
          questionId: questionId,
          answers: List<Map<String, dynamic>>.from(question['answers']),
        );

        if (!answersSuccess) {
          print('Mock: Failed to create answers');
          return false;
        }
      }

      // Update quiz status to Actif
      final statusUpdated = await updateQuizStatus(quizId, 'Actif');
      
      if (!statusUpdated) {
        print('Mock: Failed to update quiz status');
        return false;
      }

      print('Mock: Complete quiz saved successfully!');
      print('Mock quiz data: ${_mockQuizzes.last}');
      
      return true;
    } catch (e) {
      print('Mock error saving complete quiz: $e');
      return false;
    }
  }

  // Method to get all mock quizzes for debugging
  List<Map<String, dynamic>> getAllMockQuizzes() {
    return List.from(_mockQuizzes);
  }

  // Method to clear all mock data
  void clearMockData() {
    _mockQuizzes.clear();
    _quizCounter = 1;
    print('Mock data cleared');
  }

  // Method to add a test quiz for debugging
  void addTestQuiz(String instructorId) {
    final testQuiz = {
      'id': 'test_quiz_${_quizCounter++}',
      'instructor_id': instructorId,
      'title': 'Test Quiz - Debug',
      'description': 'Quiz de test pour le débogage',
      'quiz_type': 'Quiz',
      'time_limit': 20,
      'points_type': 'Standard',
      'is_public': true,
      'answer_limit': 1,
      'pin_code': _generatePinCode(),
      'status': 'Brouillon',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    _mockQuizzes.add(testQuiz);
    print('Mock: Test quiz added: $testQuiz');
    print('Mock: Total quizzes after adding test: ${_mockQuizzes.length}');
  }
}
