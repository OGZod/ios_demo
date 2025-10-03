
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../utils/do_not_disturb_service.dart';
import '../../../utils/functions/check_student_id.dart';
import '../utils/bottom_sheet.dart';
import 'exam_screen.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<bool> canAccessExam(DocumentSnapshot examDoc) async {
    // Safely check if startTime exists and is not null
    final data = examDoc.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('startTime')) {
      Timestamp? startTimeStamp = data['startTime'];
      if (startTimeStamp != null) {
        DateTime startTime = startTimeStamp.toDate();
        DateTime now = DateTime.now();

        if (now.isBefore(startTime)) {
          // Calculate time remaining
          Duration timeRemaining = startTime.difference(now);
          String timeMessage = '';

          if (timeRemaining.inDays > 0) {
            timeMessage =
                '${timeRemaining.inDays} ${timeRemaining.inDays == 1 ? 'day' : 'days'}';
          } else if (timeRemaining.inHours > 0) {
            timeMessage =
                '${timeRemaining.inHours} ${timeRemaining.inHours == 1 ? 'hour' : 'hours'}';
          } else {
            timeMessage =
                '${timeRemaining.inMinutes} ${timeRemaining.inMinutes == 1 ? 'minute' : 'minutes'}';
          }

          EasyLoading.showToast(
            'This exam will be available in $timeMessage',
            toastPosition: EasyLoadingToastPosition.bottom,
          );
          return false;
        }
      }
    }

    // If there's no startTime or it's in the past, allow access
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    DndService().ensurePermission(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Exams'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await showCourseSelectionModal(context);
              setState(() {});
            },
            child: Icon(CupertinoIcons.plus_app_fill),
          ),
        ],
      ),
      body:
          (user != null && user.emailVerified)
              ? StreamBuilder<DocumentSnapshot>(
                // Changed to StreamBuilder
                stream:
                    _db
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(), // Stream of user document
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please select a school to view available exams.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await showSchoolSelectionModal(context);
                              setState(() {});
                            },
                            child: const Text('Select School'),
                          ),
                        ],
                      ),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null || userData['schoolId'] == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please select a school to view available exams.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await showSchoolSelectionModal(context);
                              setState(() {});
                            },
                            child: const Text('Select School'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (userData['courses'] == null ||
                      (userData['courses'] as List).isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please select courses to view available exams.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await showCourseSelectionModal(context);
                              setState(() {});
                            },
                            child: const Text('Select Courses'),
                          ),
                        ],
                      ),
                    );
                  }

                  final courses = (userData['courses'] as List).cast<String>();

                  return _buildExamList(courses);
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Please verify your email address to view available exams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await user?.sendEmailVerification();
                          if(context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email resent.'),
                            ),
                          );
                          }
                        } catch (e) {
                          if(context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to resend email: $e'),
                            ),
                          );
                          }
                        }
                      },
                      child: const Text('Resend Verification Email'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                      },
                      child: const Text('I\'ve Verified My Email'),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildExamList(List<String> courses) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('exams')
              .where('courseId', whereIn: courses)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text('No exams available for your school...Chill'),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final exam = snapshot.data!.docs[index];
            final examId = exam.id;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(exam['title']),
                subtitle: Text(exam['description'] ?? 'No description'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () async {
                  final hasID = await checkStudentId();
                  if (hasID) {
                    final res = await canAccessExam(exam);
                    if (res) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExamScreen(
                                examId: examId,
                                courseId: exam['courseId'],
                              ),
                        ),
                      );
                    }
                  } else {
                    if(context.mounted) showIdNumberInputDialog(context);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
