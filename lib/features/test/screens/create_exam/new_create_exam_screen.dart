// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:path/path.dart' as path;
//
//
// class NewCreateExamScreen extends StatefulWidget {
//   final String courseId;
//
//   const NewCreateExamScreen({
//     super.key,
//     required this.courseId,
//   });
//
//   @override
//   State<NewCreateExamScreen> createState() => _NewCreateExamScreenState();
// }
//
// class _NewCreateExamScreenState extends State<NewCreateExamScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _durationController = TextEditingController();
//
//   // Document file
//   File? _questionFile;
//   String? _questionFileUrl;
//   String? _questionFileName;
//
//   // Answer list instead of file
//   List<String> _answersList = [];
//   final bool _isExtractingAnswers = false;
//
//   // New variables for start time and exam status
//   DateTime? _startTime;
//   final bool _isExamClosed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Create New Exam')),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(labelText: 'Title'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a title';
//                     }
//                     return null;
//                   },
//                 ),
//                 TextFormField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(labelText: 'Description'),
//                 ),
//                 TextFormField(
//                   controller: _durationController,
//                   decoration: const InputDecoration(
//                     labelText: 'Duration (minutes)',
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a duration';
//                     }
//                     if (int.tryParse(value) == null) {
//                       return 'Please enter a valid number';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 // Start Time Picker (Optional)
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     const Text('Start Time (Optional): '),
//                     const SizedBox(width: 8),
//                     TextButton(
//                       onPressed: () async {
//                         final DateTime? picked = await showDateTimePicker(
//                             context);
//                         if (picked != null) {
//                           setState(() {
//                             _startTime = picked;
//                           });
//                         }
//                       },
//                       child: Text(
//                         _startTime != null
//                             ? '${_startTime!.day}/${_startTime!
//                             .month}/${_startTime!.year} at ${_startTime!
//                             .hour}:${_startTime!.minute.toString().padLeft(
//                             2, '0')}'
//                             : 'Select Date & Time',
//                       ),
//                     ),
//                     if (_startTime != null)
//                       IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           setState(() {
//                             _startTime = null;
//                           });
//                         },
//                       ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 16),
//                 const Divider(),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Exam Materials',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Question document upload
//                 Row(
//                   children: [
//                     ElevatedButton(
//                       onPressed: _pickQuestionFile,
//                       child: const Text('Upload Question Document'),
//                     ),
//                     const SizedBox(width: 8),
//                     if (_questionFileName != null)
//                       Expanded(
//                         child: Text(
//                           _questionFileName!,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Answer extraction section
//                 const Text('Answer Key:',
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//
//                 if (_isExtractingAnswers)
//                   const Center(child: CircularProgressIndicator())
//                 else
//                   ...[
//                     if (_answersList.isEmpty)
//                       ElevatedButton(
//                         onPressed: _pickAnswerFile,
//                         child: const Text('Extract Answers'),
//                       )
//                     else
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('${_answersList.length} Answers Extracted'),
//                           const SizedBox(height: 8),
//                           SizedBox(
//                             height: 200,
//                             child: ListView.builder(
//                               itemCount: _answersList.length,
//                               itemBuilder: (context, index) {
//                                 return ListTile(
//                                   dense: true,
//                                   title: Text(
//                                       '${index + 1}. ${_answersList[index]}'),
//                                   trailing: IconButton(
//                                     icon: const Icon(Icons.edit, size: 16),
//                                     onPressed: () => _editAnswer(index),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               ElevatedButton(
//                                 onPressed: _pickAnswerFile,
//                                 child: const Text('Re-Extract Answers'),
//                               ),
//                               const SizedBox(width: 8),
//                               TextButton(
//                                 onPressed: () =>
//                                     setState(() => _answersList = []),
//                                 child: const Text('Clear Answers'),
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                   ],
//
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       _saveExam(context);
//                     }
//                   },
//                   child: const Text('Save Exam'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Helper method to show date and time picker
//   Future<DateTime?> showDateTimePicker(BuildContext context) async {
//     final DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//
//     if (date != null) {
//       final TimeOfDay? time = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.now(),
//       );
//
//       if (time != null) {
//         return DateTime(
//           date.year,
//           date.month,
//           date.day,
//           time.hour,
//           time.minute,
//         );
//       }
//     }
//
//     return null;
//   }
//
//   // Pick question document (PDF or Word)
//   Future<void> _pickQuestionFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'docx', 'doc'],
//       );
//
//       if (result != null) {
//         setState(() {
//           _questionFile = File(result.files.single.path!);
//           _questionFileName = result.files.single.name;
//           // Clear answers when new question file is selected
//           _answersList = [];
//         });
//
//         // Show toast confirmation
//         EasyLoading.showToast('Question document selected');
//       }
//     } catch (e) {
//       EasyLoading.showError('Error selecting file: $e');
//     }
//   }
//
//   Future<void> _pickAnswerFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'docx', 'txt'],
//       );
//
//       if (result != null) {
//         setState(() async {
//           final answerFile  = File(result.files.single.path!);
//           String content = await answerFile.readAsString();
//           log(content);
//           _showAnswerExtractionDialog(content);
//           // Clear answers when new question file is selected
//           _answersList = [];
//         });
//
//         // Show toast confirmation
//         // EasyLoading.showToast('Question document selected');
//       }
//     } catch (e) {
//       EasyLoading.showError('Error selecting file: $e');
//     }
//   }
//
//   // Show dialog to extract answers
//   Future<void> _showAnswerExtractionDialog(String answer) async {
//     if (_questionFile == null) {
//       EasyLoading.showError('Please upload a question document first');
//       return;
//     }
//
//     final TextEditingController answersController = TextEditingController();
//     answersController.text = answer;
//
//     final result = await showDialog<List<String>>(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: const Text('Extract Answers'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Enter answer key (one answer per line):',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: answersController,
//                   maxLines: 10,
//                   decoration: const InputDecoration(
//                     hintText: 'Example:\nA\nTrue\nC\nB\n...',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   final text = answersController.text.trim();
//                   if (text.isEmpty) {
//                     Navigator.pop(context);
//                     return;
//                   }
//
//                   final answers = text.split('\n')
//                       .map((e) => e.trim())
//                       .where((e) => e.isNotEmpty)
//                       .toList();
//
//                   Navigator.pop(context, answers);
//                 },
//                 child: const Text('Save Answers'),
//               ),
//             ],
//           ),
//     );
//
//     if (result != null && result.isNotEmpty) {
//       setState(() {
//         _answersList = result;
//       });
//       EasyLoading.showSuccess('${result.length} answers extracted');
//     }
//   }
//
//   // Edit specific answer
//   Future<void> _editAnswer(int index) async {
//     final TextEditingController controller = TextEditingController(
//         text: _answersList[index]);
//
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text('Edit Answer ${index + 1}'),
//             content: TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   final text = controller.text.trim();
//                   Navigator.pop(
//                       context, text.isNotEmpty ? text : _answersList[index]);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           ),
//     );
//
//     if (result != null) {
//       setState(() {
//         _answersList[index] = result;
//       });
//     }
//   }
//
//   // Upload file to Firebase Storage
//   // Future<String?> _uploadFileToStorage(File file, String folder) async {
//   //   try {
//   //     EasyLoading.show(status: 'Uploading file...',dismissOnTap: true);
//   //
//   //     final fileName = path.basename(file.path);
//   //     final destination = 'exams/${widget.courseId}/$folder/$fileName';
//   //
//   //     final ref = FirebaseStorage.instance.ref(destination);
//   //     log('1');
//   //     await ref.putFile(file);
//   //     log('11');
//   //     // Get download URL
//   //     final downloadUrl = await ref.getDownloadURL();
//   //
//   //     EasyLoading.dismiss();
//   //     return downloadUrl;
//   //   } catch (e) {
//   //     EasyLoading.dismiss();
//   //     EasyLoading.showError('Error uploading file: $e');
//   //     log(e.toString());
//   //     return null;
//   //   }
//   // }
//   Future<String?> _uploadFileToStorage(File file, String folder) async {
//     try {
//       EasyLoading.show(status: 'Uploading file...', dismissOnTap: true);
//
//       final fileName = path.basename(file.path);
//       final destination = 'exams/${widget.courseId}/$folder/$fileName';
//
//       final ref = FirebaseStorage.instance.ref(destination);
//       log('Starting upload...');
//
//       // Optional: Add metadata
//       final metadata = SettableMetadata(contentType: 'application/octet-stream');
//
//       // Upload file
//       await ref.putFile(file, metadata).then((taskSnapshot) {
//         log('Upload completed');
//       }).catchError((error) {
//         log('Upload failed: $error');
//         throw error;
//       });
//
//       // Get download URL
//       final downloadUrl = await ref.getDownloadURL();
//       log('Download URL retrieved: $downloadUrl');
//
//       EasyLoading.dismiss();
//       return downloadUrl;
//     } catch (e) {
//       EasyLoading.dismiss();
//       EasyLoading.showError('Error uploading file: $e');
//       log('Error: ${e.toString()}');
//       return null;
//     }
//   }
//
//
//   Future<void> _saveExam(BuildContext context) async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         EasyLoading.show(status: 'Saving exam...');
//
//         // Validate required files and answers
//         if (_questionFile == null) {
//           EasyLoading.dismiss();
//           EasyLoading.showError('Please upload a question document');
//           return;
//         }
//
//         if (_answersList.isEmpty) {
//           EasyLoading.dismiss();
//           EasyLoading.showError('Please extract answers for the exam');
//           return;
//         }
//
//         // Upload question document
//         _questionFileUrl =
//         await _uploadFileToStorage(_questionFile!, 'questions');
//         if (_questionFileUrl == null) {
//           EasyLoading.dismiss();
//           return; // Error message already shown
//         }
//
//         // Create exam document data
//         Map<String, dynamic> examData = {
//           'title': _titleController.text,
//           'description': _descriptionController.text,
//           'duration': int.parse(_durationController.text),
//           'courseId': widget.courseId,
//           'createdAt': FieldValue.serverTimestamp(),
//           'startTime': _startTime != null
//               ? Timestamp.fromDate(_startTime!)
//               : null,
//           'isClosed': _isExamClosed,
//           'questionFileUrl': _questionFileUrl,
//           'questionFileName': _questionFileName,
//           'answers': _answersList, // Storing answers as list of strings
//           'totalQuestions': _answersList.length,
//         };
//
//         // Save to Firestore
//         await FirebaseFirestore.instance.collection('exams').add(examData);
//
//         EasyLoading.dismiss();
//         if (context.mounted) {
//           EasyLoading.showSuccess('Exam created successfully');
//           Navigator.of(context).pop(); // Close the screen
//         }
//       } catch (e) {
//         EasyLoading.dismiss();
//         EasyLoading.showError('Error saving exam: $e');
//       }
//     }
//   }
// }
//
// // This would be a separate screen for students taking the exam
// class TakeExamScreen extends StatefulWidget {
//   final String examId;
//   final String studentId;
//
//   const TakeExamScreen({
//     super.key,
//     required this.examId,
//     required this.studentId,
//   });
//
//   @override
//   State<TakeExamScreen> createState() => _TakeExamScreenState();
// }
//
// class _TakeExamScreenState extends State<TakeExamScreen> {
//   bool _isLoading = true;
//   Map<String, dynamic>? _examData;
//   List<String> _studentAnswers = [];
//   String? _questionFileUrl;
//   int _totalQuestions = 0;
//   int _timeRemaining = 0;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadExam();
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadExam() async {
//     try {
//       final examDoc = await FirebaseFirestore.instance
//           .collection('exams')
//           .doc(widget.examId)
//           .get();
//
//       if (!examDoc.exists) {
//         if (mounted) {
//           EasyLoading.showError('Exam not found');
//           Navigator.pop(context);
//         }
//         return;
//       }
//
//       final data = examDoc.data()!;
//
//       // Check if exam is accessible
//       final startTime = data['startTime'] as Timestamp?;
//       final isClosed = data['isClosed'] as bool? ?? false;
//
//       if (isClosed) {
//         if (mounted) {
//           EasyLoading.showError('This exam is closed');
//           Navigator.pop(context);
//         }
//         return;
//       }
//
//       if (startTime != null && startTime.toDate().isAfter(DateTime.now())) {
//         if (mounted) {
//           EasyLoading.showError('This exam has not started yet');
//           Navigator.pop(context);
//         }
//         return;
//       }
//
//       // Initialize student answers array based on total questions
//       final totalQuestions = data['totalQuestions'] as int? ?? 0;
//       final answers = List<String>.filled(totalQuestions, '');
//
//       // Check if student has already started this exam
//       final submissionDoc = await FirebaseFirestore.instance
//           .collection('exam_submissions')
//           .where('examId', isEqualTo: widget.examId)
//           .where('studentId', isEqualTo: widget.studentId)
//           .limit(1)
//           .get();
//
//       if (submissionDoc.docs.isNotEmpty) {
//         final submission = submissionDoc.docs.first.data();
//         final savedAnswers = submission['answers'] as List<dynamic>?;
//
//         if (savedAnswers != null) {
//           for (int i = 0; i < savedAnswers.length && i < totalQuestions; i++) {
//             answers[i] = savedAnswers[i] as String? ?? '';
//           }
//         }
//       }
//
//       // Start timer
//       final duration = data['duration'] as int? ?? 60;
//       _timeRemaining = duration * 60; // Convert to seconds
//       _startTimer();
//
//       setState(() {
//         _examData = data;
//         _studentAnswers = answers;
//         _questionFileUrl = data['questionFileUrl'] as String?;
//         _totalQuestions = totalQuestions;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (mounted) {
//         EasyLoading.showError('Error loading exam: $e');
//         Navigator.pop(context);
//       }
//     }
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_timeRemaining <= 0) {
//         timer.cancel();
//         _submitExam(isTimeUp: true);
//         return;
//       }
//
//       setState(() {
//         _timeRemaining--;
//       });
//     });
//   }
//
//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
//   }
//
//   Future<void> _updateAnswer(int index, String answer) async {
//     if (index >= 0 && index < _studentAnswers.length) {
//       setState(() {
//         _studentAnswers[index] = answer;
//       });
//
//       // Autosave answers to Firestore
//       try {
//         await FirebaseFirestore.instance
//             .collection('exam_submissions')
//             .where('examId', isEqualTo: widget.examId)
//             .where('studentId', isEqualTo: widget.studentId)
//             .limit(1)
//             .get()
//             .then((snapshot) async {
//           if (snapshot.docs.isNotEmpty) {
//             // Update existing submission
//             await snapshot.docs.first.reference.update({
//               'answers': _studentAnswers,
//               'lastUpdated': FieldValue.serverTimestamp(),
//             });
//           } else {
//             // Create new submission
//             await FirebaseFirestore.instance.collection('exam_submissions').add(
//                 {
//                   'examId': widget.examId,
//                   'studentId': widget.studentId,
//                   'answers': _studentAnswers,
//                   'startedAt': FieldValue.serverTimestamp(),
//                   'lastUpdated': FieldValue.serverTimestamp(),
//                   'isCompleted': false,
//                 });
//           }
//         });
//       } catch (e) {
//         // Silent error - we'll try again next time
//         if (kDebugMode) {
//           print('Error autosaving: $e');
//         }
//       }
//     }
//   }
//
//   Future<void> _submitExam({bool isTimeUp = false}) async {
//     try {
//       EasyLoading.show(status: 'Submitting exam...');
//
//       // Get correct answers
//       final correctAnswers = _examData?['answers'] as List<dynamic>? ?? [];
//
//       // Calculate score
//       int correctCount = 0;
//       for (int i = 0; i < _studentAnswers.length &&
//           i < correctAnswers.length; i++) {
//         if (_studentAnswers[i].trim().toUpperCase() ==
//             (correctAnswers[i] as String).trim().toUpperCase()) {
//           correctCount++;
//         }
//       }
//
//       final score = _totalQuestions > 0
//           ? (correctCount / _totalQuestions * 100).round()
//           : 0;
//
//       // Save submission
//       await FirebaseFirestore.instance
//           .collection('exam_submissions')
//           .where('examId', isEqualTo: widget.examId)
//           .where('studentId', isEqualTo: widget.studentId)
//           .limit(1)
//           .get()
//           .then((snapshot) async {
//         if (snapshot.docs.isNotEmpty) {
//           // Update existing submission
//           await snapshot.docs.first.reference.update({
//             'answers': _studentAnswers,
//             'completedAt': FieldValue.serverTimestamp(),
//             'score': score,
//             'correctCount': correctCount,
//             'isCompleted': true,
//             'isTimeUp': isTimeUp,
//           });
//         } else {
//           // Create new completed submission
//           await FirebaseFirestore.instance.collection('exam_submissions').add({
//             'examId': widget.examId,
//             'studentId': widget.studentId,
//             'answers': _studentAnswers,
//             'startedAt': FieldValue.serverTimestamp(),
//             'completedAt': FieldValue.serverTimestamp(),
//             'score': score,
//             'correctCount': correctCount,
//             'isCompleted': true,
//             'isTimeUp': isTimeUp,
//           });
//         }
//       });
//
//       EasyLoading.dismiss();
//
//       if (mounted) {
//         if (isTimeUp) {
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) =>
//                 AlertDialog(
//                   title: const Text('Time\'s Up!'),
//                   content: Text(
//                       'Your exam has been submitted automatically.\n\nYour score: $score%'),
//                   actions: [
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pop(context); // Return to previous screen
//                       },
//                       child: const Text('OK'),
//                     ),
//                   ],
//                 ),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) =>
//                   ExamResultScreen(
//                     examId: widget.examId,
//                     studentId: widget.studentId,
//                     score: score,
//                     correctCount: correctCount,
//                     totalQuestions: _totalQuestions,
//                   ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       EasyLoading.dismiss();
//       EasyLoading.showError('Error submitting exam: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Loading Exam...')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_examData?['title'] ?? 'Take Exam'),
//         actions: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text(
//                 'Time: ${_formatTime(_timeRemaining)}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Question document viewer (PDF View)
//           Expanded(
//             flex: 3,
//             child: _questionFileUrl != null
//                 ? PDFView(
//               filePath: _questionFileUrl!,
//               autoSpacing: true,
//               pageSnap: true,
//               swipeHorizontal: true,
//               onError: (error) {
//                 if (kDebugMode) {
//                   print('Error loading PDF: $error');
//                 }
//               },
//             )
//                 : const Center(
//               child: Text('No question document available'),
//             ),
//           ),
//
//           // Answer sheet
//           Expanded(
//             flex: 2,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[400]!),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8.0),
//                     color: Colors.blue[700],
//                     width: double.infinity,
//                     child: const Text(
//                       'ANSWER SHEET',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Expanded(
//                     child: GridView.builder(
//                       padding: const EdgeInsets.all(16),
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 5,
//                         childAspectRatio: 3,
//                         crossAxisSpacing: 8,
//                         mainAxisSpacing: 8,
//                       ),
//                       itemCount: _totalQuestions,
//                       itemBuilder: (context, index) {
//                         return GestureDetector(
//                           onTap: () => _showAnswerInputDialog(index),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(4),
//                               border: Border.all(
//                                 color: _studentAnswers[index].isNotEmpty
//                                     ? Colors.blue
//                                     : Colors.grey[400]!,
//                                 width: _studentAnswers[index].isNotEmpty
//                                     ? 2
//                                     : 1,
//                               ),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 '${index + 1}. ${_studentAnswers[index]}',
//                                 style: TextStyle(
//                                   fontWeight: _studentAnswers[index].isNotEmpty
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Submit button
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             child: ElevatedButton(
//               onPressed: () => _showSubmitConfirmation(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//               child: const Text(
//                 'SUBMIT EXAM',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _showAnswerInputDialog(int questionIndex) async {
//     final TextEditingController controller = TextEditingController(
//       text: _studentAnswers[questionIndex],
//     );
//
//     await showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text('Question ${questionIndex + 1}'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Enter your answer:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: controller,
//                   decoration: const InputDecoration(
//                     hintText: 'A, B, C, D, True, False, etc.',
//                     border: OutlineInputBorder(),
//                   ),
//                   textCapitalization: TextCapitalization.characters,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 18),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   _updateAnswer(questionIndex, controller.text.trim());
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   Future<void> _showSubmitConfirmation() async {
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: const Text('Submit Exam?'),
//             content: Text(
//               'You have answered ${_studentAnswers
//                   .where((a) => a.isNotEmpty)
//                   .length} out of $_totalQuestions questions.\n\n'
//                   'Are you sure you want to submit your exam?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                 ),
//                 child: const Text('Submit'),
//               ),
//             ],
//           ),
//     );
//
//     if (result == true) {
//       await _submitExam();
//     }
//   }
// }
//
// // Result screen shown after completion
// class ExamResultScreen extends StatelessWidget {
//   final String examId;
//   final String studentId;
//   final int score;
//   final int correctCount;
//   final int totalQuestions;
//
//   const ExamResultScreen({
//     super.key,
//     required this.examId,
//     required this.studentId,
//     required this.score,
//     required this.correctCount,
//     required this.totalQuestions,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Exam Results'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.assignment_turned_in,
//               size: 100,
//               color: Colors.green,
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Exam Completed!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 32),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   ResultRow(label: 'Score', value: '$score%'),
//                   const Divider(),
//                   ResultRow(
//                     label: 'Correct Answers',
//                     value: '$correctCount out of $totalQuestions',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 12,
//                 ),
//               ),
//               child: const Text(
//                 'Return to Course',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ResultRow extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const ResultRow({
//     super.key,
//     required this.label,
//     required this.value,});
//
//   @override
//   Widget build(BuildContext context) {
//     return Text('$label: $value');
//   }
// }