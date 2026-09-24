import 'dart:convert';
import 'dart:io';
import 'package:exam/view/profile_page.dart';
import 'package:exam/widget/custom_text_fiele.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/class/dialogs.dart';
import '../core/class/route_transitions.dart';
import '../model/model.dart';
import '../widget/categories.dart';
import 'question_view.dart';

// ================= Language Helper =================
final List<String> availableLanguages = [
  'العربية',
  'English',
  'Français',
  'Español',
  'Deutsch',
  'Italiano',
  'Türkçe',
  'Русский',
  '中文',
  '日本語',
  '한국어',
  'Português',
  'हिन्दी',
  'اردو',
  'أخرى',
];

TextDirection getDirectionForLanguage(String lang) {
  final lower = lang.toLowerCase();
  if (lower == 'ar' ||
      lower == 'arabic' ||
      lower == 'العربية' ||
      lower == 'العربيه' ||
      lower == 'ur' ||
      lower == 'urdu' ||
      lower == 'اردو' ||
      lower == 'fa' ||
      lower == 'persian' ||
      lower == 'فارسي') {
    return TextDirection.rtl;
  }
  return TextDirection.ltr;
}

// ================= Category Page =================
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // ================= Controllers & Keys =================
  TextEditingController titleController = TextEditingController();
  TextEditingController promptController = TextEditingController();
  TextEditingController customLanguageController = TextEditingController();

  final GlobalKey _firstCategoryKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  XFile? selectedImage;
  final _formKey = GlobalKey<FormState>();

  DateTime? _lastBackPressed;

  // ================= State =================
  List<Category> filteredCategories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= Permission Helper =================
  Future<XFile?> _pickImageWithPermission(BuildContext dialogContext) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      try {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        return picked;
      } catch (_) {
        return null;
      }
    } else {
      if (!dialogContext.mounted) return null;
      _showPermissionDeniedDialog(dialogContext);
      return null;
    }
  }

  void _showPermissionDeniedDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1537),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.photo_library_rounded, color: Color(0xFFA78BFA)),
              SizedBox(width: 8),
              Text(
                'إذن الوصول للصور',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'لاختيار صورة للفئة، يجب السماح للتطبيق بالوصول إلى معرض الصور. يرجى قبول الإذن من الإعدادات.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text(
                  'فتح الإعدادات',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= Local Data Loading =================
  Future<void> _loadData() async {
    final savedCategories = await loadCategories();

    if (savedCategories.isNotEmpty) {
      setState(() {
        categories
          ..clear()
          ..addAll(savedCategories);
      });
    }

    _updateFilteredCategories();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (filteredCategories.isNotEmpty) {
        _checkAndShowTutorial();
      }
    });
  }

  // ================= Tutorial Check =================
  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isTutorialShown =
        prefs.getBool('category_tutorial_shown') ?? false;

    if (!isTutorialShown) {
      _createTutorial();
      await prefs.setBool('category_tutorial_shown', true);
    }
  }

  // ================= Local Storage =================
  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
        categories.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('categories', jsonList);
  }

  Future<List<Category>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('categories');
    if (jsonList == null) return [];
    return jsonList.map((j) => Category.fromMap(jsonDecode(j))).toList();
  }

  // ================= Image Handling =================
  Future<String> saveImagePermanently(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(image.path);
    final savedImage = await image.copy('${dir.path}/$fileName');
    return savedImage.path;
  }

  // ================= Filtering =================
  void _updateFilteredCategories() {
    setState(() {
      filteredCategories = List.from(categories);
    });
  }

  // ================= Refresh =================
  Future<void> _refreshPage() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    _updateFilteredCategories();
    setState(() => isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();

        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          Fluttertoast.showToast(
            msg: "اضغط مرة أخرى للخروج",
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: const Drawer(child: ProfilePage()),
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
                // Custom Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => InkWell(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "اختر الفئة",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42), // Balance for drawer button
                    ],
                  ),
                ),

                // Grid Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPage,
                    color: const Color(0xFF8B5CF6),
                    backgroundColor: const Color(0xFF1E163B),
                    child: Skeletonizer(
                      enabled: isLoading,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: filteredCategories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return GestureDetector(
                            onLongPress: () => _showEditCategoryDialog(
                              category,
                              categories.indexOf(category),
                            ),
                            onTap: () =>
                                _showDifficultyDialog(context, category),
                            child: Container(
                              key: index == 0 ? _firstCategoryKey : null,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E163B)
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image Frame with subtle glow
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6C63FF)
                                                .withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                      child:
                                          _buildCategoryImage(category.image),
                                    ),
                                    const SizedBox(height: 12),

                                    // Title
                                    Text(
                                      category.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Language Badge Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF)
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF6C63FF)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.language_rounded,
                                            size: 13,
                                            color: Color(0xFFA78BFA),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            category.language,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFDDD6FE),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            key: _fabKey,
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () {
              _clearCategoryForm();
              _showAddCategoryDialog();
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ================= Difficulty Dialog =================
  void _showDifficultyDialog(BuildContext context, Category category) {
    final bool isArabic = category.direction == TextDirection.rtl;

    showScaleDialog(
      context: context,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF1B1537),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: Color(0xFFA78BFA),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                isArabic ? "اختر مستوى الصعوبة" : "Choose Difficulty",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  "${isArabic ? 'لغة الاختبار' : 'Language'}: ${category.language}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Difficulty Buttons
              _difficultyButton(
                title: isArabic ? "سهل" : "Easy",
                color: Colors.white,
                background: const Color(0xFF10B981), // Emerald Green
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: category.language,
                        level:
                            "Easy: basic and introductory questions suitable for beginners.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: isArabic ? "متوسط" : "Medium",
                color: Colors.white,
                background: const Color(0xFF6C63FF), // Purple
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: category.language,
                        level:
                            "Medium: moderately challenging questions that require solid understanding.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: isArabic ? "صعب" : "Hard",
                color: Colors.white,
                background: const Color(0xFFF59E0B), // Amber
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: category.language,
                        level:
                            "Hard: advanced questions that test deep knowledge and analytical thinking.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: isArabic ? "صعب جداً" : "Very Hard",
                color: Colors.white,
                background: const Color(0xFFEF4444), // Crimson Red
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: category.language,
                        level:
                            "Very Hard: expert-level, complex, and highly analytical questions.",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyButton({
    required String title,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: color,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ================= Category Image =================
  Widget _buildCategoryImage(String imagePath) {
    if (imagePath.isEmpty) {
      return const Icon(Icons.code_rounded, size: 40, color: Color(0xFFA78BFA));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imagePath.startsWith('asset')
          ? Image.asset(imagePath, height: 60, width: 60, fit: BoxFit.cover)
          : Image.file(File(imagePath),
              height: 60, width: 60, fit: BoxFit.cover),
    );
  }

  // ================= Form Helpers =================
  void _clearCategoryForm() {
    titleController.clear();
    promptController.clear();
    customLanguageController.clear();
    selectedImage = null;
  }

  String? _categoryValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الحقل مطلوب';
    }
    return null;
  }

  // ================= Add / Edit Dialogs =================

  void _showAddCategoryDialog() {
    String selectedLang = 'العربية';

    showScaleDialog(
      context: context,
      child: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B1537),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFFA78BFA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'إضافة فئة جديدة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(
                      hintText: 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon:
                          const Icon(Icons.title_rounded, color: Colors.black),
                      isEnglish: false,
                      textDirection: TextDirection.rtl,
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: 'نوع الاسئلة (الوصف أو المواضيع)',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        color: Colors.black,
                      ),
                      isEnglish: false,
                      textDirection: TextDirection.rtl,
                      length: 250,
                    ),
                    const SizedBox(height: 15),

                    // Language Selector Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: availableLanguages.contains(selectedLang)
                          ? selectedLang
                          : 'أخرى',
                      dropdownColor: const Color(0xFF231B45),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'لغة الاختبار',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.language_rounded,
                          color: Color(0xFFA78BFA),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      items: availableLanguages.map((String lang) {
                        return DropdownMenuItem<String>(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedLang = newValue;
                          });
                        }
                      },
                    ),

                    if (selectedLang == 'أخرى') ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        hintText: 'أدخل اسم اللغة (مثال: Swahili)',
                        titleController: customLanguageController,
                        validator: _categoryValidator,
                        prefixIcon: const Icon(
                          Icons.translate_rounded,
                          color: Colors.black,
                        ),
                        isEnglish: true,
                        textDirection: TextDirection.ltr,
                        length: 50,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Image Preview & Select
                    if (selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: selectedImage!.path.startsWith('asset')
                            ? Image.asset(
                                selectedImage!.path,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(selectedImage!.path),
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                      ),

                    TextButton.icon(
                      icon: const Icon(Icons.image_rounded,
                          color: Color(0xFFA78BFA)),
                      label: const Text(
                        'اختر صورة للفئة',
                        style: TextStyle(
                          color: Color(0xFFDDD6FE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final picked = await _pickImageWithPermission(dialogCtx);
                        if (picked != null) {
                          final permanentPath = await saveImagePermanently(
                            File(picked.path),
                          );
                          setDialogState(() {
                            selectedImage = XFile(permanentPath);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final String finalLang = selectedLang == 'أخرى'
                          ? customLanguageController.text.trim()
                          : selectedLang;

                      if (finalLang.isEmpty) return;

                      final direction = getDirectionForLanguage(finalLang);

                      categories.add(
                        Category(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          language: finalLang,
                          title: titleController.text,
                          prompt: promptController.text,
                          image: selectedImage?.path ?? '',
                          direction: direction,
                        ),
                      );
                      await saveCategories(categories);
                      _updateFilteredCategories();
                      _clearCategoryForm();
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text(
                    'حفظ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category, int index) {
    titleController.text = category.title;
    promptController.text = category.prompt;
    selectedImage = category.image.isNotEmpty ? XFile(category.image) : null;

    String selectedLang = availableLanguages.contains(category.language)
        ? category.language
        : 'أخرى';

    if (selectedLang == 'أخرى') {
      customLanguageController.text = category.language;
    } else {
      customLanguageController.clear();
    }

    showScaleDialog(
      context: context,
      child: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B1537),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFA78BFA),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'تعديل الفئة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(
                      hintText: 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon:
                          const Icon(Icons.title_rounded, color: Colors.black),
                      isEnglish: false,
                      textDirection:
                          getDirectionForLanguage(category.language),
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: 'نوع الاسئلة',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        color: Colors.black,
                      ),
                      isEnglish: false,
                      textDirection:
                          getDirectionForLanguage(category.language),
                      length: 250,
                    ),
                    const SizedBox(height: 15),

                    // Language Selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedLang,
                      dropdownColor: const Color(0xFF231B45),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'لغة الاختبار',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.language_rounded,
                          color: Color(0xFFA78BFA),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      items: availableLanguages.map((String lang) {
                        return DropdownMenuItem<String>(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedLang = newValue;
                          });
                        }
                      },
                    ),

                    if (selectedLang == 'أخرى') ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        hintText: 'أدخل اسم اللغة (مثال: Swahili)',
                        titleController: customLanguageController,
                        validator: _categoryValidator,
                        prefixIcon: const Icon(
                          Icons.translate_rounded,
                          color: Colors.black,
                        ),
                        isEnglish: true,
                        textDirection: TextDirection.ltr,
                        length: 50,
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: selectedImage!.path.startsWith('asset')
                            ? Image.asset(
                                selectedImage!.path,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(selectedImage!.path),
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                      ),

                    TextButton.icon(
                      icon: const Icon(Icons.image_rounded,
                          color: Color(0xFFA78BFA)),
                      label: const Text(
                        'تغيير الصورة',
                        style: TextStyle(
                          color: Color(0xFFDDD6FE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final picked = await _pickImageWithPermission(dialogCtx);
                        if (picked != null) {
                          final permanentPath = await saveImagePermanently(
                            File(picked.path),
                          );
                          setDialogState(() {
                            selectedImage = XFile(permanentPath);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                label: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
                onPressed: () {
                  showDeleteConfirmDialog(
                    context: dialogCtx,
                    onConfirm: () async {
                      categories.removeAt(index);
                      await saveCategories(categories);
                      _updateFilteredCategories();
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                    },
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final String finalLang = selectedLang == 'أخرى'
                          ? customLanguageController.text.trim()
                          : selectedLang;

                      if (finalLang.isEmpty) return;

                      final direction = getDirectionForLanguage(finalLang);

                      categories[index] = Category(
                        id: category.id,
                        language: finalLang,
                        title: titleController.text,
                        prompt: promptController.text,
                        image: selectedImage?.path ?? '',
                        direction: direction,
                      );
                      await saveCategories(categories);
                      _updateFilteredCategories();
                      _clearCategoryForm();
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text(
                    'تحديث',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> showDeleteConfirmDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1537),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'تأكيد الحذف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذه الفئة؟',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= Tutorial Coach Mark =================
  void _createTutorial() {
    final targets = [
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, _) => const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'أضغط هنا لأضافة فئة جديدة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'first_category',
        keyTarget: _firstCategoryKey,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, _) => const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'اضغط مطولًا لتعديل هذه الفئة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
