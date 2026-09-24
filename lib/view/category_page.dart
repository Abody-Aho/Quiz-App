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

  static const Color backgroundPurple = Color(0xFF1E1A40);
  static const Color primaryPurple = Color(0xFF6C63FF);

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
        backgroundColor: backgroundPurple,
        drawer: const Drawer(child: ProfilePage()),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            "اختر الفئة",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPage,
          color: primaryPurple,
          backgroundColor: Colors.white,
          child: Skeletonizer(
            enabled: isLoading,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  onTap: () => _showDifficultyDialog(context, category),
                  child: Container(
                    key: index == 0 ? _firstCategoryKey : null,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryPurple.withValues(alpha: 0.8),
                          primaryPurple.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCategoryImage(category.image),
                          const SizedBox(height: 8),
                          Text(
                            category.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category.language,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
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
        floatingActionButton: FloatingActionButton(
          key: _fabKey,
          backgroundColor: primaryPurple,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            _clearCategoryForm();
            _showAddCategoryDialog();
          },
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ================= Difficulty Dialog =================
  void _showDifficultyDialog(BuildContext context, Category category) {
    const Color primaryPurple = Color(0xFF6C63FF);
    const Color lightPurple = Color(0xFFF3F2FF);
    final bool isArabic = category.direction == TextDirection.rtl;

    showScaleDialog(
      context: context,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2E2A55),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${isArabic ? 'لغة الاختبار' : 'Language'}: ${category.language}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _difficultyButton(
                title: isArabic ? "سهل" : "Easy",
                color: primaryPurple,
                background: lightPurple,
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
                color: primaryPurple,
                background: lightPurple,
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
                background: primaryPurple,
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
                background: const Color(0xFF4A43D1),
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

  // ================= Widgets =================
  Widget _difficultyButton({
    required String title,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: color,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ================= Category Image =================
  Widget _buildCategoryImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.code, size: 36, color: Colors.white),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imagePath.startsWith('asset')
          ? Image.asset(imagePath, height: 70, width: 70, fit: BoxFit.cover)
          : Image.file(File(imagePath),
              height: 70, width: 70, fit: BoxFit.cover),
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

  // ================= Add / Edit / Delete =================

  void _showAddCategoryDialog() {
    String selectedLang = 'العربية';

    showScaleDialog(
      context: context,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E2A50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'إضافة فئة جديدة',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      hintText: 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(Icons.title, color: Colors.black),
                      isEnglish: false,
                      textDirection: TextDirection.rtl,
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: 'نوع الاسئلة',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.black,
                      ),
                      isEnglish: false,
                      textDirection: TextDirection.rtl,
                      length: 250,
                    ),
                    const SizedBox(height: 15),

                    // ===== Language Selector =====
                    DropdownButtonFormField<String>(
                      initialValue: availableLanguages.contains(selectedLang)
                          ? selectedLang
                          : 'أخرى',
                      dropdownColor: const Color(0xFF2E2A50),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'لغة الاختبار',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.language, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                        prefixIcon:
                            const Icon(Icons.translate, color: Colors.black),
                        isEnglish: true,
                        textDirection: TextDirection.ltr,
                        length: 50,
                      ),
                    ],

                    const SizedBox(height: 15),
                    if (selectedImage != null)
                      selectedImage!.path.startsWith('asset')
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
                    TextButton.icon(
                      icon: const Icon(Icons.image, color: Colors.white70),
                      label: const Text(
                        'اختر صورة',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
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
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
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
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E2A50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'تعديل الفئة',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      hintText: 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(Icons.title, color: Colors.black),
                      isEnglish: false,
                      textDirection: getDirectionForLanguage(category.language),
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: 'نوع الاسئلة',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.black,
                      ),
                      isEnglish: false,
                      textDirection: getDirectionForLanguage(category.language),
                      length: 250,
                    ),
                    const SizedBox(height: 15),

                    // ===== Language Selector =====
                    DropdownButtonFormField<String>(
                      initialValue: selectedLang,
                      dropdownColor: const Color(0xFF2E2A50),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'لغة الاختبار',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.language, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                        prefixIcon:
                            const Icon(Icons.translate, color: Colors.black),
                        isEnglish: true,
                        textDirection: TextDirection.ltr,
                        length: 50,
                      ),
                    ],

                    const SizedBox(height: 15),
                    if (selectedImage != null)
                      selectedImage!.path.startsWith('asset')
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
                    TextButton.icon(
                      icon: const Icon(Icons.image, color: Colors.white70),
                      label: const Text(
                        'تغيير الصورة',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  showDeleteConfirmDialog(
                    context: context,
                    onConfirm: () async {
                      categories.removeAt(index);
                      await saveCategories(categories);
                      _updateFilteredCategories();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  );
                },
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
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
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: const Text('تحديث'),
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
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
              onPressed: () => Navigator.pop(context),
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
                Navigator.pop(context);
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
