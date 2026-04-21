import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz.dart';

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<String?> createQuiz({
    required String creatorId,
    required String title,
    String? description,
    required String quizType,
    required int timeLimit,
    required String pointsType,
    required bool isPublic,
    required int answerLimit,
    int? maxParticipants,
  }) async {
    try {
      final pinCode = _generatePinCode();

      final data = {
        'creator_id': creatorId,
        'title': title,
        'description': description,
        'quiz_type': quizType,
        'time_limit': timeLimit,
        'points_type': pointsType,
        'is_public': isPublic,
        'answer_limit': answerLimit,
        'pin_code': pinCode,
        'status': 'Actif',
        'current_participants': 0,
        'session_status': 'waiting',
      };

      // max_participants uniquement pour les quiz de groupe (non public)
      if (!isPublic && maxParticipants != null) {
        data['max_participants'] = maxParticipants;
      }

      final response = await _supabase
          .from('quizzes')
          .insert(data)
          .select('id')
          .single();

      print('Quiz créé avec ID: ${response['id']} et PIN: $pinCode');
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

  Future<bool> saveCompleteQuiz({
    required String creatorId,
    required String title,
    required String description,
    required String quizType,
    required int timeLimit,
    required String pointsType,
    required bool isPublic,
    required int answerLimit,
    int? maxParticipants,
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
        maxParticipants: maxParticipants,
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

      print('Quiz complet sauvegardé avec ID: $quizId');
      return true;
    } catch (e) {
      print('Error saving complete quiz: $e');
      return false;
    }
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserQuizzes(String creatorId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id, title, description, quiz_type, time_limit, points_type,
            is_public, answer_limit, status, pin_code,
            max_participants, current_participants, session_status, started_by,
            created_at, updated_at,
            questions (
              id, question_text, question_order, multimedia_url, multimedia_type,
              answers ( id, answer_text, is_correct, answer_order )
            )
          ''')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user quizzes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPublicQuizzes() async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id, title, description, quiz_type, time_limit,
            points_type, answer_limit, status, created_at, creator_id,
            pin_code, questions (count)
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

  /// Récupère un quiz par son PIN (public ou groupe)
  Future<Map<String, dynamic>?> getQuizByPinCode(String pinCode) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id, title, description, quiz_type, time_limit, points_type,
            is_public, answer_limit, status, created_at, updated_at, creator_id,
            max_participants, current_participants, session_status, started_by,
            questions (
              id, question_text, question_order, multimedia_url, multimedia_type,
              answers ( id, answer_text, is_correct, answer_order )
            )
          ''')
          .eq('pin_code', pinCode)
          .eq('status', 'Actif');

      if (response.isEmpty) {
        print('Aucun quiz trouvé avec le PIN: $pinCode');
        return null;
      }

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching quiz by PIN: $e');
      return null;
    }
  }

  /// Récupère un quiz complet par son ID (avec toutes les questions et réponses)
  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('''
            id, title, description, quiz_type, time_limit, points_type,
            is_public, answer_limit, status, pin_code, created_at, updated_at, creator_id,
            max_participants, current_participants, session_status, started_by,
            questions (
              id, question_text, question_order, multimedia_url, multimedia_type,
              answers ( id, answer_text, is_correct, answer_order )
            )
          ''')
          .eq('id', quizId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching quiz by ID: $e');
      return null;
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

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

  // ─── GROUP QUIZ ───────────────────────────────────────────────────────────

  /// Le créateur démarre le quiz de groupe → session_status = 'started'
  Future<bool> startGroupQuiz(String quizId, String userId) async {
    try {
      // Vérifie que c'est bien le créateur
      final quiz = await _supabase
          .from('quizzes')
          .select('creator_id, is_public, session_status')
          .eq('id', quizId)
          .single();

      if (quiz['creator_id'] != userId) {
        print('Seul le créateur peut démarrer ce quiz');
        return false;
      }
      if (quiz['is_public'] == true) {
        print('Les quiz publics ne nécessitent pas de démarrage');
        return false;
      }
      if (quiz['session_status'] != 'waiting') {
        print('Le quiz est déjà démarré ou terminé');
        return false;
      }

      await _supabase.from('quizzes').update({
        'session_status': 'started',
        'started_by': userId,
      }).eq('id', quizId);

      print('Quiz de groupe démarré: $quizId');
      return true;
    } catch (e) {
      print('Error starting group quiz: $e');
      return false;
    }
  }

  /// Un participant rejoint la salle d'attente du quiz de groupe
  Future<GroupJoinResult> joinGroupQuiz(String quizId, String userId) async {
    try {
      final quiz = await _supabase
          .from('quizzes')
          .select('current_participants, max_participants, session_status, is_public')
          .eq('id', quizId)
          .single();

      if (quiz['is_public'] == true) {
        return GroupJoinResult.notGroupQuiz;
      }
      if (quiz['session_status'] == 'finished') {
        return GroupJoinResult.quizFinished;
      }

      final currentParticipants = quiz['current_participants'] as int? ?? 0;
      final maxParticipants = quiz['max_participants'] as int?;

      if (maxParticipants != null && currentParticipants >= maxParticipants) {
        return GroupJoinResult.quizFull;
      }

      // Vérifier si déjà inscrit
      final existing = await _supabase
          .from('quiz_participants')
          .select('id')
          .eq('quiz_id', quizId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Inscrire le participant
        await _supabase.from('quiz_participants').insert({
          'quiz_id': quizId,
          'user_id': userId,
        });

        // Incrémenter le compteur
        await _supabase.from('quizzes').update({
          'current_participants': currentParticipants + 1,
        }).eq('id', quizId);
      }

      // Retourner le statut actuel de la session
      if (quiz['session_status'] == 'started') {
        return GroupJoinResult.startedCanPlay;
      }
      return GroupJoinResult.waitingForCreator;
    } catch (e) {
      print('Error joining group quiz: $e');
      return GroupJoinResult.error;
    }
  }

  /// Vérifie le statut actuel d'un quiz de groupe (pour le polling)
  Future<String> getGroupQuizStatus(String quizId) async {
    try {
      final quiz = await _supabase
          .from('quizzes')
          .select('session_status')
          .eq('id', quizId)
          .single();
      return quiz['session_status'] as String? ?? 'waiting';
    } catch (e) {
      print('Error getting group quiz status: $e');
      return 'waiting';
    }
  }

  /// Vérifie si l'utilisateur est déjà inscrit à ce quiz de groupe
  Future<bool> isAlreadyJoined(String quizId, String userId) async {
    try {
      final existing = await _supabase
          .from('quiz_participants')
          .select('id')
          .eq('quiz_id', quizId)
          .eq('user_id', userId)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      return false;
    }
  }

  // ─── RESULTS ─────────────────────────────────────────────────────────────

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
        print('Error: no authenticated user');
        return false;
      }

      final profileId = await _getOrCreateProfileId(currentUser.id);

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

      await _supabase.from('quiz_results').insert({
        'quiz_session_id': sessionId,
        'student_id': profileId,
        'total_score': totalScore,
        'max_possible_score': maxPossibleScore,
        'percentage': percentage,
        'completed_at': DateTime.now().toIso8601String(),
      });

      print('Résultat sauvegardé pour la session: $sessionId');
      return true;
    } catch (e) {
      print('Error saving quiz result: $e');
      return false;
    }
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
            total_score, max_possible_score, percentage, completed_at, student_id,
            profiles!inner ( full_name, email ),
            quiz_sessions ( started_at )
          ''')
          .filter('quiz_session_id', 'in', sessionIds)
          .order('percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading quiz rankings: $e');
      return [];
    }
  }

  // ─── PROFILE ─────────────────────────────────────────────────────────────

  Future<String> _getOrCreateProfileId(String userId) async {
    try {
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
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
    final metaFullName = currentUser?.userMetadata?['full_name'] as String?;
    if (metaFullName != null && metaFullName.isNotEmpty) return metaFullName;
    final metaName = currentUser?.userMetadata?['name'] as String?;
    if (metaName != null && metaName.isNotEmpty) return metaName;
    final email = currentUser?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Anonyme';
  }

  // ─── USER STATS ────────────────────────────────────────────────────────────

  Future<int> getUserCreatedQuizzesCount(String userId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('id')
          .eq('creator_id', userId);
      
      return response.length;
    } catch (e) {
      print('Error counting user quizzes: $e');
      return 0;
    }
  }

  Future<int> getUserParticipatedQuizzesCount(String userId) async {
    try {
      // Get user's profile ID first
      final profileId = await _getOrCreateProfileId(userId);
      
      // Count distinct quiz sessions where user participated
      final response = await _supabase
          .from('quiz_results')
          .select('quiz_sessions!inner(quiz_id)')
          .eq('student_id', profileId);
      
      // Count unique quiz IDs
      final Set<String> uniqueQuizIds = {};
      for (final result in response) {
        final quizId = result['quiz_sessions']?['quiz_id'] as String?;
        if (quizId != null) {
          uniqueQuizIds.add(quizId);
        }
      }
      
      return uniqueQuizIds.length;
    } catch (e) {
      print('Error counting participated quizzes: $e');
      return 0;
    }
  }

  // ─── UTILS ────────────────────────────────────────────────────────────────

  String _generatePinCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  String _generateSessionCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 100000;
    return random.toString().padLeft(5, '0');
  }
}

// ─── Enum pour le résultat du joinGroupQuiz ───────────────────────────────────

enum GroupJoinResult {
  waitingForCreator, // Rejoint, en attente que le créateur démarre
  startedCanPlay,    // Le quiz a déjà commencé, peut jouer
  quizFull,          // Nombre max de participants atteint
  quizFinished,      // Quiz déjà terminé
  notGroupQuiz,      // C'est un quiz public, pas de groupe
  error,             // Erreur technique
}