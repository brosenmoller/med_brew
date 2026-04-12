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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
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

  // Apply any new built-in content from the bundled seed that is missing on
  // this device. Runs once per kSeedVersion bump; safe to re-run (idempotent).
  if (settingsService.seedVersion < AppDatabase.kSeedVersion) {
    await db.mergeNewSeedContent();
    await settingsService.setSeedVersion(AppDatabase.kSeedVersion);
    await questionService.refresh();
  }

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
