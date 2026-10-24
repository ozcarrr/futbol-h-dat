class CustomChallenge {
  final String id;
  final String title;
  final String description;
  final String answer;
  final String category; // 'player', 'team', or 'trivia'
  final DateTime createdAt;

  CustomChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.answer,
    this.category = 'trivia',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomChallenge.fromJson(Map<String, dynamic> json) {
    return CustomChallenge(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      category: json['category']?.toString() ?? 'trivia',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'answer': answer,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  CustomChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? answer,
    String? category,
    DateTime? createdAt,
  }) {
    return CustomChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
