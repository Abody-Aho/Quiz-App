import 'package:flutter/material.dart';

// ================= Scale Dialog =================
// دالة عامة لعرض Dialog مخصص مع تأثير تكبير (Scale Animation)
Future<void> showScaleDialog({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.5), // تعتيم الخلفية
    transitionDuration: const Duration(milliseconds: 350), // مدة الحركة
    pageBuilder: (_, _, _) {
      return Center(child: child);
    },
    transitionBuilder: (_, animation, _, child) {
      // تأثير التكبير مع منحنى حركة ناعم
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: child,
      );
    },
  );
}
