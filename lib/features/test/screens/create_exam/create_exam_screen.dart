import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ios_demo/features/test/screens/create_exam/question_tile.dart';
import 'dart:io';

import 'add_question_screen.dart';


class CreateExamScreen extends StatefulWidget {
  final String courseId;

  const CreateExamScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  List<Map<String, dynamic>> _questions = []; // Store questions locally

  // New variables for start time and exam status
  DateTime? _startTime;
  final bool _isExamClosed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Exam')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                // Start Time Picker (Optional)
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Start Time (Optional): '),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDateTimePicker(context);
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                          });
                        }
                      },
                      child: Text(
                        _startTime != null
                            ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} at ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select Date & Time',
                      ),
                    ),
                    if (_startTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startTime = null;
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _uploadFile,
                  child: const Text('Upload Questions from File'),
                ),
                const SizedBox(height: 16),
                const Text('Questions:'),
                ..._questions.map(
                      (question) => QuestionTile(
                    question: question,
                    onEdit: (updatedQuestion) {
                      setState(() {
                        final index = _questions.indexOf(question);
                        _questions[index] = updatedQuestion;
                      });
                    },
                    onDelete: () {
                      setState(() {
                        _questions.remove(question);
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newQuestion =
                    await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddQuestionScreen(),
                      ),
                    );
                    if (newQuestion != null) {
                      setState(() {
                        _questions = [..._questions, newQuestion];
                      });
                    }
                  },
                  child: const Text('Add Question'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveExam(context);
                    }
                  },
                  child: const Text('Save Exam'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to show date and time picker
  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }

    return null;
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'], // Limit to text files for simplicity
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileContent = await file.readAsString();
      _parseQuestionsFromFile(fileContent);
    } else {
      // User canceled the picker
    }
  }

  void _parseQuestionsFromFile(String fileContent) {
    List<Map<String, dynamic>> newQuestions = [];
    List<String> blocks = fileContent.split(RegExp(r'\r?\n\s*\r?\n'));
    log('Found ${blocks.length} blocks');

    for (String block in blocks) {
      List<String> lines = block.split('\n').map((line) => line.trim()).toList();

      if (lines.length >= 3) {
        String? questionText;
        List<String>? options;
        String? correctAnswer;
        Map<String, String> optionMap = {};

        // Extract Question
        questionText = lines
            .firstWhere(
              (line) => line.startsWith('Question:'),
          orElse: () => '',
        )
            .replaceFirst('Question:', '')
            .trim();

        // Extract Options
        final optionsIndex = lines.indexWhere(
              (line) => line.startsWith('Options:'),
        );
        if (optionsIndex != -1) {
          options = lines
              .sublist(optionsIndex + 1)
              .takeWhile((line) => !line.startsWith('Answer:'))
              .where((line) => line.isNotEmpty)
              .toList();

          // Create mapping of options in various formats
          for (int i = 0; i < options.length; i++) {
            String option = options[i];

            // Handle lettered options (A, B, C, D)
            final letterMatch = RegExp(r'^([A-D])[).]').matchAsPrefix(option);
            if (letterMatch != null) {
              optionMap[letterMatch.group(1)!] = option;
              continue;
            }

            // Handle True/False or Yes/No options (no prefixes)
            if (option.trim() == 'True' || option.trim() == 'False' ||
                option.trim() == 'Yes' || option.trim() == 'No') {
              optionMap[option.trim()] = option.trim();
            }
          }
        }

        // Extract Answer
        correctAnswer = lines
            .firstWhere(
              (line) => line.startsWith('Answer:'),
          orElse: () => '',
        )
            .replaceFirst('Answer:', '')
            .trim();

        // Validate and add question
        if (questionText.isNotEmpty &&
            optionMap.isNotEmpty &&
            correctAnswer.isNotEmpty) {
          // For lettered answers, we need to get the full text
          // For True/False or Yes/No, the answer is already the full text
          String fullAnswer = optionMap.containsKey(correctAnswer)
              ? optionMap[correctAnswer]!
              : correctAnswer;

          if (fullAnswer.isNotEmpty) {
            newQuestions.add({
              'text': questionText,
              'options': optionMap.values.toList(),
              'correctAnswer': fullAnswer,
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
            });
          } else {
            log('Error: Could not determine full answer text for: $questionText');
            log('Answer: $correctAnswer');
            log('Available Options: ${optionMap.toString()}');
          }
        } else {
          log('Validation failed for question: $questionText');
          log('Options map: $optionMap');
          log('Correct answer: $correctAnswer');
        }
      } else {
        log('Block has insufficient lines: ${lines.length}');
      }
    }

    log('Successfully parsed ${newQuestions.length} questions');
    setState(() => _questions = [..._questions, ...newQuestions]);
  }

  Future<void> _saveExam(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('exams').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'duration': int.parse(_durationController.text),
          'questions': _questions,
          'courseId': widget.courseId,
          'createdAt': FieldValue.serverTimestamp(),
          // Add new fields
          'startTime': _startTime != null ? Timestamp.fromDate(_startTime!) : null,
          'isClosed': _isExamClosed,
        });
        if(context.mounted) Navigator.of(context).pop(); // Close the screen
      } catch (e) {
        EasyLoading.showToast('Error saving exam: $e');
      }
    }
  }
}