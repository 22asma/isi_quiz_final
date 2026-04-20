import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz.dart';

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> createQuiz({
    required String creatorId,
    required String title,
    String? description,
    required String quizType,
    required int timeLimit,
    required String pointsType,
    required bool isPublic,
    required int answerLimit,
  }) async {
    try {
      final pinCode = _generatePinCode();

      final response = await _supabase.from('quizzes').insert({
        'creator_id': creatorId,
        'title': title,
        'description': description,
        'quiz_type': quizType,
        'time_limit': timeLimit,
        'points_type': pointsType,
        'is_public': isPublic,
        'answer_limit': answerLimit,
        'pin_code': pinCode,
        'status': 'Actif', // Changé de 'Brouillon' à 'Actif'
      }).select('id').single();

      print('Quiz created successfully with ID: ${response['id']} and PIN: $pinCode');
      return response['id'] as String;
    } catch (e) {
      print('Error creating quiz: $e');
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
      final response = await _supabase.from('questions').insert({
        'quiz_id': quizId,
        'question_text': questionText,
        'question_order': questionOrder,
        'multimedia_url': multimediaUrl,
        'multimedia_type': multimediaType,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating question: $e');
      return null;
    }
  }

  Future<bool> createAnswers({
    required String questionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final answersData = answers
          .map((answer) => {
                'question_id': questionId,
                'answer_text': answer['text'],
                'is_correct': answer['is_correct'],
                'answer_order': answer['order'],
              })
          .toList();

      await _supabase.from('answers').insert(answersData);
      return true;
    } catch (e) {
      print('Error creating answers: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserQuizzes(String creatorId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id,
            title,
            description,
            quiz_type,
            time_limit,
            points_type,
            is_public,
            answer_limit,
            status,
            pin_code,
            created_at,
            updated_at,
            questions (
              id,
              question_text,
              question_order,
              multimedia_url,
              multimedia_type,
              answers (
                id,
                answer_text,
                is_correct,
                answer_order
              )
            )
          ''')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching instructor quizzes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQuizByPinCode(String pinCode) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id,
            title,
            description,
            quiz_type,
            time_limit,
            points_type,
            is_public,
            answer_limit,
            status,
            created_at,
            updated_at,
            creator_id,
            questions (
              id,
              question_text,
              question_order,
              multimedia_url,
              multimedia_type,
              answers (
                id,
                answer_text,
                is_correct,
                answer_order
              )
            )
          ''')
          .eq('pin_code', pinCode)
          .eq('is_public', true);
          // .eq('status', 'Actif')  // COMMENTÉ pour accepter tous les statuts

      // Vérifier si on a trouvé des résultats
      if (response.isEmpty) {
        print('No quiz found with PIN: $pinCode');
        return null;
      }

      // Retourner le premier résultat
      return response[0] as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching quiz by PIN: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPublicQuizzes() async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id,
            title,
            description,
            quiz_type,
            time_limit,
            points_type,
            answer_limit,
            status,
            created_at,
            creator_id,
            questions (count)
          ''')
          .eq('is_public', true)
          .eq('status', 'Actif')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching public quizzes: $e');
      return [];
    }
  }

  Future<bool> updateQuizStatus(String quizId, String status) async {
    try {
      await _supabase
          .from('quizzes')
          .update({'status': status}).eq('id', quizId);
      return true;
    } catch (e) {
      print('Error updating quiz status: $e');
      return false;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _supabase.from('quizzes').delete().eq('id', quizId);
      return true;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  String _generatePinCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  Future<bool> saveCompleteQuiz({
    required String creatorId,
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
      final quizId = await createQuiz(
        creatorId: creatorId,
        title: title,
        description: description,
        quizType: quizType,
        timeLimit: timeLimit,
        pointsType: pointsType,
        isPublic: isPublic,
        answerLimit: answerLimit,
      );

      if (quizId == null) return false;

      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];

        final questionId = await createQuestion(
          quizId: quizId,
          questionText: question['question_text'],
          multimediaUrl: question['multimedia_url'],
          multimediaType: question['multimedia_type'],
          questionOrder: i + 1,
        );

        if (questionId == null) return false;

        final answersSuccess = await createAnswers(
          questionId: questionId,
          answers: List<Map<String, dynamic>>.from(question['answers']),
        );

        if (!answersSuccess) return false;
      }

      // Le quiz est déjà en status 'Actif' grâce à createQuiz
      print('Complete quiz saved successfully with ID: $quizId');
      return true;
    } catch (e) {
      print('Error saving complete quiz: $e');
      return false;
    }
  }

  Future<bool> saveQuizResult({
    required String quizId,
    required String studentId,
    required int totalScore,
    required int maxPossibleScore,
    required double percentage,
    required List<Map<String, dynamic>> attempts,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('Error saving quiz result: no authenticated Supabase user');
        return false;
      }

      // Ensure profile exists with correct full_name
      final profileId = await _getOrCreateProfileId(currentUser.id);

      // Create quiz session
      final sessionResponse = await _supabase
          .from('quiz_sessions')
          .insert({
            'quiz_id': quizId,
            'session_code': _generateSessionCode(),
            'is_active': false,
            'started_at': DateTime.now().toIso8601String(),
            'ended_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final sessionId = sessionResponse['id'] as String;

      // Save attempts
      for (final attempt in attempts) {
        await _supabase.from('quiz_attempts').insert({
          'quiz_session_id': sessionId,
          'student_id': profileId,
          'question_id': attempt['question_id'],
          'selected_answer_id': attempt['selected_answer_id'],
          'is_correct': attempt['is_correct'],
          'time_taken': attempt['time_taken'],
          'answered_at': attempt['answered_at'],
        });
      }

      // Save result
      await _supabase.from('quiz_results').insert({
        'quiz_session_id': sessionId,
        'student_id': profileId,
        'total_score': totalScore,
        'max_possible_score': maxPossibleScore,
        'percentage': percentage,
        'completed_at': DateTime.now().toIso8601String(),
      });

      print('Quiz result saved successfully for session: $sessionId');
      return true;
    } catch (e) {
      print('Error saving quiz result: $e');
      return false;
    }
  }

  Future<String> _getOrCreateProfileId(String userId) async {
    try {
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Si le nom est toujours "Utilisateur", on le met à jour
        final currentName = existingProfile['full_name'] as String? ?? '';
        if (currentName.isEmpty || currentName == 'Utilisateur') {
          final realName = _getRealFullName();
          if (realName != 'Utilisateur') {
            await _supabase
                .from('profiles')
                .update({'full_name': realName}).eq('id', userId);
          }
        }
        return existingProfile['id'] as String;
      }

      // Profil n'existe pas → on le crée avec le vrai nom
      final currentUser = _supabase.auth.currentUser;
      final fullName = _getRealFullName();

      final insertResponse = await _supabase.from('profiles').insert({
        'id': userId,
        'email': currentUser?.email ?? '',
        'full_name': fullName,
      }).select('id').single();

      return insertResponse['id'] as String;
    } catch (e) {
      print('Error ensuring profile exists: $e');
      rethrow;
    }
  }

  String _getRealFullName() {
    final currentUser = _supabase.auth.currentUser;

    // Cherche dans userMetadata (données envoyées à l'inscription)
    final metaFullName =
        currentUser?.userMetadata?['full_name'] as String?;
    if (metaFullName != null && metaFullName.isNotEmpty) {
      return metaFullName;
    }

    // Cherche "name" comme alternative
    final metaName = currentUser?.userMetadata?['name'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      return metaName;
    }

    // Fallback : utilise la partie avant @ de l'email
    final email = currentUser?.email ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Anonyme';
  }

  String _generateSessionCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 100000;
    return random.toString().padLeft(5, '0');
  }

  Future<List<Map<String, dynamic>>> getQuizRankings(String quizId) async {
    try {
      final sessionsResponse = await _supabase
          .from('quiz_sessions')
          .select('id')
          .eq('quiz_id', quizId);

      if (sessionsResponse.isEmpty) return [];

      final sessionIds =
          sessionsResponse.map((s) => s['id'] as String).toList();

      final response = await _supabase
          .from('quiz_results')
          .select('''
            total_score,
            max_possible_score,
            percentage,
            completed_at,
            student_id,
            profiles!inner (
              full_name,
              email
            ),
            quiz_sessions (
              started_at
            )
          ''')
          .filter('quiz_session_id', 'in', sessionIds)
          .order('percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading quiz rankings: $e');
      return [];
    }
  }

  // Méthode de debug pour voir tous les quizzes
  Future<void> debugListAllQuizzes() async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('id, title, status, pin_code, is_public');
      
      print('=== ALL QUIZZES IN DATABASE ===');
      for (var quiz in response) {
        print('ID: ${quiz['id']}, Title: ${quiz['title']}, Status: ${quiz['status']}, PIN: ${quiz['pin_code']}, Public: ${quiz['is_public']}');
      }
      print('================================');
    } catch (e) {
      print('Error listing quizzes: $e');
    }
  }
}