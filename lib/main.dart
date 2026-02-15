import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/screens/home_screen.dart';
import 'package:med_brew/services/favorites_service.dart' show FavoritesService;
import 'package:med_brew/services/question_service.dart' show QuestionService;
import 'package:med_brew/services/srs_service.dart' show SrsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserQuestionDataAdapter());

  final srsService = SrsService();
  final questionService = QuestionService();
  final favoritesService = FavoritesService();
  await srsService.init();
  await questionService.init(
      questionsAsset: 'assets/questions.json',
      categoriesAsset: 'assets/categories.json',
      quizzesAsset: 'assets/quizzes.json'
  );
  await favoritesService.init();

  runApp(const MedBrew());
}

class MedBrew extends StatelessWidget {
  const MedBrew({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Med Brew",
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}