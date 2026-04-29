import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/db_service.dart';
import 'notes_history_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categories = [];
  final DBService _dbService = DBService();
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categoryNames = await _dbService.getUniqueCategories();

      List<Category> loadedCategories = [];
      for (final name in categoryNames) {
        final count = await _dbService.getCategoryNoteCount(name);
        final lastUpdated = await _dbService.getCategoryLastUpdated(name);

        loadedCategories.add(
          Category(
            name: name,
            noteCount: count,
            lastUpdated: lastUpdated,
            icon: getCategoryIcon(name),
            color: getCategoryColor(name),
          ),
        );
      }

      setState(() {
        categories = loadedCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return categories;
    return categories
        .where(
          (cat) => cat.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9859FF),
        elevation: 0,
        toolbarHeight: 130,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notes Library",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "${categories.length} ${categories.length == 1 ? 'Category' : 'Categories'}",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: const Color(0xFF9859FF)),
            )
          : categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 80,
                    color: const Color(0xFF9859FF).withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notes yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Record or upload audio to create notes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(context, _filteredCategories[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category cat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotesHistoryScreen(category: cat)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cat.color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cat.color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              cat.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${cat.noteCount} ${cat.noteCount == 1 ? 'Note' : 'Notes'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              cat.lastUpdated,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: _filterCategories,
        decoration: InputDecoration(
          hintText: "Search categories",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9859FF),
            size: 24,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
