// import 'dart:async';
// import 'dart:developer';
// import 'package:assessflow/utils/do_not_disturb_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
//
// import '../models/exam_model.dart';
// import '../services/exam_service.dart';
// import '../widgets/widgets.dart';
//
// class ExamScreen extends StatefulWidget {
//   final String examId;
//   final String courseId;
//
//   const ExamScreen({super.key, required this.examId, required this.courseId});
//
//   @override
//   State<ExamScreen> createState() => _ExamScreenState();
// }
//
// class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
//   late Timer _timer;
//   Duration _duration = Duration.zero;
//   final ExamService _examService = ExamService();
//   final DndService _dndService = DndService();
//   final user = FirebaseAuth.instance.currentUser;
//
//   late ExamModel _examModel;
//   bool _isExamActive = true;
//   int _currentQuestionIndex = 0;
//   bool _isLoading = true;
//   bool _isFirstTime = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WakelockPlus.enable();
//     WidgetsBinding.instance.addObserver(this);
//     _dndService.enableDnd();
//     _loadExam();
//   }
//
//   Future<void> _loadExam() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final submissionSnapshot =
//           await FirebaseFirestore.instance
//               .collection('exam_attempts')
//               .where('examId', isEqualTo: widget.examId)
//               .where('userId', isEqualTo: user?.uid)
//               .get();
//
//       _isFirstTime = submissionSnapshot.docs.isEmpty;
//
//       log(_isFirstTime.toString(), name: 'ISFIRSTTIME');
//
//       final examData = await _examService.loadExam(widget.examId);
//       setState(() {
//         _examModel = examData;
//         _duration = Duration(minutes: _examModel.durationMinutes);
//         _isLoading = false;
//         if (_isFirstTime) _startExam();
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading exam: $e');
//       }
//       setState(() {
//         _isLoading = false;
//       });
//       // Show error message
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading exam: $e')));
//       Navigator.pop(context);
//     }
//   }
//
//   void _startExam() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _duration -= const Duration(seconds: 1);
//         if (_duration.inSeconds <= 0) {
//           if (kDebugMode) {
//             print('Timer has reached zero, submitting exam');
//           }
//           _submitExam('Time expired');
//         }
//       });
//     });
//   }
//
// // Replace your existing _submitExam method with this updated version
//   void _submitExam([String reason = 'Manual submission']) async {
//     if (!_isExamActive) {
//       if (kDebugMode) {
//         print("Exam already submitted, ignoring this call");
//       }
//       return;
//     }
//
//     EasyLoading.show(status: 'Submitting your score, please wait...');
//
//     _isExamActive = false;
//     if (_isFirstTime) _timer.cancel();
//
//     try {
//       final result = await _examService.submitExam(
//         _isFirstTime,
//         _examModel,
//         reason: reason,
//         courseId: widget.courseId,
//       );
//
//       EasyLoading.dismiss();
//
//       if(_isFirstTime) Navigator.pop(context);
//
//       // Show result popup instead of Snackbar
//       if (context.mounted) {
//         _showExamResultDialog(result.score);
//       }
//
//       if (_isFirstTime) {
//         setState(() {
//           _isFirstTime = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error submitting exam: $e');
//       }
//       EasyLoading.dismiss();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error submitting exam: $e. Please try again.')),
//       );
//       setState(() {
//         _isExamActive = true; // Allow them to try submitting again
//       });
//     }
//   }
//
// // Add this new method to show the result dialog
//   void _showExamResultDialog(double score) {
//     // Generate motivational message based on score
//     String message;
//     String emoji;
//
//     if (score >= 90) {
//       message = "Excellent work! You've mastered this material.";
//       emoji = "🌟";
//     } else if (score >= 80) {
//       message = "Great job! You have a strong understanding of the content.";
//       emoji = "🎉";
//     } else if (score >= 70) {
//       message = "Good effort! You're on the right track.";
//       emoji = "👍";
//     } else if (score >= 60) {
//       message = "You passed! With a bit more study, you'll improve even more.";
//       emoji = "🔍";
//     } else {
//       message = "Don't give up! Review the material and try again - you can do it!";
//       emoji = "💪";
//     }
//
//     showDialog(
//       context: context,
//       barrierDismissible: false, // User must tap button to dismiss
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Text("Exam Results $emoji"),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Your Score: ${score.toStringAsFixed(1)}%",
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(message),
//                 const SizedBox(height: 16),
//                 Text(
//                   _isFirstTime
//                       ? "Your answers have been successfully submitted."
//                       : "This is a review of your previous submission.",
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "You answered ${_examModel.answers.length} out of ${_examModel.questions.length} questions.",
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 if (_isFirstTime) Navigator.pop(context); // Return to previous screen after first-time submission
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _selectAnswer(
//     String questionId,
//     String selectedOption,
//     String correctAnswer,
//   ) {
//     if (!_isExamActive) return;
//
//     log(questionId.toString());
//     log(_examModel.answers.toString());
//     setState(() {
//       _examModel.answers[questionId] = {
//         'answer': selectedOption,
//         'isCorrect': selectedOption == correctAnswer,
//       };
//     });
//     log(_examModel.answers.toString());
//   }
//
//   void _navigateToNextQuestion() {
//     if (_currentQuestionIndex < _examModel.questions.length - 1) {
//       setState(() {
//         _currentQuestionIndex++;
//       });
//     } else {
//       // On the last question, offer to submit
//       _showSubmitConfirmationDialog();
//     }
//   }
//
//   void _navigateToPreviousQuestion() {
//     if (_currentQuestionIndex > 0) {
//       setState(() {
//         _currentQuestionIndex--;
//       });
//     }
//   }
//
//   Future<bool> _showSubmitConfirmationDialog() async {
//     if (!_isExamActive) return false;
//
//     final shouldSubmit = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Submit Exam?'),
//             content: Text(
//               'You have answered ${_examModel.answers.length} out of ${_examModel.questions.length} questions. Are you sure you want to submit your exam?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Continue Exam'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text(_isFirstTime ? 'Submit Exam' : 'Done'),
//               ),
//             ],
//           ),
//     );
//
//     if (shouldSubmit == true) {
//       _submitExam();
//     }
//     return shouldSubmit??false;
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Handle app lifecycle changes (when app is minimized or user switches away)
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       if (_isExamActive) {
//         if (kDebugMode) {
//           print('App lifecycle changed to $state, submitting exam');
//         }
//         if (_isFirstTime) _submitExam('App interrupted');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     WakelockPlus.disable();
//     WidgetsBinding.instance.removeObserver(this);
//     if (_isFirstTime) _timer.cancel();
//     _dndService.disableDnd();
//     super.dispose();
//   }
//
//   Future<bool> _showExitConfirmationDialog(BuildContext context) async {
//     if (!_isExamActive) return true;
//     if (!_isFirstTime) return true;
//
//     return await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('Exit Exam?'),
//               content: const Text(
//                 'Leaving this screen will automatically submit your exam and you will not be able to resume. Are you sure you want to exit?',
//               ),
//               actions: <Widget>[
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(false),
//                   // Stay on the exam
//                   child: const Text('Stay'),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     _submitExam('Manual exit'); // Submit the exam
//                     Navigator.of(context).pop(true); // Allow navigation
//                   },
//                   child: const Text('Leave and Submit'),
//                 ),
//               ],
//             );
//           },
//         ) ??
//         false; // If the dialog is dismissed without a choice, return false
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: !_isFirstTime,
//       onPopInvokedWithResult: (didPop, result) async {
//         await _showExitConfirmationDialog(context);
//       },
//       child: Scaffold(
//         appBar: ExamAppBar(duration: _duration),
//         body:
//             _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _examModel.questions.isEmpty
//                 ? const Center(child: Text('No questions available...Chill'))
//                 : _buildQuestionView(),
//       ),
//     );
//   }
//
//   Widget _buildQuestionView() {
//     if (_currentQuestionIndex >= _examModel.questions.length) {
//       return const Center(child: Text('No more questions'));
//     }
//
//     return QuestionView(
//       question: _examModel.questions[_currentQuestionIndex],
//       questionIndex: _currentQuestionIndex,
//       totalQuestions: _examModel.questions.length,
//       answeredQuestionsCount: _examModel.answers.length,
//       isExamActive: _isExamActive,
//       selectedAnswer:
//           _examModel.answers[_currentQuestionIndex.toString()]?['answer']
//               as String?,
//       onAnswerSelected: _selectAnswer,
//       onNextPressed: _navigateToNextQuestion,
//       onPreviousPressed: _navigateToPreviousQuestion,
//       onSubmitPressed: _showSubmitConfirmationDialog,
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../utils/do_not_disturb_service.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import '../widgets/widgets.dart';

class ExamScreen extends StatefulWidget {
  final String examId;
  final String courseId;

  const ExamScreen({super.key, required this.examId, required this.courseId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  late Timer _timer;
  Duration _duration = Duration.zero;
  final ExamService _examService = ExamService();
  final DndService _dndService = DndService();
  final user = FirebaseAuth.instance.currentUser;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  late ExamModel _examModel;
  bool _isExamActive = true;
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isFirstTime = false;
  bool _isAirplaneModeEnabled = false;
  bool _examStarted = false;
  final List<Map<String, dynamic>> _pendingSubmissions = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    _dndService.enableDnd();
    _setupConnectivityListener();
    _loadExam();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool hasConnection = results.any((result) =>
      result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet
      );

      setState(() {
        _isAirplaneModeEnabled = !hasConnection;
      });

      // If connection restored and we have pending submissions
      if (hasConnection && _pendingSubmissions.isNotEmpty) {
        _processPendingSubmissions();
      }

      // Warning if user disables airplane mode during active exam (first-time only)
      if (hasConnection && _examStarted && _isExamActive && _isFirstTime) {
        _showNetworkWarning();
      }
    });
  }

  void _showNetworkWarning() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Network detected! For best exam experience, please enable airplane mode.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _processPendingSubmissions() async {
    if (_pendingSubmissions.isEmpty) return;

    try {
      for (final submission in _pendingSubmissions) {
        await _examService.submitExam(
          submission['isFirstTime'],
          submission['examModel'],
          reason: submission['reason'],
          courseId: widget.courseId,
        );
      }

      _pendingSubmissions.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Exam submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing pending submissions: $e');
      }
    }
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final submissionSnapshot =
      await FirebaseFirestore.instance
          .collection('exam_attempts')
          .where('examId', isEqualTo: widget.examId)
          .where('userId', isEqualTo: user?.uid)
          .get();

      _isFirstTime = submissionSnapshot.docs.isEmpty;

      log(_isFirstTime.toString(), name: 'ISFIRSTTIME');

      final examData = await _examService.loadExam(widget.examId);
      setState(() {
        _examModel = examData;
        _duration = Duration(minutes: _examModel.durationMinutes);
        _isLoading = false;
      });

      // Show airplane mode dialog for first-time exam takers
      if (_isFirstTime) {
        await _showAirplaneModeDialog();
      } else {
        _startExamView();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading exam: $e');
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam: $e'))
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showAirplaneModeDialog() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.airplanemode_active, color: Colors.blue),
              SizedBox(width: 8),
              Text('Exam Setup Required'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before starting your exam, you must:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Expanded(
                      child: Text('Turn ON Airplane Mode in your device settings',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Expanded(
                      child: Text('Return to this app to proceed',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('IMPORTANT:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Questions will not be visible until airplane mode is enabled\n• Once exam starts, you cannot leave this screen\n• Leaving will auto-submit your exam',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your exam will be saved locally and submitted when you reconnect.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel Exam'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (shouldProceed == true) {
      // Wait for user to enable airplane mode
      _waitForAirplaneMode();
    } else {
      Navigator.pop(context);
    }
  }

  void _waitForAirplaneMode() {
    // Show loading screen while waiting for airplane mode
    setState(() {
      _isLoading = true;
    });

    // Check airplane mode status periodically
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isAirplaneModeEnabled) {
        timer.cancel();
        setState(() {
          _isLoading = false;
        });
        _startExamView();
      }
    });
  }

  void _startExamView() {
    setState(() {
      _examStarted = true;
    });

    if (_isFirstTime) {
      _startExam();
    }
  }

  void _startExam() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration -= const Duration(seconds: 1);
        if (_duration.inSeconds <= 0) {
          if (kDebugMode) {
            print('Timer has reached zero, submitting exam');
          }
          _submitExam('Time expired');
        }
      });
    });
  }

  void _submitExam([String reason = 'Manual submission']) async {
    if (!_isExamActive) {
      if (kDebugMode) {
        print("Exam already submitted, ignoring this call");
      }
      return;
    }

    EasyLoading.show(status: 'Submitting your score, please wait...');

    _isExamActive = false;
    if (_isFirstTime) _timer.cancel();

    // Check if we have network connection
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResult.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
    );

    if (!hasConnection && _isFirstTime) {
      // Store submission for later
      _pendingSubmissions.add({
        'isFirstTime': _isFirstTime,
        'examModel': _examModel,
        'reason': reason,
      });

      EasyLoading.dismiss();

      if (mounted) {
        _showOfflineSubmissionDialog();
      }
      return;
    }

    try {
      final result = await _examService.submitExam(
        _isFirstTime,
        _examModel,
        reason: reason,
        courseId: widget.courseId,
      );

      EasyLoading.dismiss();

      if(_isFirstTime) Navigator.pop(context);

      if (context.mounted) {
        _showExamResultDialog(result.score);
      }

      if (_isFirstTime) {
        setState(() {
          _isFirstTime = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting exam: $e');
      }
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting exam: $e. Please try again.')),
      );
      setState(() {
        _isExamActive = true;
      });
    }
  }

  void _showOfflineSubmissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Exam Completed'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your exam has been completed and saved locally.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('To submit your exam:'),
              SizedBox(height: 8),
              Text('1. Turn OFF Airplane Mode'),
              Text('2. Connect to the internet'),
              Text('3. Your exam will be submitted automatically'),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep this app open until submission is complete.',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showExamResultDialog(double score) {
    String message;
    String emoji;

    if (score >= 90) {
      message = "Excellent work! You've mastered this material.";
      emoji = "🌟";
    } else if (score >= 80) {
      message = "Great job! You have a strong understanding of the content.";
      emoji = "🎉";
    } else if (score >= 70) {
      message = "Good effort! You're on the right track.";
      emoji = "👍";
    } else if (score >= 60) {
      message = "You passed! With a bit more study, you'll improve even more.";
      emoji = "🔍";
    } else {
      message = "Don't give up! Review the material and try again - you can do it!";
      emoji = "💪";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text("Exam Results $emoji"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Score: ${score.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 16),
                Text(
                  _isFirstTime
                      ? "Your answers have been successfully submitted."
                      : "This is a review of your previous submission.",
                ),
                const SizedBox(height: 8),
                Text(
                  "You answered ${_examModel.answers.length} out of ${_examModel.questions.length} questions.",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                if (_isFirstTime) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _selectAnswer(
      String questionId,
      String selectedOption,
      String correctAnswer,
      ) {
    if (!_isExamActive) return;

    log(questionId.toString());
    log(_examModel.answers.toString());
    setState(() {
      _examModel.answers[questionId] = {
        'answer': selectedOption,
        'isCorrect': selectedOption == correctAnswer,
      };
    });
    log(_examModel.answers.toString());
  }

  void _navigateToNextQuestion() {
    if (_currentQuestionIndex < _examModel.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showSubmitConfirmationDialog();
    }
  }

  void _navigateToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<bool> _showSubmitConfirmationDialog() async {
    if (!_isExamActive) return false;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          'You have answered ${_examModel.answers.length} out of ${_examModel.questions.length} questions. Are you sure you want to submit your exam?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Exam'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isFirstTime ? 'Submit Exam' : 'Done'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      _submitExam();
    }
    return shouldSubmit ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only auto-submit for first-time exam takers who have started the exam
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isExamActive && _isFirstTime && _examStarted) {
        if (kDebugMode) {
          print('App lifecycle changed to $state, submitting exam');
        }
        _submitExam('App interrupted');
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    if (_isFirstTime && _examStarted) _timer.cancel();
    _dndService.disableDnd();
    super.dispose();
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    // Only show exit confirmation for first-time exam takers who have started the exam
    if (!_isExamActive || !_isFirstTime || !_examStarted) return true;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Exam?'),
          content: const Text(
            'Leaving this screen will automatically submit your exam and you will not be able to resume. Are you sure you want to exit?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                _submitExam('Manual exit');
                Navigator.of(context).pop(true);
              },
              child: const Text('Leave and Submit'),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Widget _buildNetworkStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: _isAirplaneModeEnabled ? Colors.green.shade100 : Colors.orange.shade100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAirplaneModeEnabled ? Icons.airplanemode_active : Icons.signal_wifi_4_bar,
            size: 16,
            color: _isAirplaneModeEnabled ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            _isAirplaneModeEnabled ? 'Airplane Mode Active' : 'Network Connected',
            style: TextStyle(
              fontSize: 12,
              color: _isAirplaneModeEnabled ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isFirstTime && _examStarted), // Only restrict navigation for first-time active exams
      onPopInvokedWithResult: (didPop, result) async {
        if (_isFirstTime && _examStarted && !didPop) {
          await _showExitConfirmationDialog(context);
        }
      },
      child: Scaffold(
        appBar: _examStarted ? ExamAppBar(duration: _duration) : AppBar(title: const Text('Loading Exam')),
        body: Column(
          children: [
            if (_examStarted && _isFirstTime) _buildNetworkStatus(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _examModel.questions.isEmpty
                  ? const Center(child: Text('No questions available...Chill'))
                  : _examStarted
                  ? _buildQuestionView()
                  : _buildAirplaneModeWaitingScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    if (_isFirstTime && !_examStarted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for airplane mode...'),
            SizedBox(height: 8),
            Text(
              'Please enable airplane mode in your device settings',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAirplaneModeWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airplanemode_active,
            size: 64,
            color: _isAirplaneModeEnabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _isAirplaneModeEnabled ? 'Airplane Mode Enabled!' : 'Enable Airplane Mode',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isAirplaneModeEnabled ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAirplaneModeEnabled
                ? 'Starting your exam...'
                : 'Questions will appear once airplane mode is enabled',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_isAirplaneModeEnabled) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    if (_currentQuestionIndex >= _examModel.questions.length) {
      return const Center(child: Text('No more questions'));
    }

    return QuestionView(
      question: _examModel.questions[_currentQuestionIndex],
      questionIndex: _currentQuestionIndex,
      totalQuestions: _examModel.questions.length,
      answeredQuestionsCount: _examModel.answers.length,
      isExamActive: _isExamActive,
      selectedAnswer:
      _examModel.answers[_currentQuestionIndex.toString()]?['answer']
      as String?,
      onAnswerSelected: _selectAnswer,
      onNextPressed: _navigateToNextQuestion,
      onPreviousPressed: _navigateToPreviousQuestion,
      onSubmitPressed: _showSubmitConfirmationDialog,
    );
  }
}
