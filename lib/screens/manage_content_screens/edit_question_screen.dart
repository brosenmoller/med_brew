import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/models/answer_configs.dart' show FlashcardConfig, ImageClickConfig, MultipleChoiceConfig, SortingConfig, TypedAnswerConfig;
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';
import 'package:med_brew/widgets/unsaved_changes_guard.dart';
import 'edit_question/answer_type_selector.dart';
import 'edit_question/multiple_choice_section.dart';
import 'edit_question/typed_answer_section.dart';
import 'edit_question/image_click_section.dart';
import 'edit_question/flashcard_section.dart';
import 'edit_question/sorting_section.dart';

class EditQuestionScreen extends StatefulWidget {
  final String quizId;
  final AppDatabase db;
  final Question? question; // If provided → edit mode; if null → add mode

  const EditQuestionScreen({
    super.key,
    required this.quizId,
    required this.db,
    this.question,
  });

  bool get isEditing => question != null;

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickerKey = GlobalKey<ImagePickerFieldState>();
  final _flashcardFrontPickerKey = GlobalKey<ImagePickerFieldState>();
  final _flashcardBackPickerKey = GlobalKey<ImagePickerFieldState>();
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late String _answerType;
  late String? _imagePath;
  bool _isDirty = false;

  // Multiple choice
  late final List<TextEditingController> _optionControllers;
  late Set<int> _correctIndices;
  bool _multipleCorrectEnabled = false;
  bool _showCorrectCount = false;

  // Typed
  late final List<TextEditingController> _acceptedAnswerControllers;

  // Image click — list of polygons in normalized (0–1) coordinates
  List<List<Offset>> _selectedImageAreas = [];

  // Flashcard
  late final TextEditingController _flashcardFrontTextController;
  late final TextEditingController _flashcardBackTextController;
  String? _flashcardFrontImagePath;
  String? _flashcardBackImagePath;
  bool _flashcardRandomizeSides = false;

  // Sorting
  late final List<TextEditingController> _sortingControllers;
  bool _sortingShowPreFilled = true;

  bool get _hasChanges => _isDirty;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    final q = widget.question;

    _answerType = q?.answerType ?? 'multipleChoice';
    _imagePath = q?.imagePath;
    _questionController = TextEditingController(text: q?.questionText ?? '');
    _explanationController =
        TextEditingController(text: q?.explanation ?? '');

    if (q != null) {
      Map<String, dynamic> config;
      try {
        config = jsonDecode(q.answerConfig) as Map<String, dynamic>;
      } catch (_) {
        config = {};
      }

      if (_answerType == 'multipleChoice') {
        final mc = MultipleChoiceConfig.fromJson(config);
        _optionControllers = mc.options
            .map((o) => TextEditingController(text: o))
            .toList();
        while (_optionControllers.length < 2) {
          _optionControllers.add(TextEditingController());
        }
        _correctIndices = mc.correctIndices.toSet();
        _multipleCorrectEnabled = mc.multipleCorrect;
        _showCorrectCount = mc.showCorrectCount;
      } else {
        _optionControllers =
            List.generate(4, (_) => TextEditingController());
        _correctIndices = {0};
      }

      if (_answerType == 'typed') {
        final tc = TypedAnswerConfig.fromJson(config);
        _acceptedAnswerControllers = tc.acceptedAnswers
            .map((a) => TextEditingController(text: a))
            .toList();
      } else {
        _acceptedAnswerControllers = [TextEditingController()];
      }

      if (_answerType == 'imageClick') {
        final ic = ImageClickConfig.fromJson(config);
        _selectedImageAreas = ic.correctAreas;
      }

      if (_answerType == 'flashcard') {
        final fc = FlashcardConfig.fromJson(config);
        _flashcardFrontTextController =
            TextEditingController(text: fc.frontText ?? '');
        _flashcardBackTextController =
            TextEditingController(text: fc.backText ?? '');
        _flashcardFrontImagePath = fc.frontImagePath;
        _flashcardBackImagePath = fc.backImagePath;
        _flashcardRandomizeSides = fc.randomizeSides;
      } else {
        _flashcardFrontTextController = TextEditingController();
        _flashcardBackTextController = TextEditingController();
      }

      if (_answerType == 'sorting') {
        final sc = SortingConfig.fromJson(config);
        _sortingControllers =
            sc.items.map((s) => TextEditingController(text: s)).toList();
        while (_sortingControllers.length < 2) {
          _sortingControllers.add(TextEditingController());
        }
        _sortingShowPreFilled = sc.showPreFilled;
      } else {
        _sortingControllers =
            List.generate(4, (_) => TextEditingController());
      }
    } else {
      // Add mode defaults
      _optionControllers =
          List.generate(4, (_) => TextEditingController());
      _correctIndices = {0};
      _acceptedAnswerControllers = [TextEditingController()];
      _flashcardFrontTextController = TextEditingController();
      _flashcardBackTextController = TextEditingController();
      _sortingControllers =
          List.generate(4, (_) => TextEditingController());
    }

