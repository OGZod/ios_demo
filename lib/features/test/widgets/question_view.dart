// import 'package:flutter/material.dart';
//
// class QuestionView extends StatelessWidget {
//   final List<Map<String, dynamic>> questions;
//   final int currentIndex;
//   final Function(String questionId, Map<String, dynamic> answer)
//       onAnswerSelected;
//   final VoidCallback onNextQuestion;
//
//   const QuestionView({
//     super.key,
//     required this.questions,
//     required this.currentIndex,
//     required this.onAnswerSelected,
//     required this.onNextQuestion,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final question = questions[currentIndex];
//     final options = question['options'] as List;
//
//     return Column(
//       children: [
//         Text(question['text']),
//         ...options.map((option) => ListTile(
//               title: Text(option),
//               onTap: () => onAnswerSelected(question['id'], {'answer': option}),
//             )),
//         ElevatedButton(onPressed: onNextQuestion, child: const Text('Next')),
//       ],
//     );
//   }
// }
