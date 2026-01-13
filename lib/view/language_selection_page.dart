import 'package:exam/view/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/class/route_transitions.dart';
import 'category_page.dart';

// ================= Language Selection Page =================
class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {

  // ================= User Data =================
  final user = FirebaseAuth.instance.currentUser;
  late String imageUrl = user?.photoURL ?? "";

  // ================= Keys & State =================
  final GlobalKey _english = GlobalKey<FormState>();
  final GlobalKey _arabic = GlobalKey<FormState>();
  DateTime? _lastBackPressed;

  // ================= Tutorial Check =================
  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isTutorialShown =
        prefs.getBool('language_tutorial_shown') ?? false;

    if (!isTutorialShown) {
      _createTutorial();
      await prefs.setBool('language_tutorial_shown', true);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndShowTutorial();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A40),
      drawer: Drawer(child: ProfilePage()),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "اختر اللغة",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PopScope(
        canPop: false,

        // ================= Exit Handling =================
        onPopInvokedWithResult: (didPop, result) {
          final now = DateTime.now();

          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) >
                  const Duration(seconds: 2)) {
            _lastBackPressed = now;

            Fluttertoast.showToast(
              msg: "اضغط مرة أخرى للخروج",
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            SystemNavigator.pop();
          }
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ================= English Button =================
                  ElevatedButton(
                    key: _english,
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppRoute.fadeSlide(
                          CategoryPage(
                            language: 'en',
                            direction: TextDirection.ltr,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(200, 200),
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "English",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= Arabic Button =================
                  ElevatedButton(
                    key: _arabic,
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppRoute.fadeSlide(
                          CategoryPage(
                            language: 'ar',
                            direction: TextDirection.rtl,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(200, 200),
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "عربي",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Tutorial Coach Mark =================
  void _createTutorial() {
    final targets = [
      TargetFocus(
        identify: "english_button",
        keyTarget: _english,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => const Text(
              "Choose your English test language here",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "arabic_button",
        keyTarget: _arabic,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => const Text(
              "أختار لغة الاختبار العربي من هنا",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ];

    final tutorial = TutorialCoachMark(targets: targets);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      tutorial.show(context: context);
    });
  }
}
