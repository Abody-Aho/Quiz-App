import 'package:flutter/material.dart';
import '../core/class/route_transitions.dart';
import '../model/model.dart';
import 'login_page.dart';

// ================= Onboarding View =================
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // ================= Controllers & State =================
  final PageController _controller = PageController();
  int currentIndex = 0;

  // ================= Onboarding Data =================
  final List<OnboardItem> items = [
    OnboardItem(
      icon: Icons.smart_toy_rounded,
      title: "اختبارات ذكية",
      description:
          "أنشئ أسئلة واختبارات مخصصة باستخدام الذكاء الاصطناعي خلال ثوانٍ معدودة",
    ),
    OnboardItem(
      icon: Icons.category_rounded,
      title: "اختر المجال واللغة",
      description:
          "برمجة، لغات، علوم، تاريخ\nأو أضف مجالك الخاص باللغة التي تفضلها",
    ),
    OnboardItem(
      icon: Icons.psychology_rounded,
      title: "تعلّم وقيّم مستواك",
      description:
          "أجب على الأسئلة واحصل على نتيجتك فورًا مع تحليل معرفي ذكي وشامل",
    ),
    OnboardItem(
      icon: Icons.rocket_launch_rounded,
      title: "ابدأ رحلتك الآن",
      description:
          "اختبارات غير محدودة وتجربة تعليمية تفاعلية ممتازة بين يديك",
    ),
  ];

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      AppRoute.fadeSlide(const LoginPage()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final bool isLast = currentIndex == items.length - 1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0C20),
              Color(0xFF1E1035),
              Color(0xFF2A0845),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLast)
                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text(
                          "تخطي",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E163B)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Glowing Icon Badge
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.3),
                                      const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.15),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 80,
                                  color: const Color(0xFFA78BFA),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Title
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Description
                              Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: currentIndex == index
                          ? const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFEC4899)],
                            )
                          : null,
                      color: currentIndex == index
                          ? null
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: currentIndex == index
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEC4899)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : [],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (currentIndex < items.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToLogin();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? "ابدأ الآن" : "التالي",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
