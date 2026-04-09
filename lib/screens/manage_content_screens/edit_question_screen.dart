import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// True whenever there is unsaved state — mirrors the _hasChanges pattern
  /// from ImageAreaSelectorScreen so the guard always reflects real intent.
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

    // Attach dirty listeners after initial values are set so they only fire
    // on actual user edits.
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
    return UnsavedChangesGuard(
      hasChanges: _hasChanges, // ← uses getter, not raw _isDirty
      message: 'Your question changes will be lost.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Question' : 'Add Question'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'multipleChoice',
                      label: Text('Multiple\nChoice'),
                      icon: Icon(Icons.list)),
                  ButtonSegment(
                      value: 'typed',
                      label: Text('Typed'),
                      icon: Icon(Icons.keyboard)),
                  ButtonSegment(
                      value: 'imageClick',
                      label: Text('Image\nClick'),
                      icon: Icon(Icons.mouse_rounded)),
                  ButtonSegment(
                      value: 'flashcard',
                      label: Text('Flashcard'),
                      icon: Icon(Icons.style_outlined)),
                ],
                selected: {_answerType},
                onSelectionChanged: (s) => setState(() {
                  _answerType = s.first;
                  _isDirty = true;
                }),
              ),
              const SizedBox(height: 16),

              if (_answerType == 'multipleChoice') ...[
                const Text('Options',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                            labelText: 'Option ${i + 1}',
                            border: const OutlineInputBorder(),
                            fillColor: _correctIndex == i
                                ? Colors.green.withOpacity(0.1)
                                : null,
                            filled: _correctIndex == i,
                          ),
                          validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                )),
                Text('Radio button = correct answer',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.green)),
              ],

              if (_answerType == 'imageClick') ...[
                ImagePickerField(
                  key: _pickerKey,
                  label: 'Click area image',
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
                          ? 'Define Click Areas'
                          : 'Edit Click Areas (${_selectedImageAreas.length} area${_selectedImageAreas.length == 1 ? '' : 's'})',
                    ),
                  ),
                if (_selectedImageAreas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_selectedImageAreas.length} area${_selectedImageAreas.length == 1 ? '' : 's'} defined ✓',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
              ],

              if (_answerType == 'typed') ...[
                const Text('Accepted Answers',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                              labelText: 'Accepted answer ${e.key + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                            e.key == 0 && v!.trim().isEmpty
                                ? 'At least one required'
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
                  label: const Text('Add variant'),
                ),
              ],

              if (_answerType == 'flashcard') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Randomize front/back sides'),
                  subtitle: const Text(
                      'Each attempt randomly picks which side to show first'),
                  value: _flashcardRandomizeSides,
                  onChanged: (v) => setState(() {
                    _flashcardRandomizeSides = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 8),
                _FlashcardSideEditor(
                  sideLabel: 'Front',
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
                  sideLabel: 'Back',
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
                  label: 'Question image (optional)',
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
                decoration: const InputDecoration(
                  labelText: 'Explanation (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(widget.isEditing ? 'Save Changes' : 'Save Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please define at least one click area')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Front side needs at least text or an image')));
        return;
      }
      if (backText.isEmpty && (backImagePath == null || backImagePath.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Back side needs at least text or an image')));
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

class _FlashcardSideEditor extends StatelessWidget {
  final String sideLabel;
  final TextEditingController textController;
  final String? imagePath;
  final GlobalKey<ImagePickerFieldState> pickerKey;
  final ValueChanged<String?> onImageChanged;

  const _FlashcardSideEditor({
    required this.sideLabel,
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
          '$sideLabel side',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: textController,
          decoration: InputDecoration(
            labelText: '$sideLabel text (optional)',
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        ImagePickerField(
          key: pickerKey,
          label: '$sideLabel image (optional)',
          initialPath: imagePath,
          onChanged: onImageChanged,
        ),
      ],
    );
  }
}