import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/custom_challenge_model.dart';
import 'package:futbole/models/player_model.dart';
import 'package:futbole/models/team_model.dart';
import 'package:futbole/providers/game_provider.dart';
import 'package:futbole/screens/guess_player_screen.dart';
import 'package:futbole/screens/guess_team_screen.dart';
import 'package:futbole/screens/home_screen.dart';
import 'package:futbole/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameProvider State Management', () {
    late StorageService storageService;
    late GameProvider gameProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      gameProvider = GameProvider(storageService: storageService);
      await gameProvider.loadInitialState();
    });

    test('initial state is loaded and empty', () {
      expect(gameProvider.isLoading, false);
      expect(gameProvider.recordsMap.isEmpty, true);
      expect(gameProvider.statistics['totalPlayed'], 0);
      expect(gameProvider.customChallenges.isEmpty, true);
    });

    test('recordChallengeAttempt updates state and notifies listeners', () async {
      int notifications = 0;
      gameProvider.addListener(() {
        notifications++;
      });

      await gameProvider.recordChallengeAttempt(
        challengeId: 'p1',
        type: 'player',
        won: true,
        attemptsUsed: 3,
      );

      expect(notifications, greaterThanOrEqualTo(1));
      expect(gameProvider.isCompleted('p1'), true);
      expect(gameProvider.getRecord('p1'), isNotNull);
      expect(gameProvider.getRecord('p1')!.won, true);
      expect(gameProvider.getRecord('p1')!.attemptsUsed, 3);
      expect(gameProvider.statistics['totalPlayed'], 1);
      expect(gameProvider.statistics['wins'], 1);
    });

    test('resetAllProgress clears records and notifies listeners', () async {
      await gameProvider.recordChallengeAttempt(
        challengeId: 't1',
        type: 'team',
        won: false,
        attemptsUsed: 5,
      );
      expect(gameProvider.isCompleted('t1'), true);

      int resetNotifications = 0;
      gameProvider.addListener(() {
        resetNotifications++;
      });

      await gameProvider.resetAllProgress();

      expect(resetNotifications, greaterThanOrEqualTo(1));
      expect(gameProvider.isCompleted('t1'), false);
      expect(gameProvider.statistics['totalPlayed'], 0);
      expect(gameProvider.statistics['wins'], 0);
    });

    test('custom challenge CRUD manages list and notifies listeners', () async {
      int notifications = 0;
      gameProvider.addListener(() {
        notifications++;
      });

      final challenge = CustomChallenge(
        id: 'c1',
        title: 'Goleador Histórico',
        description: '¿Quién es el máximo goleador de la selección chilena?',
        answer: 'Alexis Sánchez',
        category: 'player',
      );

      await gameProvider.addCustomChallenge(challenge);
      expect(notifications, 1);
      expect(gameProvider.customChallenges.length, 1);
      expect(gameProvider.customChallenges.first.title, 'Goleador Histórico');

      final updated = challenge.copyWith(title: 'Goleador Rojo');
      await gameProvider.updateCustomChallenge(updated);
      expect(notifications, 2);
      expect(gameProvider.customChallenges.first.title, 'Goleador Rojo');

      await gameProvider.deleteCustomChallenge('c1');
      expect(notifications, 3);
      expect(gameProvider.customChallenges.isEmpty, true);
    });
  });

  group('FutureBuilder & Hero Widgets Integration', () {
    late StorageService storageService;
    late GameProvider gameProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      gameProvider = GameProvider(storageService: storageService);
      await gameProvider.loadInitialState();
    });

    testWidgets(
        'HomeScreen renders FutureBuilder and Hero widgets for challenges',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify FutureBuilder is present in HomeScreen
      expect(find.byType(FutureBuilder<FootballData>), findsOneWidget);

      // Settle async future
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify Hero widgets exist for players in player tab
      expect(find.byType(Hero), findsWidgets);
      final playerHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'player_hero_p1',
      );
      expect(playerHero, findsOneWidget);

      // Switch to Equipos tab and verify team Hero widget
      await tester.tap(find.text('Adivinar Equipo'));
      await tester.pumpAndSettle();

      final teamHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'team_hero_t1',
      );
      expect(teamHero, findsOneWidget);
    });

    testWidgets('GuessPlayerScreen contains matching player_hero Hero tag',
        (tester) async {
      const testPlayer = Player(
        id: 'p1',
        name: 'Alexis Sánchez',
        nationality: 'Chile',
        age: 35,
        position: 'Forward',
        initialTeam: 'Cobreloa',
        currentTeam: 'Udinese',
        imageUrl: '',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: GuessPlayerScreen(
              player: testPlayer,
              allPlayers: [testPlayer],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'player_hero_p1',
      );
      expect(heroFinder, findsOneWidget);
    });

    testWidgets('GuessTeamScreen contains matching team_hero Hero tag',
        (tester) async {
      const testTeam = Team(
        id: 't1',
        name: 'Colo-Colo',
        country: 'Chile',
        league: 'Primera División de Chile',
        logoUrl: 'https://r2.thesportsdb.com/images/media/team/badge/s41be31578347962.png',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: GuessTeamScreen(
              team: testTeam,
              allTeams: [testTeam],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'team_hero_t1',
      );
      expect(heroFinder, findsOneWidget);
    });
  });
}
