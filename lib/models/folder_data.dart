class FolderData {
  final String id;
  final String? parentFolderId;
  final String title;
  final String? imagePath;
  final List<String> subfolderIds;
  final List<String> quizIds;

  FolderData({
    required this.id,
    this.parentFolderId,
    required this.title,
    this.imagePath,
    required this.subfolderIds,
    required this.quizIds,
  });
}
