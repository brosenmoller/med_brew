import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/screens/home_screen.dart';
import 'package:med_brew/services/favorites_service.dart' show FavoritesService;
import 'package:med_brew/services/question_service.dart' show QuestionService;
import 'package:med_brew/services/srs_service.dart' show SrsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserQuestionDataAdapter());

  final db = AppDatabase();

  final srsService = SrsService();
  final questionService = QuestionService();
  final favoritesService = FavoritesService();
  await srsService.init();
  await questionService.init(db);
  await favoritesService.init();

  runApp(MedBrew(db: db));
}

class MedBrew extends StatelessWidget {
  final AppDatabase db;
  const MedBrew({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Med Brew",
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(db: db),
    );
  }
}