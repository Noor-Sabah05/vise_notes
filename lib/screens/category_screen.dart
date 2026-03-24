import 'package:flutter/material.dart';
import '../models/category_model.dart';
import 'notes_list_screen.dart';

class CategoryScreen extends StatelessWidget {
  final List<Category> categories = [
    Category(name: "Mathematics", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.functions, color: const Color(0xFF7B78D8)),
    Category(name: "Physics", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.fitness_center, color: const Color(0xFFFFA069)),
    Category(name: "Chemistry", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.science_outlined, color: const Color(0xFFFF6B6B)),
    Category(name: "AHCI", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.desktop_windows_outlined, color: const Color(0xFF38A3A5)),
    Category(name: "AI", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.smart_toy_outlined, color: const Color(0xFFD471D4)),
    Category(name: "CA", noteCount: "12 Notes", lastUpdated: "2 days ago", icon: Icons.memory_outlined, color: const Color(0xFF6B6B6B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF915BFF),
        elevation: 0,
        toolbarHeight: 130,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Notes", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Click on category to access its notes", style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.82,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) => _buildCategoryCard(context, categories[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category cat) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotesListScreen(category: cat))),
      child: Container(
        decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(cat.noteCount, style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text(cat.lastUpdated, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: const TextStyle(color: Colors.white, fontSize: 20),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 28),
          suffixIcon: const Icon(Icons.mic, color: Colors.white, size: 28),
          filled: true,
          fillColor: const Color(0xFFB388FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(color: Color(0xFF915BFF)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_outlined, label: "Home"),
          _NavItem(icon: Icons.assignment_outlined, label: "Notes"),
          _NavItem(icon: Icons.mic, label: "Records"),
          _NavItem(icon: Icons.stars_outlined, label: "Events"),
          _NavItem(icon: Icons.person_outline, label: "Profile"),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}