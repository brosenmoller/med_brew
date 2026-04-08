import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/models/answer_configs.dart';
import 'package:med_brew/screens/manage_content_screens/image_area_selector_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';

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
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late String _answerType;
  late String? _imagePath;

  // Multiple choice
  late final List<TextEditingController> _optionControllers;
  late int _correctIndex;

  // Typed
  late final List<TextEditingController> _acceptedAnswerControllers;

  // Image click — list of polygons in normalized (0–1) coordinates
  List<List<Offset>> _selectedImageAreas = [];

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
    } else {
      // Add mode defaults
      _optionControllers =
          List.generate(4, (_) => TextEditingController());
      _correctIndex = 0;
      _acceptedAnswerControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) c.dispose();
    for (final c in _acceptedAnswerControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    label: Text('Multiple Choice'),
                    icon: Icon(Icons.list)),
                ButtonSegment(
                    value: 'typed',
                    label: Text('Typed'),
                    icon: Icon(Icons.keyboard)),
                ButtonSegment(
                    value: 'imageClick',
                    label: Text('Image Click'),
                    icon: Icon(Icons.mouse_rounded)),
              ],
              selected: {_answerType},
              onSelectionChanged: (s) =>
                  setState(() => _answerType = s.first),
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
                      onChanged: (v) =>
                          setState(() => _correctIndex = v!),
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
                      setState(() => _selectedImageAreas = result);
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
                          onPressed: () => setState(() =>
                              _acceptedAnswerControllers.removeAt(e.key).dispose()),
                        ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _acceptedAnswerControllers
                    .add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add variant'),
              ),
            ],

            if (_answerType != 'imageClick') ...[
              const SizedBox(height: 8),
              ImagePickerField(
                key: _pickerKey,
                label: 'Question image (optional)',
                initialPath: _imagePath,
                onChanged: (path) => setState(() => _imagePath = path),
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final questionText = _questionController.text.trim();
    final imagePath = await _pickerKey.currentState
        ?.applyAutoName('question_$questionText') ?? _imagePath;

    final String answerConfig;
    if (_answerType == 'multipleChoice') {
      answerConfig = jsonEncode({
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndex': _correctIndex,
        'scrambleOptions': true,
      });
    } else if (_answerType == 'imageClick') {
      if (_selectedImageAreas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please define at least one click area')));
        return;
      }
      answerConfig = jsonEncode(
          ImageClickConfig(correctAreas: _selectedImageAreas).toJson());
    } else {
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
      imagePath: Value(imagePath),
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
          imagePath: Value(imagePath),
        ),
      );
    }

    await QuestionService().refresh();
    if (mounted) Navigator.pop(context);
  }
}
