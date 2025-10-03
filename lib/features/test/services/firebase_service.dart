import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<Map<String, dynamic>?> getExamData(String examId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('exams').doc(examId).get();
      return snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      print('Error fetching exam data: $e');
      return null;
    }
  }

  static Future<void> submitExam(String examId,
      {required Map<String, Map<String, dynamic>> answers,
      required double score,
      String? studentId,
      required String reason}) async {
    try {
      await FirebaseFirestore.instance.collection('exam_attempts').add({
        'examId': examId,
        'answers': answers.values.toList(),
        'score': score,
        'studentId': studentId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting exam: $e');
    }
  }
}
