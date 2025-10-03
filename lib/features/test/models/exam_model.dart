// models/exam_model.dart
class ExamModel {
  final String id;
  final int durationMinutes;
  final List<QuestionModel> questions;
  final Map<String, Map<String, dynamic>> answers = {}; // questionId: {answer, isCorrect}

  ExamModel({
    required this.id,
    required this.durationMinutes,
    required this.questions,
  });

  factory ExamModel.fromFirestore(String id, Map<String, dynamic> data) {
    final List<QuestionModel> questionsList = [];
    
    final questions = (data['questions'] as List? ?? []).cast<Map<String, dynamic>>();
    for (var i = 0; i < questions.length; i++) {
      questionsList.add(QuestionModel.fromMap(i.toString(), questions[i]));
    }
    
    return ExamModel(
      id: id,
      durationMinutes: data['duration'] as int? ?? 30,
      questions: questionsList,
    );
  }

  double calculateScore() {
    if (questions.isEmpty) return 0;
    final correctAnswers = answers.values.where((a) => a['isCorrect'] == true).length;
    return (correctAnswers / questions.length) * 100;
  }
}

// models/question_model.dart
class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final String correctAnswer;

  QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> data) {
    return QuestionModel(
      id: id,
      text: data['text'] as String,
      options: (data['options'] as List).cast<String>(),
      correctAnswer: data['correctAnswer'] as String,
    );
  }
}

// models/exam_result.dart
class ExamResult {
  final double score;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctAnswers;

  ExamResult({
    required this.score,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctAnswers,
  });
}