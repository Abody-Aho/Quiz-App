import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController titleController;
  final Widget prefixIcon;
  final String? Function(String?)? validator;
  final bool isEnglish;
  final TextDirection textDirection;
  final int length;


  const CustomTextField({
    super.key,
    required this.hintText,
    required this.titleController,
    required this.validator,
    required this.prefixIcon,
    required this.isEnglish,
    required this.textDirection, required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleController,
      maxLength: length,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter: (
          context, {
            required int currentLength,
            required bool isFocused,
            int? maxLength,
          }) =>
      null,
      style: const TextStyle(color: Colors.black),
      textDirection: textDirection,
      textAlign: textDirection == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      inputFormatters: isEnglish == true
          ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\u0600-\u06FF\s]'))],
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: isEnglish ? prefixIcon : null,
        suffixIcon: isEnglish ? null : prefixIcon,
        filled: true,
        fillColor: Colors.purple.shade50,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
