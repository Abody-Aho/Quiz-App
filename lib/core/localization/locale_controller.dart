import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._internal();
  LocaleController._internal();

  static const String _prefKey = 'selected_app_language';
  static const List<String> supportedLanguageCodes = ['ar', 'en', 'es'];
  static const String defaultLanguageCode = 'en';

  Locale _currentLocale = const Locale(defaultLanguageCode);

  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefKey);

    if (savedLang != null && supportedLanguageCodes.contains(savedLang)) {
      _currentLocale = Locale(savedLang);
    } else {
      // الكشف التلقائي عن لغة النظام
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      final systemLang = systemLocale.languageCode.toLowerCase();

      if (supportedLanguageCodes.contains(systemLang)) {
        _currentLocale = Locale(systemLang);
      } else {
        // افتراضي الإنجليزية إن كانت لغة النظام غير الثلاث
        _currentLocale = const Locale(defaultLanguageCode);
      }
    }
    notifyListeners();
  }

  Future<void> changeLocale(Locale newLocale) async {
    if (!supportedLanguageCodes.contains(newLocale.languageCode)) return;
    if (_currentLocale.languageCode == newLocale.languageCode) return;

    _currentLocale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }
}
