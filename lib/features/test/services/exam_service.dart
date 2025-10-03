// services/exam_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';

import 'package:flutter/services.dart';
class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ExamModel> loadExam(String examId) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('exams')
          .doc(examId)
          .get();

      if (snapshot.exists) {
        final examData = snapshot.data() as Map<String, dynamic>?;
        if (examData != null) {
          return ExamModel.fromFirestore(examId, examData);
        }
      }
      
      throw Exception('Exam document not found or is invalid');
    } catch (e) {
      if (kDebugMode) {
        print('Error loading exam: $e');
      }
      throw Exception('Failed to load exam: $e');
    }
  }

  Future<ExamResult> submitExam(
      bool isFirstTime,
    ExamModel exam, {
    String reason = 'Manual submission',
    required String courseId,
  }) async {
    final double score = exam.calculateScore();
    final int totalQuestions = exam.questions.length;
    final int answeredQuestions = exam.answers.length;
    final int correctAnswers = exam.answers.values.where((a) => a['isCorrect'] == true).length;

    try {
      if(isFirstTime) {
        await _firestore.collection('exam_attempts').add({
          'examId': exam.id,
          'userId': _auth.currentUser?.uid,
          'courseId': courseId,
          'answers': exam.answers.entries.map((e) => {
            'questionId': e.key,
            'answer': e.value['answer'],
            'isCorrect': e.value['isCorrect'],
          }).toList(),
          'score': score,
          'totalQuestions': totalQuestions,
          'answeredQuestions': answeredQuestions,
          'correctAnswers': correctAnswers,
          'submissionReason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return ExamResult(
        score: score,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
        correctAnswers: correctAnswers,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting exam: $e');
      }
      throw Exception('Failed to submit exam: $e');
    }
  }
}