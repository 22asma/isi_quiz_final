import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (!isPublic && maxParticipants != null) {
        data['max_participants'] = maxParticipants;
      }
      final response = await _supabase
          .from('quizzes')
          .insert(data)
          .select('id')
          .single();
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
      final answersData = answers.map((a) => {
        'question_id': questionId,
        'answer_text': a['text'],
        'is_correct': a['is_correct'],
        'answer_order': a['order'],
      }).toList();
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
        final q = questions[i];
        final questionId = await createQuestion(
          quizId: quizId,
          questionText: q['question_text'],
          multimediaUrl: q['multimedia_url'],
          multimediaType: q['multimedia_type'],
          questionOrder: i + 1,
        );
        if (questionId == null) return false;
        final ok = await createAnswers(
          questionId: questionId,
          answers: List<Map<String, dynamic>>.from(q['answers']),
        );
        if (!ok) return false;
      }
      return true;
    } catch (e) {
      print('Error saving complete quiz: $e');
      return false;
    }
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserQuizzes(String creatorId) async {
    try {
      final response = await _supabase.from('quizzes').select('''
        id, title, description, quiz_type, time_limit, points_type,
        is_public, answer_limit, status, pin_code,
        max_participants, current_participants, session_status, started_by,
        created_at, updated_at,
        questions (
          id, question_text, question_order, multimedia_url, multimedia_type,
          answers ( id, answer_text, is_correct, answer_order )
        )
      ''').eq('creator_id', creatorId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user quizzes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPublicQuizzes() async {
    try {
      final response = await _supabase.from('quizzes').select('''
        id, title, description, quiz_type, time_limit,
        points_type, answer_limit, status, created_at, creator_id,
        pin_code, questions (count)
      ''').eq('is_public', true).eq('status', 'Actif')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching public quizzes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQuizByPinCode(String pinCode) async {
    try {
      final response = await _supabase.from('quizzes').select('''
        id, title, description, quiz_type, time_limit, points_type,
        is_public, answer_limit, status, created_at, updated_at, creator_id,
        max_participants, current_participants, session_status, started_by,
        questions (
          id, question_text, question_order, multimedia_url, multimedia_type,
          answers ( id, answer_text, is_correct, answer_order )
        )
      ''').eq('pin_code', pinCode).eq('status', 'Actif');
      if (response.isEmpty) return null;
      return response[0] as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching quiz by PIN: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQuizById(String quizId) async {
    try {
      final response = await _supabase.from('quizzes').select('''
        id, title, description, quiz_type, time_limit, points_type,
        is_public, answer_limit, status, pin_code, created_at, updated_at, creator_id,
        max_participants, current_participants, session_status, started_by,
        questions (
          id, question_text, question_order, multimedia_url, multimedia_type,
          answers ( id, answer_text, is_correct, answer_order )
        )
      ''').eq('id', quizId).single();
      return response;
    } catch (e) {
      print('Error fetching quiz by ID: $e');
      return null;
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<bool> updateQuizStatus(String quizId, String status) async {
    try {
      await _supabase.from('quizzes').update({'status': status}).eq('id', quizId);
      return true;
    } catch (e) {
      print('Error updating quiz status: $e');
      return false;
    }
  }

  Future<bool> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    String? quizType,
    int? timeLimit,
    String? pointsType,
    bool? isPublic,
    int? answerLimit,
    int? maxParticipants,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (quizType != null) data['quiz_type'] = quizType;
      if (timeLimit != null) data['time_limit'] = timeLimit;
      if (pointsType != null) data['points_type'] = pointsType;
      if (isPublic != null) data['is_public'] = isPublic;
      if (answerLimit != null) data['answer_limit'] = answerLimit;
      if (maxParticipants != null) data['max_participants'] = maxParticipants;
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('quizzes').update(data).eq('id', quizId);
      return true;
    } catch (e) {
      print('Error updating quiz: $e');
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

  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _supabase.from('questions').delete().eq('id', questionId);
      return true;
    } catch (e) {
      print('Error deleting question: $e');
      return false;
    }
  }

  Future<bool> deleteAnswersByQuestionId(String questionId) async {
    try {
      await _supabase.from('answers').delete().eq('question_id', questionId);
      return true;
    } catch (e) {
      print('Error deleting answers: $e');
      return false;
    }
  }

  Future<bool> updateQuizWithQuestions({
    required String quizId,
    String? title,
    String? description,
    String? quizType,
    int? timeLimit,
    String? pointsType,
    bool? isPublic,
    int? answerLimit,
    int? maxParticipants,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final updated = await updateQuiz(
        quizId: quizId, title: title, description: description,
        quizType: quizType, timeLimit: timeLimit, pointsType: pointsType,
        isPublic: isPublic, answerLimit: answerLimit,
        maxParticipants: maxParticipants,
      );
      if (!updated) return false;

      final existingQuiz = await getQuizById(quizId);
      if (existingQuiz != null && existingQuiz['questions'] != null) {
        for (final q in existingQuiz['questions']) {
          await deleteAnswersByQuestionId(q['id']);
          await deleteQuestion(q['id']);
        }
      }

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final questionId = await createQuestion(
          quizId: quizId,
          questionText: q['question_text'],
          multimediaUrl: q['multimedia_url'],
          multimediaType: q['multimedia_type'],
          questionOrder: i + 1,
        );
        if (questionId == null) return false;
        final ok = await createAnswers(
          questionId: questionId,
          answers: List<Map<String, dynamic>>.from(q['answers']),
        );
        if (!ok) return false;
      }
      return true;
    } catch (e) {
      print('Error updating quiz with questions: $e');
      return false;
    }
  }

  // ─── GROUP QUIZ ───────────────────────────────────────────────────────────

  Future<bool> startGroupQuiz(String quizId, String userId) async {
    try {
      final quiz = await _supabase.from('quizzes')
          .select('creator_id, is_public, session_status')
          .eq('id', quizId).single();
      if (quiz['creator_id'] != userId) return false;
      if (quiz['is_public'] == true) return false;
      if (quiz['session_status'] != 'waiting') return false;
      await _supabase.from('quizzes').update({
        'session_status': 'started',
        'started_by': userId,
      }).eq('id', quizId);
      return true;
    } catch (e) {
      print('Error starting group quiz: $e');
      return false;
    }
  }

  Future<GroupJoinResult> joinGroupQuiz(String quizId, String userId) async {
    try {
      final quiz = await _supabase.from('quizzes')
          .select('current_participants, max_participants, session_status, is_public')
          .eq('id', quizId).single();
      if (quiz['is_public'] == true) return GroupJoinResult.notGroupQuiz;
      if (quiz['session_status'] == 'finished') return GroupJoinResult.quizFinished;

      final current = quiz['current_participants'] as int? ?? 0;
      final max = quiz['max_participants'] as int?;
      if (max != null && current >= max) return GroupJoinResult.quizFull;

      final existing = await _supabase.from('quiz_participants')
          .select('id').eq('quiz_id', quizId).eq('user_id', userId).maybeSingle();

      if (existing == null) {
        await _supabase.from('quiz_participants').insert({
          'quiz_id': quizId, 'user_id': userId,
        });
        await _supabase.from('quizzes')
            .update({'current_participants': current + 1}).eq('id', quizId);
      }
      return quiz['session_status'] == 'started'
          ? GroupJoinResult.startedCanPlay
          : GroupJoinResult.waitingForCreator;
    } catch (e) {
      print('Error joining group quiz: $e');
      return GroupJoinResult.error;
    }
  }

  Future<String> getGroupQuizStatus(String quizId) async {
    try {
      final quiz = await _supabase.from('quizzes')
          .select('session_status').eq('id', quizId).single();
      return quiz['session_status'] as String? ?? 'waiting';
    } catch (e) {
      return 'waiting';
    }
  }

  Future<bool> isAlreadyJoined(String quizId, String userId) async {
    try {
      final existing = await _supabase.from('quiz_participants')
          .select('id').eq('quiz_id', quizId).eq('user_id', userId).maybeSingle();
      return existing != null;
    } catch (e) {
      return false;
    }
  }

  // ─── RESULTS ──────────────────────────────────────────────────────────────

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
      if (currentUser == null) return false;

      // ✅ FIX PRINCIPAL : upsert du profil EN PREMIER
      // Garantit que le profil existe avant toute jointure profiles!inner
      await _supabase.from('profiles').upsert({
        'id': currentUser.id,
        'email': currentUser.email ?? '',
        'full_name': _getRealFullName(),
      }, onConflict: 'id');

      // Créer la session
      final sessionResponse = await _supabase.from('quiz_sessions').insert({
        'quiz_id': quizId,
        'session_code': _generateSessionCode(),
        'is_active': false,
        'started_at': DateTime.now().toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final sessionId = sessionResponse['id'] as String;

      // Insérer les tentatives
      for (final attempt in attempts) {
        await _supabase.from('quiz_attempts').insert({
          'quiz_session_id': sessionId,
          'student_id': currentUser.id,
          'question_id': attempt['question_id'],
          'selected_answer_id': attempt['selected_answer_id'],
          'is_correct': attempt['is_correct'],
          'time_taken': attempt['time_taken'],
          'answered_at': attempt['answered_at'],
        });
      }

      // Insérer le résultat
      await _supabase.from('quiz_results').insert({
        'quiz_session_id': sessionId,
        'student_id': currentUser.id,
        'total_score': totalScore,
        'max_possible_score': maxPossibleScore,
        'percentage': percentage,
        'completed_at': DateTime.now().toIso8601String(),
      });

      print('Résultat sauvegardé, session: $sessionId');
      return true;
    } catch (e) {
      print('Error saving quiz result: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getQuizRankings(String quizId) async {
    try {
      final sessionsResponse = await _supabase
          .from('quiz_sessions').select('id').eq('quiz_id', quizId);
      if (sessionsResponse.isEmpty) return [];

      final sessionIds = sessionsResponse.map((s) => s['id'] as String).toList();

      final response = await _supabase.from('quiz_results').select('''
        total_score, max_possible_score, percentage, completed_at, student_id,
        profiles!inner ( full_name, email ),
        quiz_sessions ( started_at )
      ''').filter('quiz_session_id', 'in', sessionIds)
          .order('percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading quiz rankings: $e');
      return [];
    }
  }

  // ─── PROFILE ─────────────────────────────────────────────────────────────

  /// Appelé au login pour garantir l'existence du profil dès la 1ère session
  Future<void> ensureProfileOnLogin() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    try {
      await _supabase.from('profiles').upsert({
        'id': currentUser.id,
        'email': currentUser.email ?? '',
        'full_name': _getRealFullName(),
      }, onConflict: 'id');
      print('Profile upserted on login for: ${currentUser.id}');
    } catch (e) {
      print('Error upserting profile on login: $e');
    }
  }

  String _getRealFullName() {
    final user = _supabase.auth.currentUser;
    final metaFull = user?.userMetadata?['full_name'] as String?;
    if (metaFull != null && metaFull.isNotEmpty) return metaFull;
    final metaName = user?.userMetadata?['name'] as String?;
    if (metaName != null && metaName.isNotEmpty) return metaName;
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Anonyme';
  }

  // ─── USER STATS ───────────────────────────────────────────────────────────

  Future<int> getUserCreatedQuizzesCount(String userId) async {
    try {
      final response = await _supabase.from('quizzes')
          .select('id').eq('creator_id', userId);
      return response.length;
    } catch (e) {
      print('Error counting user quizzes: $e');
      return 0;
    }
  }

  Future<int> getUserParticipatedQuizzesCount(String userId) async {
    try {
      // ✅ Utilise directement userId (= profiles.id) sans appel à _getOrCreateProfileId
      final response = await _supabase.from('quiz_results')
          .select('quiz_sessions!inner(quiz_id)')
          .eq('student_id', userId);

      final Set<String> uniqueQuizIds = {};
      for (final result in response) {
        final qid = result['quiz_sessions']?['quiz_id'] as String?;
        if (qid != null) uniqueQuizIds.add(qid);
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

enum GroupJoinResult {
  waitingForCreator,
  startedCanPlay,
  quizFull,
  quizFinished,
  notGroupQuiz,
  error,
}