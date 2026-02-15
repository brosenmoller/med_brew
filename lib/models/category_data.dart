class CategoryData {
  final String id;
  final String title;
  final String? imagePath;
  final List<String> quizIds;

  CategoryData({
    required this.id,
    required this.title,
    this.imagePath,
    required this.quizIds,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'],
      title: json['title'],
      imagePath: json['imagePath'],
      quizIds: List<String>.from(json['quizIds'] ?? []),
    );
  }
}