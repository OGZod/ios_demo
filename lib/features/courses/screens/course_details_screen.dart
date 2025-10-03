import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ios_demo/features/courses/screens/student_performance.dart';

import '../../admin/exam_details_sceen.dart';
import '../../test/screens/create_exam/create_exam_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;
  final String courseName;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exams - $courseName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateExamScreen(courseId: courseId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exams')
            .where('courseId', isEqualTo: courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final exams = snapshot.data?.docs ?? [];

          if (exams.isEmpty) {
            return const Center(child: Text('No exams found. Add an exam to get started.'));
          }

          return ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final examDoc = exams[index];
              final examData = examDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(examData['title'] ?? 'Untitled Exam'),
                  subtitle: Text('Duration: ${examData['duration']} minutes'),
                  trailing: Text('${(examData['questions'] as List?)?.length ?? 0} questions'),
                  onTap: () {
                    // Navigate to the exam details screen when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamDetailsScreen(exam: examDoc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentPerformanceScreen(
                courseId: courseId,
                courseName: courseName,
              ),
            ),
          );
        },
        icon: const Icon(Icons.analytics),
        label: const Text('Performance'),
        tooltip: 'View student performance',
      ),
    );
  }
}