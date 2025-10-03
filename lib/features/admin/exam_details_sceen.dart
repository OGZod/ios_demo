
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ExamDetailsScreen extends StatefulWidget {
  final DocumentSnapshot exam;

  const ExamDetailsScreen({super.key, required this.exam});

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  String? courseName;
  String? schoolName;
  bool _isLoading = true;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _loadCourseAndSchoolInfo();
  }

  Future<void> _loadCourseAndSchoolInfo() async {
    try {
      final examData = widget.exam.data() as Map<String, dynamic>;
      final courseId = examData['courseId'];
      _isClosed = examData['isClosed'];

      if (courseId != null) {
        // Get course information
        DocumentSnapshot courseSnapshot =
            await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseId)
                .get();

        if (courseSnapshot.exists) {
          final courseData = courseSnapshot.data() as Map<String, dynamic>;
          courseName = courseData['name'];

          // Get school information
          final schoolId = courseData['schoolId'];
          if (schoolId != null) {
            DocumentSnapshot schoolSnapshot =
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .get();

            if (schoolSnapshot.exists) {
              final schoolData = schoolSnapshot.data() as Map<String, dynamic>;
              schoolName = schoolData['name'];
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading course and school info: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleExamStatus(String examId, bool newClosedValue) async {
    try {
      EasyLoading.show(status: 'Updating...');

      // Update Firestore
      await FirebaseFirestore.instance.collection('exams').doc(examId).update({
        'isClosed': newClosedValue,
      });

      // Update local state
      if (mounted) {
        setState(() {
          _isClosed = newClosedValue;
        });
      }

      EasyLoading.showToast(
        'Exam ${newClosedValue ? 'closed' : 'opened'} successfully',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      EasyLoading.showToast('Error updating exam status: $e');
      // Revert state if there was an error
      if (mounted) {
        setState(() {
          _isClosed = !newClosedValue;
        });
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  Future<void> _showDeleteConfirmation(
      BuildContext context, String examTitle) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "$examTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('exams')
                    .doc(widget.exam.id)
                    .delete();
                EasyLoading.showToast('Exam deleted successfully');
              } catch (e) {
                EasyLoading.showToast('Error deleting exam: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final examData = widget.exam.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit exam screen
              // You'll need to implement this
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context, examData['title']);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                examData['title'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (schoolName != null)
                                Text(
                                  'School: $schoolName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              if (courseName != null)
                                Text(
                                  'Course: $courseName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${examData['duration']} minutes',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.question_answer, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(examData['questions'] as List).length} questions',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exam Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Switch(
                                    value: _isClosed,
                                    activeColor: Colors.red,  // Red when closed (active)
                                    inactiveThumbColor: Colors.green,  // Green when open (inactive)
                                    onChanged: (newValue) {
                                      log("Switching to: $newValue");
                                      _toggleExamStatus(
                                        widget.exam.id,
                                        newValue,  // Pass the new value directly
                                      );
                                    },
                                  ),
                                  Text(
                                    _isClosed  // Use the state variable, not examData
                                        ? 'Closed'
                                        : 'Open',
                                    style: TextStyle(
                                      color: _isClosed  // Use the state variable, not examData
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (examData['description'] != null &&
                          examData['description'].toString().isNotEmpty)
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(examData['description']),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(examData['questions'] as List).asMap().entries.map<
                        Widget
                      >((entry) {
                        final int index = entry.key;
                        final question = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        question['text'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Options:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(
                                  (question['options'] as List).length,
                                  (optionIndex) {
                                    final option =
                                        question['options'][optionIndex];
                                    final isCorrect =
                                        option == question['correctAnswer'];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isCorrect
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color:
                                                isCorrect
                                                    ? Colors.green
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: TextStyle(
                                                color:
                                                    isCorrect
                                                        ? Colors.green
                                                        : null,
                                                fontWeight:
                                                    isCorrect
                                                        ? FontWeight.bold
                                                        : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
    );
  }
}
