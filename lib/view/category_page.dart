import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../model/model.dart';
import '../widget/categories.dart';
import 'question_view.dart';

class CategoryPage extends StatefulWidget {
  final String language;
  const CategoryPage({super.key, required this.language});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late List<Category> filteredCategories;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    filteredCategories =
        categories.where((category) => category.id == widget.language).toList();
  }

  static const Color backgroundPurple = Color(0xFF1E1A40);
  static const Color primaryPurple = Color(0xFF6C63FF);

  Future<void> _refreshPage() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      filteredCategories =
          categories.where((category) => category.id == widget.language).toList();
      isLoading = false;
    });
  }

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
            letterSpacing: 1.2,
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
          effect: const ShimmerEffect(
            baseColor: Colors.white12,
            highlightColor: Colors.white24,
          ),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                onTap: isLoading
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionView(category: category),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryPurple.withValues(alpha: 0.85),
                        primaryPurple.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        category.image.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            category.image,
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.code,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            category.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
    );
  }
}
