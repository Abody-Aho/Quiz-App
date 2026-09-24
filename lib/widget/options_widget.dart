import 'package:flutter/material.dart';
import '../model/model.dart';

class OptionsWidget extends StatelessWidget {
  final Question question;
  final ValueChanged<Option> onClickedOption;
  final bool isArabic;

  const OptionsWidget({
    super.key,
    required this.question,
    required this.onClickedOption,
    this.isArabic = true,
  });

  static const List<String> arBadges = ['أ', 'ب', 'ج', 'د'];
  static const List<String> enBadges = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return buildOption(context, option, index);
      }).toList(),
    );
  }

  Widget buildOption(BuildContext context, Option option, int index) {
    final isSelected = option == question.selectedOption;
    final isConfirmed = question.isConfirmed;
    final isCorrect = option.isCorrect;

    // Badges
    final badgeText = isArabic
        ? (index < arBadges.length ? arBadges[index] : '${index + 1}')
        : (index < enBadges.length ? enBadges[index] : '${index + 1}');

    // Color definitions
    Color borderColor = Colors.white.withValues(alpha: 0.15);
    Color bgColor = Colors.white.withValues(alpha: 0.08);
    Color textColor = Colors.white;
    Color badgeBgColor = Colors.white.withValues(alpha: 0.15);
    Color badgeTextColor = Colors.white70;
    Widget? statusIcon;

    if (!isConfirmed) {
      if (isSelected) {
        borderColor = const Color(0xFF8B5CF6); // Vibrant Purple
        bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.25);
        badgeBgColor = const Color(0xFF8B5CF6);
        badgeTextColor = Colors.white;
        statusIcon = const Icon(
          Icons.radio_button_checked,
          color: Color(0xFFA78BFA),
          size: 22,
        );
      } else {
        statusIcon = Icon(
          Icons.radio_button_off,
          color: Colors.white.withValues(alpha: 0.3),
          size: 22,
        );
      }
    } else {
      if (isCorrect) {
        borderColor = const Color(0xFF10B981); // Emerald Green
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        badgeBgColor = const Color(0xFF10B981);
        badgeTextColor = Colors.white;
        statusIcon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF34D399),
          size: 24,
        );
      } else if (isSelected && !isCorrect) {
        borderColor = const Color(0xFFEF4444); // Crimson Red
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.25);
        badgeBgColor = const Color(0xFFEF4444);
        badgeTextColor = Colors.white;
        statusIcon = const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFF87171),
          size: 24,
        );
      } else {
        borderColor = Colors.white.withValues(alpha: 0.08);
        bgColor = Colors.white.withValues(alpha: 0.04);
        textColor = Colors.white38;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!question.isConfirmed) {
                onClickedOption(option);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (isConfirmed && (isCorrect || isSelected)) ? 2 : 1.2,
                ),
                boxShadow: isSelected || (isConfirmed && isCorrect)
                    ? [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Option Badge (A/B/C/D or أ/ب/ج/د)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Option Text
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status Icon
                  if (statusIcon != null) statusIcon,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
