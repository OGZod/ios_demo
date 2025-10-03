// score_calculator.dart
class ScoreCalculator {
  static double calculate(List<Map<String, dynamic>> questions, Map<String, Map<String, dynamic>> answers) {
    if (questions.isEmpty) return 0;

    final correctAnswers = answers.values.where((answer) => answer['isCorrect'] == true).length;
    return (correctAnswers / questions.length) * 100; // Return percentage out of 100
  }
}
