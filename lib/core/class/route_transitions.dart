import 'package:flutter/material.dart';

// ================= Custom Page Transition =================
class AppRoute {
  static Route fadeSlide(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450), // مدة الانتقال للأمام
      reverseTransitionDuration: const Duration(milliseconds: 300), // مدة الرجوع
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        // تأثير الانزلاق من اليمين إلى المنتصف
        final slide = Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        // تأثير التلاشي التدريجي
        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation);

        // دمج تأثيري التلاشي والانزلاق
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }
}
