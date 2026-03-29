import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/models/answer_configs.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_area_selector.dart';

class AddQuestionScreen extends StatefulWidget {
  final int quizId;
  final AppDatabase db;

  const AddQuestionScreen({super.key, required this.quizId, required this.db});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _imagePathController = TextEditingController();

  String _answerType = 'multipleChoice';
  Rect? _selectedImageRect;
  String? _imageClickImagePath;

  // Multiple choice state
  final List<TextEditingController> _optionControllers =
  List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  // Typed answer state
  final List<TextEditingController> _acceptedAnswerControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _imagePathController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    for (final c in _acceptedAnswerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Question')),
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

            // Answer type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'multipleChoice',
                  label: Text('Multiple Choice'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: 'typed',
                  label: Text('Typed'),
                  icon: Icon(Icons.keyboard),
                ),
                ButtonSegment(
                    value: 'imageClick',
                    label: Text('Image Click'),
                    icon: Icon(Icons.mouse_rounded)
                ),
              ],
              selected: {_answerType},
              onSelectionChanged: (s) =>
                  setState(() => _answerType = s.first),
            ),
            const SizedBox(height: 16),

            if (_answerType == 'multipleChoice') ...[
              const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                          // Highlight the correct answer
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
              Text(
                'Radio button = correct answer',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.green),
              ),
            ],

            if (_answerType == 'imageClick') ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Image path',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _imageClickImagePath = v.trim()),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_imageClickImagePath != null && _imageClickImagePath!.isNotEmpty)
                ImageAreaSelector(
                  imagePath: _imageClickImagePath!,
                  initialRect: _selectedImageRect,
                  onRectSelected: (rect) => setState(() => _selectedImageRect = rect),
                ),
              if (_selectedImageRect != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Area selected ✓',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],

            if (_answerType == 'typed') ...[
              const Text('Accepted Answers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._acceptedAnswerControllers.asMap().entries.map((e) => Padding(
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
                            ? 'At least one answer required'
                            : null,
                      ),
                    ),
                    if (e.key > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () => setState(() =>
                            _acceptedAnswerControllers.removeAt(e.key)),
                      ),
                  ],
                ),
              )),
              TextButton.icon(
                onPressed: () => setState(() => _acceptedAnswerControllers
                    .add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add accepted answer variant'),
              ),
            ],

            TextFormField(
              controller: _imagePathController,
              decoration: const InputDecoration(
                labelText: 'Question image path (optional)',
                hintText: 'assets/images/...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

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
              label: const Text('Save Question'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String answerConfig;
    if (_answerType == 'multipleChoice') {
      answerConfig = jsonEncode({
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndex': _correctIndex,
      });
    } else if (_answerType == 'imageClick') {
      if (_selectedImageRect == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an area on the image')),
        );
        return;
      }
      answerConfig = jsonEncode(ImageClickConfig(
        correctArea: _selectedImageRect!,
      ).toJson());
    } else {
      answerConfig = jsonEncode({
        'acceptedAnswers': _acceptedAnswerControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      });
    }

    await widget.db.insertQuestionIntoQuiz(
      quizId: widget.quizId,
      question: QuestionsCompanion.insert(
        questionText: _questionController.text.trim(),
        answerType: _answerType,
        answerConfig: answerConfig,
        explanation: Value(_explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim()),
        imagePath: Value(_imagePathController.text.trim().isEmpty
            ? null
            : _imagePathController.text.trim()),
      ),
    );

    await QuestionService().refresh();
    if (mounted) Navigator.pop(context);
  }
}