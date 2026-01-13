import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/model.dart';
import 'options_widget.dart';

class ReviewQuestionCard extends StatelessWidget {
  final QueryDocumentSnapshot data;
  const ReviewQuestionCard({super.key, required this.data});
  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }


  @override
  Widget build(BuildContext context) {
    final questionText = data['question'] ?? '';
    final bool arabic = isArabic(questionText);

    final options = List.generate(
      4,
          (i) => Option(
        text: data['options'][i],
        isCorrect: i == data['correctIndex'],
        index: i,
      ),
    );

    final question = Question(
      text: data['question'],
      options: options,
    )
      ..isConfirmed = true
      ..selectedOption =
      options[data['selectedIndex']];

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                question.text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              OptionsWidget(
                question: question,
                onClickedOption: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
