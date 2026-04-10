import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/models/answer_configs.dart' show FlashcardConfig, ImageClickConfig, MultipleChoiceConfig, TypedAnswerConfig;
import 'package:med_brew/screens/manage_content_screens/image_area_selector_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';
import 'package:med_brew/widgets/unsaved_changes_guard.dart';

class EditQuestionScreen extends StatefulWidget {
  final int quizId;
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
  late int _correctIndex;

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
        while (_optionControllers.length < 4) {
          _optionControllers.add(TextEditingController());
        }
        _correctIndex = mc.correctIndex;
      } else {
        _optionControllers =
            List.generate(4, (_) => TextEditingController());
        _correctIndex = 0;
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
    } else {
      // Add mode defaults
      _optionControllers =
          List.generate(4, (_) => TextEditingController());
      _correctIndex = 0;
      _acceptedAnswerControllers = [TextEditingController()];
      _flashcardFrontTextController = TextEditingController();
      _flashcardBackTextController = TextEditingController();
    }

    _questionController.addListener(_markDirty);
    _explanationController.addListener(_markDirty);
    for (final c in _optionControllers) { c.addListener(_markDirty); }
    for (final c in _acceptedAnswerControllers) { c.addListener(_markDirty); }
    _flashcardFrontTextController.addListener(_markDirty);
    _flashcardBackTextController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) c.dispose();
    for (final c in _acceptedAnswerControllers) c.dispose();
    _flashcardFrontTextController.dispose();
    _flashcardBackTextController.dispose();
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
                maxLines: 2,
                validator: (v) => v!.trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 16),

              _AnswerTypeSelector(
                selected: _answerType,
                onChanged: (v) => setState(() {
                  _answerType = v;
                  _isDirty = true;
                }),
              ),
              const SizedBox(height: 16),

              if (_answerType == 'multipleChoice') ...[
                Text(l10n.optionsLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _correctIndex,
                        onChanged: (v) => setState(() {
                          _correctIndex = v!;
                          _isDirty = true;
                        }),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[i],
                          decoration: InputDecoration(
                            labelText: l10n.optionN(i + 1),
                            border: const OutlineInputBorder(),
                            fillColor: _correctIndex == i
                                ? Colors.green.withOpacity(0.1)
                                : null,
                            filled: _correctIndex == i,
                          ),
                          validator: (v) =>
                          v!.trim().isEmpty ? l10n.required : null,
                        ),
                      ),
                    ],
                  ),
                )),
                Text(l10n.radioCorrectHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.green)),
              ],

              if (_answerType == 'imageClick') ...[
                ImagePickerField(
                  key: _pickerKey,
                  label: l10n.clickAreaImageLabel,
                  initialPath: _imagePath,
                  onChanged: (path) => setState(() {
                    _imagePath = path;
                    _selectedImageAreas = [];
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 12),
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<List<List<Offset>>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageAreaSelectorScreen(
                            imagePath: _imagePath!,
                            initialAreas: _selectedImageAreas,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedImageAreas = result;
                          _isDirty = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Text(
                      _selectedImageAreas.isEmpty
                          ? l10n.defineClickAreas
                          : l10n.editClickAreas(_selectedImageAreas.length),
                    ),
                  ),
                if (_selectedImageAreas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.areasDefinedCount(_selectedImageAreas.length),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
              ],

              if (_answerType == 'typed') ...[
                Text(l10n.acceptedAnswersLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._acceptedAnswerControllers.asMap().entries.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: e.value,
                            decoration: InputDecoration(
                              labelText: l10n.acceptedAnswerN(e.key + 1),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                            e.key == 0 && v!.trim().isEmpty
                                ? l10n.atLeastOneRequired
                                : null,
                          ),
                        ),
                        if (e.key > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => setState(() {
                              _acceptedAnswerControllers.removeAt(e.key).dispose();
                              _isDirty = true;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final c = TextEditingController();
                    c.addListener(_markDirty);
                    setState(() => _acceptedAnswerControllers.add(c));
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addVariant),
                ),
              ],

              if (_answerType == 'flashcard') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.flashcardRandomize),
                  subtitle: Text(l10n.flashcardRandomizeSubtitle),
                  value: _flashcardRandomizeSides,
                  onChanged: (v) => setState(() {
                    _flashcardRandomizeSides = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 8),
                _FlashcardSideEditor(
                  headerLabel: l10n.flashcardFrontSide,
                  textOptionalLabel: l10n.flashcardFrontTextOptional,
                  imageOptionalLabel: l10n.flashcardFrontImageOptional,
                  textController: _flashcardFrontTextController,
                  imagePath: _flashcardFrontImagePath,
                  pickerKey: _flashcardFrontPickerKey,
                  onImageChanged: (path) => setState(() {
                    _flashcardFrontImagePath = path;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 16),
                _FlashcardSideEditor(
                  headerLabel: l10n.flashcardBackSide,
                  textOptionalLabel: l10n.flashcardBackTextOptional,
                  imageOptionalLabel: l10n.flashcardBackImageOptional,
                  textController: _flashcardBackTextController,
                  imagePath: _flashcardBackImagePath,
                  pickerKey: _flashcardBackPickerKey,
                  onImageChanged: (path) => setState(() {
                    _flashcardBackImagePath = path;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 16),
              ],

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
      savedImagePath = await _pickerKey.currentState
          ?.applyAutoName('question_$questionText') ?? _imagePath;
      answerConfig = jsonEncode({
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndex': _correctIndex,
        'scrambleOptions': true,
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
        question: QuestionsCompanion.insert(
          questionText: questionText,
          answerType: _answerType,
          answerConfig: answerConfig,
          explanation: Value(explanation.isEmpty ? null : explanation),
          imagePath: Value(savedImagePath),
        ),
      );
    }

    await QuestionService().refresh();
    if (mounted) Navigator.pop(context);
  }
}

// ── Answer type selector ──────────────────────────────────────────────────────

class _AnswerTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AnswerTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final answerTypes = [
      (value: 'multipleChoice', label: l10n.answerTypeMCLabel,         icon: Icons.list),
      (value: 'typed',          label: l10n.answerTypeTypedLabel,       icon: Icons.keyboard),
      (value: 'imageClick',     label: l10n.answerTypeImageClickLabel,  icon: Icons.mouse_rounded),
      (value: 'flashcard',      label: l10n.answerTypeFlashcardLabel,   icon: Icons.style_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 500) {
          return SegmentedButton<String>(
            segments: answerTypes
                .map((t) => ButtonSegment<String>(
                      value: t.value,
                      label: Text(t.label),
                      icon: Icon(t.icon),
                    ))
                .toList(),
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
          );
        }

        return DropdownButtonFormField<String>(
          value: selected,
          decoration: InputDecoration(
            labelText: l10n.answerTypeLabel,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: false,
          ),
          onChanged: (v) { if (v != null) onChanged(v); },
          items: answerTypes
              .map((t) => DropdownMenuItem(
                    value: t.value,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  ))
                  .toList(),
        );
      },
    );
  }
}

class _FlashcardSideEditor extends StatelessWidget {
  final String headerLabel;
  final String textOptionalLabel;
  final String imageOptionalLabel;
  final TextEditingController textController;
  final String? imagePath;
  final GlobalKey<ImagePickerFieldState> pickerKey;
  final ValueChanged<String?> onImageChanged;

  const _FlashcardSideEditor({
    required this.headerLabel,
    required this.textOptionalLabel,
    required this.imageOptionalLabel,
    required this.textController,
    required this.imagePath,
    required this.pickerKey,
    required this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: textController,
          decoration: InputDecoration(
            labelText: textOptionalLabel,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        ImagePickerField(
          key: pickerKey,
          label: imageOptionalLabel,
          initialPath: imagePath,
          onChanged: onImageChanged,
        ),
      ],
    );
  }
}
