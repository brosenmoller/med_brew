import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final subfolders = folder == null
        ? _service.getRootFolders()
        : _service.getSubfolders(folder!.id);

    final quizzes = _service.getQuizzesInFolder(folder?.id);

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400
        ? 2
        : screenWidth < 600
            ? 3
            : screenWidth < 900
                ? 4
                : 6;

    final isEmpty = subfolders.isEmpty && quizzes.isEmpty;

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.title ?? l10n.navBrowse),
      ),
      body: isEmpty
          ? Center(child: Text(l10n.emptyFolder))
          : CustomScrollView(
              slivers: [
                if (subfolders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.foldersSection,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                        },
                        childCount: subfolders.length,
                      ),
                      gridDelegate: gridDelegate,
                    ),
                  ),
                ],
                if (quizzes.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.quizzesSection,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final quiz = quizzes[index];
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
                        childCount: quizzes.length,
                      ),
                      gridDelegate: gridDelegate,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
