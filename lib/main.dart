import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/screens/home_screen.dart';
import 'package:med_brew/services/favorites_service.dart' show FavoritesService;
import 'package:med_brew/services/question_service.dart' show QuestionService;
import 'package:med_brew/services/settings_service.dart';
import 'package:med_brew/services/srs_service.dart' show SrsService;
import 'package:med_brew/utils/app_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageDir = await getAppStorageDir();
  Hive.init(storageDir.path);
  Hive.registerAdapter(UserQuestionDataAdapter());

  final db = AppDatabase();

  final srsService = SrsService();
  final questionService = QuestionService();
  final favoritesService = FavoritesService();
  final settingsService = SettingsService();
  await srsService.init();
  await questionService.init(db);
  await favoritesService.init();
  await settingsService.init();

  runApp(MedBrew(db: db));
}

class MedBrew extends StatefulWidget {
  final AppDatabase db;
  const MedBrew({super.key, required this.db});

  @override
  State<MedBrew> createState() => _MedBrewState();
}

class _MedBrewState extends State<MedBrew> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _settings.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Med Brew',
      locale: _settings.localeNotifier.value,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(db: widget.db),
    );
  }
}
