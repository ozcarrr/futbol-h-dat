import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/player_model.dart';
import 'package:futbole/models/team_model.dart';
import 'package:futbole/services/football_api_service.dart';
import 'package:futbole/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player and Team Models', () {
    test('Player serialization and deserialization', () {
      final json = {
        'id': 'p100',
        'name': 'Test Player',
        'nationality': 'Chile',
        'age': 28,
        'position': 'Midfielder',
        'initialTeam': 'Audax Italiano',
        'currentTeam': 'Racing',
        'imageUrl': 'https://example.com/player.png',
      };

      final player = Player.fromJson(json);
      expect(player.id, 'p100');
      expect(player.name, 'Test Player');
      expect(player.nationality, 'Chile');
      expect(player.age, 28);
      expect(player.initialTeam, 'Audax Italiano');
      expect(player.currentTeam, 'Racing');

      final serialized = player.toJson();
      expect(serialized['name'], 'Test Player');
      expect(serialized['initialTeam'], 'Audax Italiano');
    });

    test('Team serialization and deserialization', () {
      final json = {
        'id': 't100',
        'name': 'Colo-Colo',
        'country': 'Chile',
        'league': 'Primera División de Chile',
        'logoUrl': 'https://example.com/logo.png',
      };

      final team = Team.fromJson(json);
      expect(team.id, 't100');
      expect(team.name, 'Colo-Colo');
      expect(team.country, 'Chile');
      expect(team.league, 'Primera División de Chile');

      final serialized = team.toJson();
      expect(serialized['country'], 'Chile');
      expect(serialized['logoUrl'], 'https://example.com/logo.png');
    });
  });

  group('FootballApiService', () {
    late FootballApiService apiService;

    setUp(() {
      apiService = FootballApiService();
    });

    tearDown(() {
      apiService.dispose();
    });

    test('getPlayers returns 49 curated players with valid initialTeam and attributes', () async {
      final players = await apiService.getPlayers();
      expect(players.length, 49);

      for (final p in players) {
        expect(p.id.isNotEmpty, true);
        expect(p.name.isNotEmpty, true);
        expect(p.nationality.isNotEmpty, true);
        expect(p.age > 0, true);
        expect(p.position.isNotEmpty, true);
        expect(p.initialTeam.isNotEmpty, true);
        expect(p.currentTeam.isNotEmpty, true);
      }
    });

    test('getTeams returns 25 curated clubs with valid crests and attributes', () async {
      final teams = await apiService.getTeams();
      expect(teams.length, 25);

      for (final t in teams) {
        expect(t.id.isNotEmpty, true);
        expect(t.name.isNotEmpty, true);
        expect(t.country.isNotEmpty, true);
        expect(t.league.isNotEmpty, true);
        expect(t.logoUrl.startsWith('http'), true);
      }
    });

    test('fetchLiveTeamInfo fallback works seamlessly for curated club', () async {
      final result = await apiService.fetchLiveTeamInfo('Colo-Colo');
      expect(result, isNotNull);
      expect(result!['strTeam'], contains('Colo-Colo'));
      expect(result['strCountry'], 'Chile');
    });
  });

  group('StorageService', () {
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
    });

    test('records completed challenge and updates stats', () async {
      expect(await storageService.isChallengeCompleted('p1'), false);

      await storageService.saveChallengeResult(
        challengeId: 'p1',
        type: 'player',
        won: true,
        attemptsUsed: 3,
      );

      expect(await storageService.isChallengeCompleted('p1'), true);

      final record = await storageService.getChallengeResult('p1');
      expect(record, isNotNull);
      expect(record!.won, true);
      expect(record.attemptsUsed, 3);
      expect(record.type, 'player');

      await storageService.saveChallengeResult(
        challengeId: 't1',
        type: 'team',
        won: false,
        attemptsUsed: 6,
      );

      final stats = await storageService.getStatistics();
      expect(stats['totalPlayed'], 2);
      expect(stats['wins'], 1);
      expect(stats['losses'], 1);
      expect(stats['winRate'], 50.0);
    });
  });
}
