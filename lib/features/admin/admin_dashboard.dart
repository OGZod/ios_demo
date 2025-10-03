// admin_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../test/screens/create_exam/create_exam_screen.dart';
import 'exam_attempts.dart';
import 'exam_details_sceen.dart';

class AdminDashboard extends StatelessWidget {
  final _examsRef = FirebaseFirestore.instance.collection('exams');

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Dashboard'),

      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createNewExam(context),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExamAttemptsScreen()),
              );
            },
            child: const Text('View Exam Attempts'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _examsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final exam = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(exam['title']),
                      subtitle: Text('Questions: ${(exam['questions']).length}'),
                      onTap: () => _showExamDetails(context, exam),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createNewExam(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateExamScreen(courseId: '',);
      },
    );
  }

  void _showExamDetails(BuildContext context, DocumentSnapshot exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamDetailsScreen(exam: exam),
      ),
    );  }
}
