import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/screens/category_overview_screen.dart';
import 'package:med_brew/screens/manage_content_screens/manage_content_screen.dart';
import 'package:med_brew/screens/settings_screen.dart';
import 'package:med_brew/screens/favorites_screen.dart';
import 'srs_overview_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppDatabase db;

  const HomeScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Med Brew",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryOverviewScreen()),
              ),
              child: const Text("Categories"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SrsOverviewScreen()),
              ),
              child: const Text("Spaced Repetition"),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.star),
              label: const Text("Favorites"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
            const SizedBox(height: 30),
            // New button — leads to the category/quiz/question management screens
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text("Manage Content"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageContentScreen(db: db)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}