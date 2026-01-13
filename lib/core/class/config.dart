import 'dart:io';

// ================= Internet Connection Check =================
// التحقق من توفر اتصال بالإنترنت عبر اختبار الوصول إلى خادم خارجي
Future<bool> checkIConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');

    // التحقق من نجاح الاتصال واستلام عنوان IP صالح
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('connected');
      return true;
    } else {
      print('not connected');
      return false;
    }
  }
  // معالجة فشل الاتصال أو عدم توفر الشبكة
  on SocketException catch (_) {
    print('not connected');
    return false;
  }
}
