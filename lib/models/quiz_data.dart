class QuizData {
  final String id;
  final String? parentFolderId;
  final String title;
  final String? imagePath;
  final String? languageCode;
  final List<String> questionIds;

  QuizData({
    required this.id,
    this.parentFolderId,
    required this.title,
    this.imagePath,
    this.languageCode,
    required this.questionIds,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      id: json['id'],
      parentFolderId: json['folderId'] as String?,
      title: json['title'],
      imagePath: json['imagePath'],
      languageCode: json['languageCode'] as String?,
      questionIds: List<String>.from(json['questionIds'] ?? []),
    );
  }
}
