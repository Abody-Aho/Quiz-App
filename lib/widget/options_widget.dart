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

  Color getColorForOption(Option option, Question question) {
    final isSelected = option == question.selectedOption;

    // قبل التأكيد
    if (!question.isConfirmed) {
      return isSelected ? Colors.purple : Colors.grey.shade400;
    }

    // بعد التأكيد
    if (option.isCorrect) return Colors.green;
    if (isSelected && !option.isCorrect) return Colors.red;

    return Colors.grey.shade400;
  }

  Color getBackgroundColor(Option option, Question question) {
    final isSelected = option == question.selectedOption;

    // قبل التأكيد
    if (!question.isConfirmed) {
      return isSelected
          ? Colors.purple.withValues(alpha: 0.15)
          : Colors.grey.shade200;
    }

    // بعد التأكيد
    if (option.isCorrect) {
      return Colors.green.withValues(alpha: 0.15);
    }

    if (isSelected && !option.isCorrect) {
      return Colors.red.withValues(alpha: 0.15);
    }

    return Colors.grey.shade200;
  }

  Widget getIconForOption(Option option, Question question) {
    final isSelected = option == question.selectedOption;

    // قبل التأكيد
    if (!question.isConfirmed) {
      return isSelected
          ? const Icon(Icons.radio_button_checked, color: Colors.purple)
          : const Icon(Icons.radio_button_off, color: Colors.grey);
    }

    // بعد التأكيد
    if (option.isCorrect) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (isSelected && !option.isCorrect) {
      return const Icon(Icons.cancel, color: Colors.red);
    }

    return const SizedBox.shrink();
  }



  Widget buildOption(BuildContext context, Option option) {
    final color = getColorForOption(option, question);

    return GestureDetector(
      onTap: () {
        if (!question.isConfirmed) {
          onClickedOption(option);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: getBackgroundColor(option, question),
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
