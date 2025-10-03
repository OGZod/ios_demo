// widgets/exam_app_bar.dart
import 'dart:developer';

import 'package:flutter/material.dart';

import '../models/exam_model.dart';

class ExamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Duration duration;

  const ExamAppBar({
    super.key,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Exam in Progress'),
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'Time: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class QuestionView extends StatefulWidget {
  final QuestionModel question;
  final int questionIndex;
  final int totalQuestions;
  final int answeredQuestionsCount;
  final bool isExamActive;
  final String? selectedAnswer;
  final Function(String, String, String) onAnswerSelected;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;
  final Future<bool> Function() onSubmitPressed;

  const QuestionView({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.answeredQuestionsCount,
    required this.isExamActive,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.onSubmitPressed,
  });

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

bool showCorrectAnswer = false;

class _QuestionViewState extends State<QuestionView> {
  @override
  void initState() {
    showCorrectAnswer = false;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${widget.questionIndex + 1} of ${widget.totalQuestions}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            widget.question.text,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: widget.question.options.length,
              itemBuilder: (context, index) {
                final option = widget.question.options[index];
                final isSelected = option == widget.selectedAnswer;
                final isCorrect = option == widget.question.correctAnswer;

                return Card(
                  elevation: isSelected ? 2 : 0,
                  color: _getOptionColor(isSelected, isCorrect),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: RadioListTile<String>(
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: showCorrectAnswer && isCorrect ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: option,
                    groupValue: widget.selectedAnswer,
                    onChanged: widget.isExamActive
                        ? (value) {
                      if (value != null) {
                        widget.onAnswerSelected(widget.question.id, value, widget.question.correctAnswer);
                      }
                    }
                        : null,
                    selected: isSelected,
                    secondary: showCorrectAnswer && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (showCorrectAnswer && isSelected && !isCorrect
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : null),
                  ),
                );
              },
            ),
          ),
          if (showCorrectAnswer && widget.selectedAnswer != widget.question.correctAnswer)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Correct answer: ${widget.question.correctAnswer}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Color _getOptionColor(bool isSelected, bool isCorrect) {
    if (!showCorrectAnswer) {
      return isSelected ? Colors.blue.withOpacity(0.1) : Colors.white;
    }

    if (isCorrect) {
      return Colors.green.withOpacity(0.2);
    }

    if (isSelected && !isCorrect) {
      return Colors.red.withOpacity(0.2);
    }

    return Colors.white;
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        widget.questionIndex > 0
            ? ElevatedButton(
          onPressed: widget.onPreviousPressed,
          child: const Text('Previous'),
        )
            : const SizedBox(width: 80), // Empty space to maintain layout

        Text('${widget.answeredQuestionsCount}/${widget.totalQuestions} answered'),

        widget.questionIndex < widget.totalQuestions - 1
            ? ElevatedButton(
          onPressed: widget.onNextPressed,
          child: const Text('Next'),
        )
            : ElevatedButton(
          onPressed: widget.isExamActive ? () async {
            final res = await widget.onSubmitPressed();
            if(res) {
              setState(() {
              showCorrectAnswer = true;
            });
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}