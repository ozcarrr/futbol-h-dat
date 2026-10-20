class Player {
  final String id;
  final String name;
  final String nationality;
  final int age;
  final String position;
  final String initialTeam;
  final String currentTeam;
  final String imageUrl;

  const Player({
    required this.id,
    required this.name,
    required this.nationality,
    required this.age,
    required this.position,
    required this.initialTeam,
    required this.currentTeam,
    required this.imageUrl,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    int parsedAge = 0;
    if (json['age'] != null) {
      if (json['age'] is int) {
        parsedAge = json['age'] as int;
      } else {
        parsedAge = int.tryParse(json['age'].toString()) ?? 0;
      }
    } else if (json['dateBorn'] != null) {
      try {
        final birthDate = DateTime.parse(json['dateBorn'].toString());
        final now = DateTime.now();
        parsedAge = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          parsedAge--;
        }
      } catch (_) {
        parsedAge = 0;
      }
    }

    return Player(
      id: json['id']?.toString() ?? json['idPlayer']?.toString() ?? '',
      name: json['name']?.toString() ?? json['strPlayer']?.toString() ?? '',
      nationality: json['nationality']?.toString() ??
          json['strNationality']?.toString() ??
          '',
      age: parsedAge,
      position: json['position']?.toString() ??
          json['strPosition']?.toString() ??
          '',
      initialTeam: json['initialTeam']?.toString() ?? '',
      currentTeam: json['currentTeam']?.toString() ??
          json['strTeam']?.toString() ??
          '',
      imageUrl: json['imageUrl']?.toString() ??
          json['strCutout']?.toString() ??
          json['strThumb']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality,
      'age': age,
      'position': position,
      'initialTeam': initialTeam,
      'currentTeam': currentTeam,
      'imageUrl': imageUrl,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? nationality,
    int? age,
    String? position,
    String? initialTeam,
    String? currentTeam,
    String? imageUrl,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      position: position ?? this.position,
      initialTeam: initialTeam ?? this.initialTeam,
      currentTeam: currentTeam ?? this.currentTeam,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Player(id: $id, name: $name, nationality: $nationality, age: $age, position: $position, initialTeam: $initialTeam, currentTeam: $currentTeam)';
  }
}
