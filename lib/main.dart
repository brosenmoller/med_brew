import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:med_brew/data/question_repository.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/screens/home_screen.dart';
import 'package:med_brew/services/question_service.dart' show QuestionService;
import 'package:med_brew/services/srs_service.dart' show SrsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserQuestionDataAdapter());

  await QuestionRepository.loadQuestions('assets/questions.json');

  final srsService = SrsService();
  QuestionService();
  await srsService.init();

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