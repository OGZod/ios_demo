import 'package:flutter/material.dart';

import 'add_question_screen.dart';

class QuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onDelete;

  const QuestionTile({
    super.key,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question: ${question['text']}'),
                  Text('Answer: ${question['correctAnswer']}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedQuestion =
                await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                        AddQuestionScreen(initialQuestion: question),
                  ),
                );
                if (updatedQuestion != null) {
                  onEdit(updatedQuestion);
                }
              },
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
