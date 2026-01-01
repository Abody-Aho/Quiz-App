import 'package:flutter/material.dart';

Future<void> showScaleDialog({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) {
      return Center(child: child);
    },
    transitionBuilder: (_, animation, _, child) {
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
