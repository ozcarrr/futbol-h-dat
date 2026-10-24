class CustomChallenge {
  final String id;
  final String? userId;
  final String title;
  final String targetName; // Nombre del jugador o club secreto
  final String category; // 'player', 'team', or 'trivia'
  final String clue1; // Pista 1 (ej: Nacionalidad / País)
  final String clue2; // Pista 2 (ej: Posición / Liga)
  final String clue3; // Pista 3 (ej: Club Actual / Época)
  final DateTime createdAt;

  CustomChallenge({
    required this.id,
    this.userId,
    required this.title,
    String? targetName,
    String? answer,
    this.category = 'trivia',
    String? clue1,
    String? clue2,
    String? clue3,
    String? description,
    DateTime? createdAt,
  })  : targetName = targetName ?? answer ?? '',
        clue1 = clue1 ?? (description ?? ''),
        clue2 = clue2 ?? '',
        clue3 = clue3 ?? '',
        createdAt = createdAt ?? DateTime.now();

  factory CustomChallenge.fromJson(Map<String, dynamic> json) {
    return CustomChallenge(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      title: json['title']?.toString() ?? '',
      targetName: json['target_name']?.toString() ??
          json['targetName']?.toString() ??
          json['answer']?.toString() ??
          '',
      category: json['category']?.toString() ?? 'trivia',
      clue1: json['clue_1']?.toString() ??
          json['clue1']?.toString() ??
          json['description']?.toString() ??
          '',
      clue2: json['clue_2']?.toString() ?? json['clue2']?.toString() ?? '',
      clue3: json['clue_3']?.toString() ?? json['clue3']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'title': title,
        'target_name': targetName,
        'category': category,
        'clue_1': clue1,
        'clue_2': clue2,
        'clue_3': clue3,
        'created_at': createdAt.toIso8601String(),
      };

  String get answer => targetName;
  String get description => clue2.isNotEmpty || clue3.isNotEmpty
      ? '$clue1 • $clue2 • $clue3'
      : clue1;

  CustomChallenge copyWith({
    String? id,
    String? userId,
    String? title,
    String? targetName,
    String? answer,
    String? category,
    String? clue1,
    String? clue2,
    String? clue3,
    String? description,
    DateTime? createdAt,
  }) {
    return CustomChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetName: targetName ?? answer ?? this.targetName,
      category: category ?? this.category,
      clue1: clue1 ?? description ?? this.clue1,
      clue2: clue2 ?? this.clue2,
      clue3: clue3 ?? this.clue3,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
