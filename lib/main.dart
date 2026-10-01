import 'package:exam/core/localization/app_localizations.dart';
import 'package:exam/core/localization/locale_controller.dart';
import 'package:exam/view/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// ================= App Entry Point =================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اللغة وتحديد لغة النظام أو المحفوظة بحذر
  try {
    await LocaleController.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('LocaleController init error: $e');
    }
  }

  // تهيئة الفايربيز
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init error: $e');
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

// ================= Root Widget =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ================= App Configuration =================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final localeController = LocaleController.instance;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeController.currentLocale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return localeController.currentLocale;
          },
          home: const SplashPage(),
        );
      },
    );
  }
}
