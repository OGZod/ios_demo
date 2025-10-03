// exam_attempts_screen.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamAttemptsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Attempts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('exam_attempts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No exam attempts found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final attempt = snapshot.data!.docs[index];
              return ExamAttemptTile(attempt: attempt);
            },
          );
        },
      ),
    );
  }
}

class ExamAttemptTile extends StatelessWidget {
  final DocumentSnapshot attempt;

  const ExamAttemptTile({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final userId = attempt['userId'];
    final score = attempt['score'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text('Loading user data...'),
          );
        }


        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final studentNumber = userData?['identificationNumber'] ?? '';
        log(userData.toString());

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student Number: $studentNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Score: $score'),
                // You can add more details here, like the exam name, timestamp, etc.
              ],
            ),
          ),
        );
      },
    );
  }
}
