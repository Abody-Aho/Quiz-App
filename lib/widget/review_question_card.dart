import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/model.dart';
import 'options_widget.dart';

class ReviewQuestionCard extends StatelessWidget {
  final QueryDocumentSnapshot data;
  const ReviewQuestionCard({super.key, required this.data});

  bool isArabicText(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> docData = data.data() as Map<String, dynamic>;
    final questionText = docData['question'] ?? '';
    final bool arabic = isArabicText(questionText);

    final List optionsData = docData['options'] ?? [];
    final int correctIndex = docData['correctIndex'] ?? 0;
    final int selectedIndex = docData['selectedIndex'] ?? 0;

    final options = List.generate(
      optionsData.length > 4 ? 4 : optionsData.length,
      (i) => Option(
        text: optionsData[i].toString(),
        isCorrect: i == correctIndex,
        index: i,
      ),
    );

    final question = Question(
      text: questionText,
      options: options,
    )
      ..isConfirmed = true
      ..selectedOption =
          (selectedIndex >= 0 && selectedIndex < options.length)
              ? options[selectedIndex]
              : null;

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E163B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OptionsWidget(
              question: question,
              isArabic: arabic,
              onClickedOption: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
