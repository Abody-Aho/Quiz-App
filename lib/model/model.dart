import 'package:flutter/material.dart';

// ================= Question Model =================
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

  // ================= JSON =================
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'],
      options: (json['options'] as List)
          .map((o) => Option.fromJson(o))
          .toList(),
      selectedOption: null,
      isConfirmed: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

// ================= Option Model =================
class Option {
  final String text;
  final bool isCorrect;
  final int index;

  Option({
    required this.text,
    required this.isCorrect,
    required this.index,
  });

  // ================= JSON =================
  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      text: json['text'],
      isCorrect: json['isCorrect'],
      index: json['index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      'index': index,
    };
  }
}

// ================= Category Model =================
class Category {
  final String id;
  final String language;
  final String title;
  final String prompt;
  final String image;
  final TextDirection direction;

  Category({
    required this.id,
    required this.language,
    required this.title,
    required this.prompt,
    required this.image,
    required this.direction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'title': title,
      'prompt': prompt,
      'image': image,
      'direction': direction == TextDirection.rtl ? 'rtl' : 'ltr',
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      language: map['language'],
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
