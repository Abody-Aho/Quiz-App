import 'package:flutter/material.dart';
import '../model/model.dart';

class OptionsWidget extends StatelessWidget {
  final Question question;
  final ValueChanged<Option> onClickedOption;

  const OptionsWidget({
    super.key,
    required this.question,
    required this.onClickedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...question.options.map((option) => buildOption(context, option)),
      ],
    );
  }

  Widget buildOption(BuildContext context, Option option) {
    final color = getColorForOption(option, question);

    return GestureDetector(
      onTap: () => onClickedOption(option),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            getIconForOption(option, question),
          ],
        ),
      ),
    );
  }
}

Color getColorForOption(Option option, Question question) {
  final isSelected = option == question.selectedOption;

  if (question.isLocked) {
    if (isSelected) {
      return option.isCorrect ? Colors.green : Colors.red;
    } else if (option.isCorrect) {
      return Colors.green;
    }
  }
  return Colors.grey.shade400;
}

Widget getIconForOption(Option option, Question question) {
  final isSelected = option == question.selectedOption;

  if (question.isLocked) {
    if (isSelected) {
      return option.isCorrect
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.red);
    } else if (option.isCorrect) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
  return const SizedBox.shrink();
}
