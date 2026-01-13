import 'dart:convert';
import 'dart:io';
import 'package:exam/widget/custom_text_fiele.dart';
import 'package:flutter/material.dart';
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

// ================= Category Page =================
class CategoryPage extends StatefulWidget {
  final String language;
  final TextDirection direction;

  const CategoryPage({
    super.key,
    required this.language,
    required this.direction,
  });

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {

  // ================= Controllers & Keys =================
  TextEditingController titleController = TextEditingController();
  TextEditingController promptController = TextEditingController();

  final GlobalKey _firstCategoryKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  XFile? selectedImage;
  final _formKey = GlobalKey<FormState>();

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
        prefs.getBool('tutorial_shown_${widget.language}') ?? false;

    if (!isTutorialShown) {
      _createTutorial();
      await prefs.setBool('tutorial_shown_${widget.language}', true);
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
      filteredCategories =
          categories.where((c) => c.language == widget.language).toList();
    });
  }

  static const Color backgroundPurple = Color(0xFF1E1A40);
  static const Color primaryPurple = Color(0xFF6C63FF);

  // ================= Refresh =================
  Future<void> _refreshPage() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    _updateFilteredCategories();
    setState(() => isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPurple,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.language == 'en' ? "Choose Category" : "اختر الفئة",
          style: const TextStyle(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCategoryImage(category.image),
                      const SizedBox(height: 12),
                      Text(
                        category.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ================= Difficulty Dialog =================
  void _showDifficultyDialog(BuildContext context, Category category) {
    const Color primaryPurple = Color(0xFF6C63FF);
    const Color lightPurple = Color(0xFFF3F2FF);

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
                widget.language == 'en'
                    ? "Choose Difficulty"
                    : "اختر مستوى الصعوبة",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              _difficultyButton(
                title: widget.language == 'en' ? "Easy" : "سهل",
                color: primaryPurple,
                background: lightPurple,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: widget.language,
                        level:
                        "Easy: basic and introductory questions suitable for beginners.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: widget.language == 'en' ? "Medium" : "متوسط",
                color: primaryPurple,
                background: lightPurple,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: widget.language,
                        level:
                        "Medium: moderately challenging questions that require solid understanding.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: widget.language == 'en' ? "Hard" : "صعب",
                color: Colors.white,
                background: primaryPurple,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: widget.language,
                        level:
                        "Hard: advanced questions that test deep knowledge and analytical thinking.",
                      ),
                    ),
                  );
                },
              ),

              _difficultyButton(
                title: widget.language == 'en' ? "Very Hard" : "صعب جداً",
                color: Colors.white,
                background: const Color(0xFF4A43D1),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                      QuestionView(
                        category: category,
                        language: widget.language,
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
    selectedImage = null;
  }

  String? _categoryValidator(String? value) {
    if (value == null || value.isEmpty) {
      return widget.language == 'en' ? 'Required field' : 'الحقل مطلوب';
    }
    return null;
  }

  // ================= Add / Edit / Delete =================

  void _showAddCategoryDialog() {
    showScaleDialog(
      context: context,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E2A50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              widget.language == 'en' ? 'Add New Category' : 'إضافة فئة جديدة',
              style: const TextStyle(color: Colors.white),textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      hintText: widget.language == 'en' ? 'Title' : 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(Icons.title, color: Colors.black),
                      isEnglish: widget.language == 'en',
                      textDirection: widget.language == 'en'
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: widget.language == 'en'
                          ? 'Type of questions'
                          : 'نوع الاسئلة',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.black,
                      ),
                      isEnglish: widget.language == 'en',
                      textDirection: widget.language == 'en'
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      length: 250,
                    ),
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
                      label: Text(
                        widget.language == 'en' ? 'Image' : 'اختر صورة',
                        style: const TextStyle(color: Colors.white70),
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
                child: Text(
                  widget.language == 'en' ? 'Cancel' : 'إلغاء',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    categories.add(
                      Category(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        language: widget.language,
                        title: titleController.text,
                        prompt: promptController.text,
                        image: selectedImage?.path ?? '',
                        direction: widget.direction,
                      ),
                    );
                    await saveCategories(categories);
                    _updateFilteredCategories();
                    _clearCategoryForm();
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.language == 'en' ? 'Save' : 'حفظ'),
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

    showScaleDialog(
      context: context,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E2A50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              widget.language == 'en' ? 'Edit Category' : 'تعديل الفئة',
              style: const TextStyle(color: Colors.white),textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      hintText: widget.language == 'en' ? 'Title' : 'العنوان',
                      titleController: titleController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(Icons.title, color: Colors.black),
                      isEnglish: widget.language == 'en',
                      textDirection: widget.language == 'en'
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      length: 50,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hintText: widget.language == 'en'
                          ? 'Type of questions'
                          : 'نوع الاسئلة',
                      titleController: promptController,
                      validator: _categoryValidator,
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.black,
                      ),
                      isEnglish: widget.language == 'en',
                      textDirection: widget.language == 'en'
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      length: 250,
                    ),
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
                      label: Text(
                        widget.language == 'en'
                            ? 'Change Image'
                            : 'تغيير الصورة',
                        style: const TextStyle(color: Colors.white70),
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
                child: Text(
                  widget.language == 'en' ? 'Cancel' : 'إلغاء',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  showDeleteConfirmDialog(
                    context: context,
                    language: widget.language,
                    onConfirm: () async {
                      categories.removeAt(index);
                      await saveCategories(categories);
                      _updateFilteredCategories();
                      Navigator.pop(context);
                    },
                  );
                },
                child: Text(
                  widget.language == 'en' ? 'Delete' : 'حذف',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    categories[index] = Category(
                      id: category.id,
                      language: category.language,
                      title: titleController.text,
                      prompt: promptController.text,
                      image: selectedImage?.path ?? '',
                      direction: category.direction,
                    );
                    await saveCategories(categories);
                    _updateFilteredCategories();
                    _clearCategoryForm();
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.language == 'en' ? 'Update' : 'تحديث'),
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
    required String language,
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
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                language == 'en' ? 'Delete' : 'تأكيد الحذف',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            language == 'en'
                ? 'Are you sure you want to delete this category?'
                : 'هل أنت متأكد من حذف هذه الفئة؟',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                language == 'en' ? 'Cancel' : 'إلغاء',
                style: const TextStyle(color: Colors.grey),
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
              child: Text(
                language == 'en' ? 'Delete' : 'حذف',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // إنشاء الإرشادات التوضيحية
  void _createTutorial() {
    final targets = [
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.language == 'en'
                    ? 'Click here to add a new category'
                    : 'أضغط هنا لأضافة فئة جديدة',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
            builder: (_, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.language == 'en'
                    ? 'Press and hold to edit this category'
                    : 'اضغط مطولًا لتعديل هذه الفئة',
                textAlign: TextAlign.center,
                style: const TextStyle(
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

