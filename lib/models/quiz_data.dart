class QuizData {
  final String id;
  final String title;
  final String? imagePath;
  final List<String> questionIds;

  QuizData({
    required this.id,
    required this.title,
    this.imagePath,
    required this.questionIds,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      id: json['id'],
      title: json['title'],
      imagePath: json['imagePath'],
      questionIds: List<String>.from(json['questionIds'] ?? []),
    );
  }
}