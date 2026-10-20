class Team {
  final String id;
  final String name;
  final String country;
  final String league;
  final String logoUrl;

  const Team({
    required this.id,
    required this.name,
    required this.country,
    required this.league,
    required this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id']?.toString() ?? json['idTeam']?.toString() ?? '',
      name: json['name']?.toString() ?? json['strTeam']?.toString() ?? '',
      country: json['country']?.toString() ?? json['strCountry']?.toString() ?? '',
      league: json['league']?.toString() ?? json['strLeague']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ??
          json['strBadge']?.toString() ??
          json['strLogo']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'league': league,
      'logoUrl': logoUrl,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? country,
    String? league,
    String? logoUrl,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      league: league ?? this.league,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Team(id: $id, name: $name, country: $country, league: $league)';
  }
}
