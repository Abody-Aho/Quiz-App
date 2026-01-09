import 'package:flutter/material.dart';

class Question {
  final String text;
  final List<Option> options;
  Option? selectedOption;
  bool isConfirmed;

  Question({
    required this.text,
    required this.options,
    this.selectedOption,
    this.isConfirmed = false,
  });
}

class Option {
  final String text;
  final bool isCorrect;

  Option({required this.text, required this.isCorrect});
}

class Category {
  final String id;
  final String title;
  final String prompt;
   late String level;
  final String image;
  final TextDirection direction;

  Category({
    required this.id,
    required this.title,
    required this.prompt,
    required this.image,
    required this.direction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'image': image,
      'direction': direction == TextDirection.rtl ? 'rtl' : 'ltr',
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      title: map['title'],
      prompt: map['prompt'],
      image: map['image'],
      direction: map['direction'] == 'rtl'
          ? TextDirection.rtl
          : TextDirection.ltr,
    );
  }
}

class OnboardItem {
  final IconData icon;
  final String title;
  final String description;

  OnboardItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
