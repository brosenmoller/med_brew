import 'package:flutter/material.dart';
import 'package:med_brew/models/folder_data.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/folder_tile.dart';
import 'package:med_brew/widgets/quiz_tile.dart';

/// Browsable folder/quiz screen. Pass [folder] = null to show the root level.
class FolderBrowserScreen extends StatelessWidget {
  final FolderData? folder;

  FolderBrowserScreen({super.key, this.folder});

  final QuestionService _service = QuestionService();

  @override
  Widget build(BuildContext context) {
    final subfolders = folder == null
        ? _service.getRootFolders()
        : _service.getSubfolders(folder!.id);

    final quizzes = _service.getQuizzesInFolder(folder?.id);

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 6;

    final itemCount = subfolders.length + quizzes.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.title ?? 'Browse'),
      ),
      body: itemCount == 0
          ? const Center(child: Text('Nothing here yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                // Subfolders first, then quizzes
                if (index < subfolders.length) {
                  final sub = subfolders[index];
                  return FolderTile(
                    folder: sub,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FolderBrowserScreen(folder: sub),
                      ),
                    ),
                  );
                }
                final quiz = quizzes[index - subfolders.length];
                return QuizTile(
                  quiz: quiz,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizSessionScreen(quizData: quiz),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