    _questionController.addListener(_markDirty);
    _explanationController.addListener(_markDirty);
    for (final c in _optionControllers) { c.addListener(_markDirty); }
    for (final c in _acceptedAnswerControllers) { c.addListener(_markDirty); }
    _flashcardFrontTextController.addListener(_markDirty);
    _flashcardBackTextController.addListener(_markDirty);
    for (final c in _sortingControllers) { c.addListener(_markDirty); }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) c.dispose();
    for (final c in _acceptedAnswerControllers) c.dispose();
    _flashcardFrontTextController.dispose();
    _flashcardBackTextController.dispose();
    for (final c in _sortingControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      message: l10n.unsavedChangesQuestion,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? l10n.editQuestionAppBarTitle : l10n.addQuestionAppBarTitle),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: l10n.questionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: null,
                    validator: (v) => v!.trim().isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 16),

                  AnswerTypeSelector(
                    selected: _answerType,
                    onChanged: (v) => setState(() {
                      _answerType = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 16),

                  if (_answerType == 'multipleChoice')
                    MultipleChoiceSection(
                      optionControllers: _optionControllers,
                      correctIndices: _correctIndices,
                      multipleCorrectEnabled: _multipleCorrectEnabled,
                      showCorrectCount: _showCorrectCount,
                      onCorrectIndicesChanged: (v) => setState(() {
                        _correctIndices = v;
                        _isDirty = true;
                      }),
                      onMultipleCorrectChanged: (v) => setState(() {
                        _multipleCorrectEnabled = v;
                        if (!v && _correctIndices.length > 1) {
                          _correctIndices = {_correctIndices.first};
                        }
                        _isDirty = true;
                      }),
                      onShowCorrectCountChanged: (v) => setState(() {
                        _showCorrectCount = v;
                        _isDirty = true;
                      }),
                      onAddOption: () {
                        final c = TextEditingController();
                        c.addListener(_markDirty);
                        setState(() => _optionControllers.add(c));
                      },
                      onRemoveOption: (i) => setState(() {
                        _optionControllers.removeAt(i).dispose();
                        _correctIndices = _correctIndices
                            .where((idx) => idx != i)
                            .map((idx) => idx > i ? idx - 1 : idx)
                            .toSet();
                        if (_correctIndices.isEmpty) _correctIndices = {0};
                        _isDirty = true;
                      }),
                    ),

                  if (_answerType == 'imageClick')
                    ImageClickSection(
                      pickerKey: _pickerKey,
                      imagePath: _imagePath,
                      selectedImageAreas: _selectedImageAreas,
                      onImageChanged: (path) => setState(() {
                        _imagePath = path;
                        _selectedImageAreas = [];
                        _isDirty = true;
                      }),
                      onAreasChanged: (areas) => setState(() {
                        _selectedImageAreas = areas;
                        _isDirty = true;
                      }),
                    ),

                  if (_answerType == 'typed')
                    TypedAnswerSection(
                      controllers: _acceptedAnswerControllers,
                      onAddVariant: () {
                        final c = TextEditingController();
                        c.addListener(_markDirty);
                        setState(() => _acceptedAnswerControllers.add(c));
                      },
                      onRemoveVariant: (index) => setState(() {
                        _acceptedAnswerControllers.removeAt(index).dispose();
                        _isDirty = true;
                      }),
                    ),

                  if (_answerType == 'flashcard')
                    FlashcardSection(
                      randomizeSides: _flashcardRandomizeSides,
                      onRandomizeChanged: (v) => setState(() {
                        _flashcardRandomizeSides = v;
                        _isDirty = true;
                      }),
                      frontTextController: _flashcardFrontTextController,
                      backTextController: _flashcardBackTextController,
                      frontImagePath: _flashcardFrontImagePath,
                      backImagePath: _flashcardBackImagePath,
                      frontPickerKey: _flashcardFrontPickerKey,
                      backPickerKey: _flashcardBackPickerKey,
                      onFrontImageChanged: (path) => setState(() {
                        _flashcardFrontImagePath = path;
                        _isDirty = true;
                      }),
                      onBackImageChanged: (path) => setState(() {
                        _flashcardBackImagePath = path;
                        _isDirty = true;
                      }),
                    ),

                  if (_answerType == 'sorting')
                    SortingSection(
                      itemControllers: _sortingControllers,
                      showPreFilled: _sortingShowPreFilled,
                      onShowPreFilledChanged: (v) => setState(() {
                        _sortingShowPreFilled = v;
                        _isDirty = true;
                      }),
                      onAddItem: () {
                        final c = TextEditingController();
                        c.addListener(_markDirty);
                        setState(() => _sortingControllers.add(c));
                      },
                      onRemoveItem: (i) => setState(() {
                        _sortingControllers.removeAt(i).dispose();
                        _isDirty = true;
                      }),
                    ),

                  if (_answerType != 'imageClick' && _answerType != 'flashcard') ...[
                    const SizedBox(height: 8),
                    ImagePickerField(
                      key: _pickerKey,
                      label: l10n.questionImageOptional,
                      initialPath: _imagePath,
                      onChanged: (path) => setState(() {
                        _imagePath = path;
                        _isDirty = true;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _explanationController,
                    decoration: InputDecoration(
                      labelText: l10n.explanationOptional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(widget.isEditing ? l10n.saveChanges : l10n.saveQuestion),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final questionText = _questionController.text.trim();

    final String answerConfig;
    String? savedImagePath;

    if (_answerType == 'multipleChoice') {
      if (_correctIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.selectAtLeastOneCorrect)));
        return;
      }
      savedImagePath = await _pickerKey.currentState
          ?.applyAutoName('question_$questionText') ?? _imagePath;
      answerConfig = jsonEncode({
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndices': _correctIndices.toList(),
        'scrambleOptions': true,
        if (_multipleCorrectEnabled) 'multipleCorrect': true,
        if (_showCorrectCount) 'showCorrectCount': true,
      });
    } else if (_answerType == 'imageClick') {
      savedImagePath = await _pickerKey.currentState
          ?.applyAutoName('question_$questionText') ?? _imagePath;
      if (_selectedImageAreas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pleaseDefineClickArea)));
        return;
      }
      answerConfig = jsonEncode(
          ImageClickConfig(correctAreas: _selectedImageAreas).toJson());
    } else if (_answerType == 'flashcard') {
      final frontText = _flashcardFrontTextController.text.trim();
      final backText = _flashcardBackTextController.text.trim();
      final frontImagePath = await _flashcardFrontPickerKey.currentState
          ?.applyAutoName('question_${questionText}_front')
          ?? _flashcardFrontImagePath;
      final backImagePath = await _flashcardBackPickerKey.currentState
          ?.applyAutoName('question_${questionText}_back')
          ?? _flashcardBackImagePath;

      if (frontText.isEmpty && (frontImagePath == null || frontImagePath.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.flashcardFrontRequired)));
        return;
      }
      if (backText.isEmpty && (backImagePath == null || backImagePath.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.flashcardBackRequired)));
        return;
      }

      savedImagePath = null;
      answerConfig = jsonEncode(FlashcardConfig(
        frontText: frontText.isEmpty ? null : frontText,
        frontImagePath: frontImagePath,
        backText: backText.isEmpty ? null : backText,
        backImagePath: backImagePath,
        randomizeSides: _flashcardRandomizeSides,
      ).toJson());
    } else if (_answerType == 'sorting') {
      savedImagePath = await _pickerKey.currentState
          ?.applyAutoName('question_$questionText') ?? _imagePath;
      answerConfig = jsonEncode(SortingConfig(
        items: _sortingControllers.map((c) => c.text.trim()).toList(),
        showPreFilled: _sortingShowPreFilled,
      ).toJson());
    } else {
      savedImagePath = await _pickerKey.currentState
          ?.applyAutoName('question_$questionText') ?? _imagePath;
      answerConfig = jsonEncode({
        'acceptedAnswers': _acceptedAnswerControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      });
    }

    final explanation = _explanationController.text.trim();
    final companion = QuestionsCompanion(
      questionText: Value(questionText),
      answerType: Value(_answerType),
      answerConfig: Value(answerConfig),
      explanation: Value(explanation.isEmpty ? null : explanation),
      imagePath: Value(savedImagePath),
    );

    if (widget.isEditing) {
      await (widget.db.update(widget.db.questions)
        ..where((t) => t.id.equals(widget.question!.id)))
          .write(companion);
    } else {
      await widget.db.insertQuestionIntoQuiz(
        quizId: widget.quizId,
        question: QuestionsCompanion(
          questionText: Value(questionText),
          answerType: Value(_answerType),
          answerConfig: Value(answerConfig),
          explanation: Value(explanation.isEmpty ? null : explanation),
          imagePath: Value(savedImagePath),
        ),
      );
    }

    await QuestionService().refresh();
    if (mounted) Navigator.pop(context);
  }
}
