import 'package:flutter/material.dart';

class AddQuestionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialQuestion;

  const AddQuestionScreen({super.key, this.initialQuestion});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _optionsController = TextEditingController(); // comma-separated options

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      _questionController.text = widget.initialQuestion!['text'] ?? '';
      _answerController.text = widget.initialQuestion!['correctAnswer'] ?? '';
      _optionsController.text =
          (widget.initialQuestion!['options'] as List?)?.join(', ') ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialQuestion == null ? 'Add Question' : 'Edit Question',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the question';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Options (comma-separated)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the options';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the correct answer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final question = {
                        'text': _questionController.text,
                        'options':
                        _optionsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                        'correctAnswer': _answerController.text,
                        'id':
                        DateTime.now().millisecondsSinceEpoch
                            .toString(), // Unique ID
                      };
                      Navigator.of(context).pop(question);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
