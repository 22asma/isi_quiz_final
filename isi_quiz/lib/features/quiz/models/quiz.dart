class Quiz {
  final String id;
  final String instructorId;
  final String title;
  final String? description;
  final String quizType;
  final int timeLimit;
  final String pointsType;
  final bool isPublic;
  final int answerLimit;
  final String status;
  final String? pinCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Question>? questions;

  Quiz({
    required this.id,
    required this.instructorId,
    required this.title,
    this.description,
    required this.quizType,
    required this.timeLimit,
    required this.pointsType,
    required this.isPublic,
    required this.answerLimit,
    required this.status,
    this.pinCode,
    required this.createdAt,
    required this.updatedAt,
    this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      instructorId: json['instructor_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      quizType: json['quiz_type'] as String,
      timeLimit: json['time_limit'] as int,
      pointsType: json['points_type'] as String,
      isPublic: json['is_public'] as bool,
      answerLimit: json['answer_limit'] as int,
      status: json['status'] as String,
      pinCode: json['pin_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instructor_id': instructorId,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'time_limit': timeLimit,
      'points_type': pointsType,
      'is_public': isPublic,
      'answer_limit': answerLimit,
      'status': status,
      'pin_code': pinCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Question {
  final String id;
  final String quizId;
  final String questionText;
  final int questionOrder;
  final String? multimediaUrl;
  final String? multimediaType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Answer>? answers;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionOrder,
    this.multimediaUrl,
    this.multimediaType,
    required this.createdAt,
    required this.updatedAt,
    this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionText: json['question_text'] as String,
      questionOrder: json['question_order'] as int,
      multimediaUrl: json['multimedia_url'] as String?,
      multimediaType: json['multimedia_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      answers: json['answers'] != null
          ? (json['answers'] as List)
              .map((a) => Answer.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_order': questionOrder,
      'multimedia_url': multimediaUrl,
      'multimedia_type': multimediaType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Answer {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final int answerOrder;
  final DateTime createdAt;

  Answer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.isCorrect,
    required this.answerOrder,
    required this.createdAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      answerText: json['answer_text'] as String,
      isCorrect: json['is_correct'] as bool,
      answerOrder: json['answer_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'answer_text': answerText,
      'is_correct': isCorrect,
      'answer_order': answerOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
