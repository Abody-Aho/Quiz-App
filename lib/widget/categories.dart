import 'dart:ui';
import '../model/model.dart';

final List<Category> categories = [

  // ===================== Flutter =====================
  Category(
    id: 'flutter_en',
    language: 'en',
    title: 'Flutter',
    prompt:
    'Flutter framework, widgets, layouts, state management, navigation, forms, animations',
    image: 'asset/images/flutter.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'flutter_ar',
    language: 'ar',
    title: 'فلاتر',
    prompt:
    'إطار عمل فلاتر، الودجتس، التخطيطات، إدارة الحالة، التنقل بين الصفحات، النماذج، الحركات',
    image: 'asset/images/flutter.png',
    direction: TextDirection.rtl,
  ),

  // ===================== Dart =====================
  Category(
    id: 'dart_en',
    language: 'en',
    title: 'Dart',
    prompt:
    'Dart language, variables, data types, functions, OOP, async, await, futures, streams',
    image: 'asset/images/dart.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'dart_ar',
    language: 'ar',
    title: 'دارت',
    prompt:
    'لغة دارت، المتغيرات، أنواع البيانات، الدوال، البرمجة كائنية التوجه، async و await، Futures و Streams',
    image: 'asset/images/dart.png',
    direction: TextDirection.rtl,
  ),

  // ===================== Python =====================
  Category(
    id: 'python_en',
    language: 'en',
    title: 'Python',
    prompt:
    'Python programming language, basics, data structures, functions, OOP, exceptions, modules',
    image: 'asset/images/python.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'python_ar',
    language: 'ar',
    title: 'بايثون',
    prompt:
    'لغة بايثون، الأساسيات، هياكل البيانات، الدوال، البرمجة كائنية التوجه، الاستثناءات، الوحدات',
    image: 'asset/images/python.png',
    direction: TextDirection.rtl,
  ),

  // ===================== JavaScript =====================
  Category(
    id: 'javascript_en',
    language: 'en',
    title: 'JavaScript',
    prompt:
    'JavaScript basics, ES6, variables, functions, async programming, promises, arrays, objects',
    image: 'asset/images/javascript.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'javascript_ar',
    language: 'ar',
    title: 'جافاسكربت',
    prompt:
    'لغة جافاسكربت، الأساسيات، ES6، المتغيرات، الدوال، البرمجة غير المتزامنة، Promises، المصفوفات، الكائنات',
    image: 'asset/images/javascript.png',
    direction: TextDirection.rtl,
  ),

  // ===================== APIs =====================
  Category(
    id: 'api_en',
    language: 'en',
    title: 'APIs',
    prompt:
    'REST APIs, HTTP methods, status codes, JSON, authentication, tokens',
    image: 'asset/images/api.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'api_ar',
    language: 'ar',
    title: 'واجهات برمجة التطبيقات',
    prompt:
    'واجهات برمجة التطبيقات REST، طرق HTTP، أكواد الحالة، JSON، المصادقة، التوكنات',
    image: 'asset/images/api.png',
    direction: TextDirection.rtl,
  ),

  // ===================== Databases =====================
  Category(
    id: 'database_en',
    language: 'en',
    title: 'Databases',
    prompt:
    'Databases, SQL basics, tables, relations, queries, indexes',
    image: 'asset/images/database.png',
    direction: TextDirection.ltr,
  ),
  Category(
    id: 'database_ar',
    language: 'ar',
    title: 'قواعد البيانات',
    prompt:
    'قواعد البيانات، أساسيات SQL، الجداول، العلاقات، الاستعلامات، الفهارس',
    image: 'asset/images/database.png',
    direction: TextDirection.rtl,
  ),
];
