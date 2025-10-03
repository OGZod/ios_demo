import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentPerformanceScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const StudentPerformanceScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<StudentPerformanceScreen> createState() =>
      _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _enrolledStudents = [];
  List<QueryDocumentSnapshot> _exams = [];
  Map<String, Map<String, dynamic>> _studentScores = {};
  Map<String, Map<String, String>> _attemptIds =
      {}; // Store attempt IDs for deletion
  String _sortBy = 'identificationNumber';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load enrolled students
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('courses', arrayContains: widget.courseId)
              .get();

      // Load exams
      final examsSnapshot =
          await FirebaseFirestore.instance
              .collection('exams')
              .where('courseId', isEqualTo: widget.courseId)
              .get();

      setState(() {
        _enrolledStudents = studentsSnapshot.docs;
        _exams = examsSnapshot.docs;
      });

      // Calculate scores and store attempt IDs
      final result = await _calculateStudentScores(_enrolledStudents, _exams);

      setState(() {
        _studentScores = result.scores;
        _attemptIds = result.attemptIds;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sortStudents(String sortKey) {
    setState(() {
      if (_sortBy == sortKey) {
        // Toggle sort direction if clicking the same column
        _sortAscending = !_sortAscending;
      } else {
        // New column, default to ascending
        _sortBy = sortKey;
        _sortAscending = true;
      }
    });
  }

  List<MapEntry<String, Map<String, dynamic>>> _getSortedStudents() {
    final students = _studentScores.entries.toList();

    students.sort((a, b) {
      if (_sortBy == 'identificationNumber') {
        final nameA = a.value['identificationNumber'] as String? ?? '';
        final nameB = b.value['identificationNumber'] as String? ?? '';
        return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
      } else if (_sortBy == 'average30') {
        final avgA = a.value['average30'] as double? ?? 0.0;
        final avgB = b.value['average30'] as double? ?? 0.0;
        return _sortAscending ? avgA.compareTo(avgB) : avgB.compareTo(avgA);
      } else {
        // Sorting by exam score
        final scoreA = a.value[_sortBy] as double? ?? 0.0;
        final scoreB = b.value[_sortBy] as double? ?? 0.0;
        return _sortAscending
            ? scoreA.compareTo(scoreB)
            : scoreB.compareTo(scoreA);
      }
    });

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseName} - Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: () => _exportToCsv(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPerformanceContent(),
    );
  }

  Widget _buildPerformanceContent() {
    if (_enrolledStudents.isEmpty) {
      return const Center(child: Text('No students enrolled in this course.'));
    }

    if (_exams.isEmpty) {
      return const Center(child: Text('No exams created for this course yet.'));
    }

    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(child: _buildPerformanceTable()),
      ],
    );
  }

  Widget _buildSummaryCards() {
    // Calculate class average
    double classAverage = 0;
    int passingCount = 0;

    if (_studentScores.isNotEmpty) {
      for (final scores in _studentScores.values) {
        classAverage += (scores['average30'] as double? ?? 0.0);
        if ((scores['average30'] as double? ?? 0.0) >= 15.0) {
          passingCount++;
        }
      }
      classAverage /= _studentScores.length;
    }

    final passRate =
        _studentScores.isEmpty
            ? 0.0
            : (passingCount / _studentScores.length) * 100;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Class Average',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${classAverage.toStringAsFixed(1)}/30',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: classAverage < 15 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Pass Rate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${passRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: passRate < 50 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Students',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_enrolledStudents.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable() {
    final sortedStudents = _getSortedStudents();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(
              label: const Text(
                'Student',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _sortStudents('identificationNumber'),
            ),
            ..._exams.map((exam) {
              final examData = exam.data() as Map<String, dynamic>;
              final examId = exam.id;
              return DataColumn(
                label: Tooltip(
                  message: examData['title'] ?? 'Exam',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      examData['title'] ?? 'Exam',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onSort: (_, __) => _sortStudents(examId),
              );
            }),
            DataColumn(
              label: const Text(
                'Average/30',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              onSort: (_, __) => _sortStudents('average30'),
            ),
            DataColumn(
              label: const Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows:
              sortedStudents.map((entry) {
                final studentId = entry.key;
                final scores = entry.value;
                final studentName =
                    scores['identificationNumber'] as String? ?? 'Unknown';

                return DataRow(
                  cells: [
                    DataCell(Text(studentName)),
                    ..._exams.map((exam) {
                      final examId = exam.id;
                      final examData = exam.data() as Map<String, dynamic>;
                      final examTitle = examData['title'] ?? 'Exam';
                      final score = scores[examId] as double? ?? 0.0;
                      final hasAttempt =
                          _attemptIds[studentId]?[examId] != null;

                      return DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${score.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: score < 40 ? Colors.red : null,
                              ),
                            ),
                            if (hasAttempt)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete attempt',
                                onPressed:
                                    () => _showDeleteExamAttemptConfirmation(
                                      context,
                                      studentId,
                                      studentName,
                                      examId,
                                      examTitle,
                                      _attemptIds[studentId]![examId]!,
                                    ),
                              ),
                          ],
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        (scores['average30'] as double? ?? 0.0).toStringAsFixed(
                          1,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (scores['average30'] as double? ?? 0.0) < 15
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.red,
                        ),
                        tooltip: 'Remove student from course',
                        onPressed:
                            () => _showDeleteConfirmation(
                              context,
                              studentId,
                              studentName,
                            ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  // New method to show delete confirmation dialog for a specific exam attempt
  void _showDeleteExamAttemptConfirmation(
    BuildContext context,
    String studentId,
    String studentName,
    String examId,
    String examTitle,
    String attemptId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Exam Attempt'),
          content: Text(
            'Are you sure you want to delete $studentName\'s attempt for "$examTitle"?\n\n'
            'This will remove their score for this exam only.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteExamAttempt(studentId, examId, attemptId);
              },
            ),
          ],
        );
      },
    );
  }

  // New method to delete a specific exam attempt
  Future<void> _deleteExamAttempt(
    String studentId,
    String examId,
    String attemptId,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the specific exam attempt
      await FirebaseFirestore.instance
          .collection('exam_attempts')
          .doc(attemptId)
          .delete();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam attempt deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload data
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting exam attempt: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to show delete confirmation dialog for removing student from course
  void _showDeleteConfirmation(
    BuildContext context,
    String studentId,
    String studentName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Student'),
          content: Text(
            'Are you sure you want to remove $studentName from this course?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _removeStudentFromCourse(studentId);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to remove student from course
  Future<void> _removeStudentFromCourse(String studentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the student document
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();

      if (studentDoc.exists) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        final List<dynamic> courses = List.from(studentData['courses'] ?? []);

        // Remove this course from the student's courses array
        courses.remove(widget.courseId);

        // Update the student document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .update({'courses': courses});

        // Also delete their exam attempts for this course's exams
        for (final exam in _exams) {
          final examId = exam.id;
          final attemptsQuery =
              await FirebaseFirestore.instance
                  .collection('exam_attempts')
                  .where('examId', isEqualTo: examId)
                  .where('userId', isEqualTo: studentId)
                  .get();

          // Delete each attempt
          for (final attempt in attemptsQuery.docs) {
            await FirebaseFirestore.instance
                .collection('exam_attempts')
                .doc(attempt.id)
                .delete();
          }
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student removed from course successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Reload data
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing student: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated to track attempt IDs for each student and exam
  Future<StudentScoreResult> _calculateStudentScores(
    List<QueryDocumentSnapshot> students,
    List<QueryDocumentSnapshot> exams,
  ) async {
    final Map<String, Map<String, dynamic>> studentScores = {};
    final Map<String, Map<String, String>> attemptIds = {};

    // Initialize student data
    for (final student in students) {
      final studentData = student.data() as Map<String, dynamic>;
      studentScores[student.id] = {
        'identificationNumber':
            studentData['identificationNumber'] ?? 'Unknown',
      };
      attemptIds[student.id] = {};
    }

    // Get all exam attempts for this course
    if (exams.isNotEmpty) {
      final examIds = exams.map((exam) => exam.id).toList();
      final attemptsSnapshot =
          await FirebaseFirestore.instance
              .collection('exam_attempts')
              .where('examId', whereIn: examIds)
              .get();

      // Map exam attempts to students
      for (final attempt in attemptsSnapshot.docs) {
        final attemptData = attempt.data();
        final studentId = attemptData['userId'] as String?;
        final examId = attemptData['examId'] as String?;
        final score = attemptData['score'] as num? ?? 0;

        if (studentId != null &&
            examId != null &&
            studentScores.containsKey(studentId)) {
          studentScores[studentId]![examId] = score.toDouble();
          // Store the attempt ID for potential deletion
          attemptIds[studentId]![examId] = attempt.id;
        }
      }
    }

    // Calculate averages and fill in zeros for missing attempts
    for (final studentId in studentScores.keys) {
      double totalScore = 0;
      int examCount = 0;

      for (final exam in exams) {
        final examId = exam.id;
        // If student didn't take this exam, score is 0
        if (!studentScores[studentId]!.containsKey(examId)) {
          studentScores[studentId]![examId] = 0.0;
          examCount++;
        } else {
          // Only count exams they've actually taken
          examCount++;
          totalScore += (studentScores[studentId]![examId] as double? ?? 0.0);
        }
      }

      // Calculate average on 30 based on exams taken (avoid division by zero)
      final average = examCount == 0 ? 0.0 : (totalScore / examCount) * 0.3;
      studentScores[studentId]!['average30'] = average;
    }

    return StudentScoreResult(scores: studentScores, attemptIds: attemptIds);
  }

  void _exportToCsv() async {
    String csv = 'Student Name,';

    // Add exam titles as headers
    for (final exam in _exams) {
      final examData = exam.data() as Map<String, dynamic>;
      csv += '${examData['title'] ?? 'Exam'},';
    }
    csv += 'Average/30\n';

    // Add student data
    final sortedStudents = _getSortedStudents();
    for (final entry in sortedStudents) {
      final scores = entry.value;
      csv += '${scores['identificationNumber'] ?? 'Unknown'},';

      for (final exam in _exams) {
        final examId = exam.id;
        final score = scores[examId] as double? ?? 0.0;
        csv += '${score.toStringAsFixed(1)},';
      }

      csv += '${(scores['average30'] as double? ?? 0.0).toStringAsFixed(1)}\n';
    }

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: csv));

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV data copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class StudentScoreResult {
  final Map<String, Map<String, dynamic>> scores;
  final Map<String, Map<String, String>> attemptIds;

  StudentScoreResult({required this.scores, required this.attemptIds});
}

// class StudentPerformanceScreen extends StatefulWidget {
//   final String courseId;
//   final String courseName;
//
//   const StudentPerformanceScreen({
//     super.key,
//     required this.courseId,
//     required this.courseName,
//   });
//
//   @override
//   State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
// }
//
// class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
//   bool _isLoading = true;
//   List<QueryDocumentSnapshot> _enrolledStudents = [];
//   List<QueryDocumentSnapshot> _exams = [];
//   Map<String, Map<String, dynamic>> _studentScores = {};
//   String _sortBy = 'identificationNumber';
//   bool _sortAscending = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   Future<void> _loadData() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // Load enrolled students
//       final studentsSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('courses', arrayContains: widget.courseId)
//           .get();
//
//       // Load exams
//       final examsSnapshot = await FirebaseFirestore.instance
//           .collection('exams')
//           .where('courseId', isEqualTo: widget.courseId)
//           .get();
//
//       setState(() {
//         _enrolledStudents = studentsSnapshot.docs;
//         _exams = examsSnapshot.docs;
//       });
//
//       // Calculate scores
//       final scores = await _calculateStudentScores(_enrolledStudents, _exams);
//
//       setState(() {
//         _studentScores = scores;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading data: $e')),
//         );
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _sortStudents(String sortKey) {
//     setState(() {
//       if (_sortBy == sortKey) {
//         // Toggle sort direction if clicking the same column
//         _sortAscending = !_sortAscending;
//       } else {
//         // New column, default to ascending
//         _sortBy = sortKey;
//         _sortAscending = true;
//       }
//     });
//   }
//
//   List<MapEntry<String, Map<String, dynamic>>> _getSortedStudents() {
//     final students = _studentScores.entries.toList();
//
//     students.sort((a, b) {
//       if (_sortBy == 'identificationNumber') {
//         final nameA = a.value['identificationNumber'] as String? ?? '';
//         final nameB = b.value['identificationNumber'] as String? ?? '';
//         return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
//       } else if (_sortBy == 'average30') {
//         final avgA = a.value['average30'] as double? ?? 0.0;
//         final avgB = b.value['average30'] as double? ?? 0.0;
//         return _sortAscending ? avgA.compareTo(avgB) : avgB.compareTo(avgA);
//       } else {
//         // Sorting by exam score
//         final scoreA = a.value[_sortBy] as double? ?? 0.0;
//         final scoreB = b.value[_sortBy] as double? ?? 0.0;
//         return _sortAscending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
//       }
//     });
//
//     return students;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.courseName} - Performance'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh data',
//             onPressed: _loadData,
//           ),
//           IconButton(
//             icon: const Icon(Icons.download),
//             tooltip: 'Export to CSV',
//             onPressed: () => _exportToCsv(),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildPerformanceContent(),
//     );
//   }
//
//   Widget _buildPerformanceContent() {
//     if (_enrolledStudents.isEmpty) {
//       return const Center(child: Text('No students enrolled in this course.'));
//     }
//
//     if (_exams.isEmpty) {
//       return const Center(child: Text('No exams created for this course yet.'));
//     }
//
//     return Column(
//       children: [
//         _buildSummaryCards(),
//         Expanded(
//           child: _buildPerformanceTable(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSummaryCards() {
//     // Calculate class average
//     double classAverage = 0;
//     int passingCount = 0;
//
//     if (_studentScores.isNotEmpty) {
//       for (final scores in _studentScores.values) {
//         classAverage += (scores['average30'] as double? ?? 0.0);
//         if ((scores['average30'] as double? ?? 0.0) >= 15.0) {
//           passingCount++;
//         }
//       }
//       classAverage /= _studentScores.length;
//     }
//
//     final passRate = _studentScores.isEmpty
//         ? 0.0
//         : (passingCount / _studentScores.length) * 100;
//
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text('Class Average', style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${classAverage.toStringAsFixed(1)}/30',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: classAverage < 15 ? Colors.red : Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text('Pass Rate', style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${passRate.toStringAsFixed(1)}%',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: passRate < 50 ? Colors.red : Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text('Total Students', style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${_enrolledStudents.length}',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPerformanceTable() {
//     final sortedStudents = _getSortedStudents();
//
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: SingleChildScrollView(
//         child: DataTable(
//           columns: [
//             DataColumn(
//               label: const Text('Student', style: TextStyle(fontWeight: FontWeight.bold)),
//               onSort: (_, __) => _sortStudents('identificationNumber'),
//             ),
//             ..._exams.map((exam) {
//               final examData = exam.data() as Map<String, dynamic>;
//               final examId = exam.id;
//               return DataColumn(
//                 label: Tooltip(
//                   message: examData['title'] ?? 'Exam',
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 100),
//                     child: Text(
//                       examData['title'] ?? 'Exam',
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 onSort: (_, __) => _sortStudents(examId),
//               );
//             }),
//             DataColumn(
//               label: const Text('Average/30', style: TextStyle(fontWeight: FontWeight.bold)),
//               numeric: true,
//               onSort: (_, __) => _sortStudents('average30'),
//             ),
//           ],
//           rows: sortedStudents.map((entry) {
//             final scores = entry.value;
//             final studentName = scores['identificationNumber'] as String? ?? 'Unknown';
//
//             return DataRow(
//               cells: [
//                 DataCell(Text(studentName)),
//                 ..._exams.map((exam) {
//                   final examId = exam.id;
//                   final score = scores[examId] as double? ?? 0.0;
//                   return DataCell(
//                     Text(
//                       '${score.toStringAsFixed(1)}%',
//                       style: TextStyle(
//                         color: score < 40 ? Colors.red : null,
//                       ),
//                     ),
//                   );
//                 }),
//                 DataCell(
//                   Text(
//                     (scores['average30'] as double? ?? 0.0).toStringAsFixed(1),
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: (scores['average30'] as double? ?? 0.0) < 15 ? Colors.red : Colors.green,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Future<Map<String, Map<String, dynamic>>> _calculateStudentScores(
//       List<QueryDocumentSnapshot> students,
//       List<QueryDocumentSnapshot> exams,
//       ) async {
//     final Map<String, Map<String, dynamic>> studentScores = {};
//
//     // Initialize student data
//     for (final student in students) {
//       final studentData = student.data() as Map<String, dynamic>;
//       studentScores[student.id] = {
//         'identificationNumber': studentData['identificationNumber'] ?? 'Unknown',
//       };
//     }
//
//     // Get all exam attempts for this course
//     if (exams.isNotEmpty) {
//       final examIds = exams.map((exam) => exam.id).toList();
//       final attemptsSnapshot = await FirebaseFirestore.instance
//           .collection('exam_attempts')
//           .where('examId', whereIn: examIds)
//           .get();
//
//       // Map exam attempts to students
//       for (final attempt in attemptsSnapshot.docs) {
//         final attemptData = attempt.data();
//         final studentId = attemptData['userId'] as String?;
//         final examId = attemptData['examId'] as String?;
//         final score = attemptData['score'] as num? ?? 0;
//
//         if (studentId != null && examId != null && studentScores.containsKey(studentId)) {
//           studentScores[studentId]![examId] = score.toDouble();
//         }
//       }
//     }
//
//     // Calculate averages and fill in zeros for missing attempts
//     for (final studentId in studentScores.keys) {
//       double totalScore = 0;
//
//       for (final exam in exams) {
//         final examId = exam.id;
//         // If student didn't take this exam, score is 0
//         if (!studentScores[studentId]!.containsKey(examId)) {
//           studentScores[studentId]![examId] = 0.0;
//         }
//
//         totalScore += (studentScores[studentId]![examId] as double? ?? 0.0);
//       }
//
//       // Calculate average on 30
//       final average = exams.isEmpty ? 0.0 : (totalScore / exams.length) * 0.3;
//       studentScores[studentId]!['average30'] = average;
//     }
//
//     return studentScores;
//   }
//
//   void _exportToCsv() async {
//     String csv = 'Student Name,';
//
//     // Add exam titles as headers
//     for (final exam in _exams) {
//       final examData = exam.data() as Map<String, dynamic>;
//       csv += '${examData['title'] ?? 'Exam'},';
//     }
//     csv += 'Average/30\n';
//
//     // Add student data
//     final sortedStudents = _getSortedStudents();
//     for (final entry in sortedStudents) {
//       final scores = entry.value;
//       csv += '${scores['identificationNumber'] ?? 'Unknown'},';
//
//       for (final exam in _exams) {
//         final examId = exam.id;
//         final score = scores[examId] as double? ?? 0.0;
//         csv += '${score.toStringAsFixed(1)},';
//       }
//
//       csv += '${(scores['average30'] as double? ?? 0.0).toStringAsFixed(1)}\n';
//     }
//
//     // Copy to clipboard
//     await Clipboard.setData(ClipboardData(text: csv));
//
//     // Show success message
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('CSV data copied to clipboard'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }
