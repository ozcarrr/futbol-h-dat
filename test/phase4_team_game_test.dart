import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/team_model.dart';
import 'package:futbole/screens/guess_team_screen.dart';
import 'package:futbole/services/storage_service.dart';
import 'package:futbole/widgets/clue_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const targetTeam = Team(
    id: 't1',
    name: 'Colo-Colo',
    country: 'Chile',
    league: 'Primera División de Chile',
    logoUrl: 'https://example.com/colocolo.png',
  );

  const guessIncorrectTeam = Team(
    id: 't4',
    name: 'Real Madrid',
    country: 'Spain',
    league: 'La Liga',
    logoUrl: 'https://example.com/realmadrid.png',
  );

  const guessSameCountryTeam = Team(
    id: 't2',
    name: 'Universidad de Chile',
    country: 'Chile',
    league: 'Primera División de Chile',
    logoUrl: 'https://example.com/udechile.png',
  );

  final allTestTeams = [targetTeam, guessIncorrectTeam, guessSameCountryTeam];

  group('GuessTeamScreen Game Engine', () {
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
    });

    testWidgets(
        'renders initial state with 0/5 attempts, 4.2x zoom, and locked clues',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GuessTeamScreen(
            team: targetTeam,
            allTeams: allTestTeams,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempts counter
      expect(find.text('Intentos: 0 / 5'), findsOneWidget);

      // Initial high zoom indicator
      expect(find.textContaining('4.2x'), findsOneWidget);

      // Clues locked
      expect(find.text('Desbloquea en intento 2'), findsOneWidget);
      expect(find.text('Desbloquea en intento 3'), findsOneWidget);
    });

    testWidgets(
        'incorrect guess increments attempts to 1/5, reduces zoom to 3.1x, and renders TeamGuessRow',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GuessTeamScreen(
            team: targetTeam,
            allTeams: allTestTeams,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit incorrect guess: Real Madrid
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Real');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Real Madrid'));
      await tester.pumpAndSettle();

      // Attempt incremented
      expect(find.text('Intentos: 1 / 5'), findsOneWidget);

      // Zoom reduced to 3.1x
      expect(find.textContaining('3.1x'), findsOneWidget);

      // Guess row rendered
      expect(find.byType(TeamGuessRow), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TeamGuessRow),
          matching: find.text('Real Madrid'),
        ),
        findsOneWidget,
      );
      expect(find.text('Spain'), findsOneWidget);
      expect(find.text('La Liga'), findsOneWidget);
    });

    testWidgets(
        'Alejar Zoom skip button increments attempt and unlocks country at attempt 2',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GuessTeamScreen(
            team: targetTeam,
            allTeams: allTestTeams,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final skipButton = find.text('Alejar Zoom (+1 intento)');

      // Tap 1: attempt 1, zoom 3.1x
      await tester.tap(skipButton);
      await tester.pumpAndSettle();
      expect(find.text('Intentos: 1 / 5'), findsOneWidget);
      expect(find.textContaining('3.1x'), findsOneWidget);

      // Tap 2: attempt 2, zoom 2.3x and País is unlocked!
      await tester.tap(skipButton);
      await tester.pumpAndSettle();
      expect(find.text('Intentos: 2 / 5'), findsOneWidget);
      expect(find.textContaining('2.3x'), findsOneWidget);
      expect(find.text('Chile'), findsOneWidget);
    });

    testWidgets(
        'correct guess sets zoom to 1.0x, triggers victory, and saves to storage',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GuessTeamScreen(
            team: targetTeam,
            allTeams: allTestTeams,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit correct guess
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Colo');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Colo-Colo'));
      await tester.pumpAndSettle();

      // Zoom is 1.0x (fully revealed)
      expect(find.textContaining('1.0x'), findsOneWidget);

      // Victory banner appears
      expect(find.text('¡FELICITACIONES! ACERTASTE'), findsOneWidget);
      expect(find.text('Volver al Hub'), findsOneWidget);

      // Storage verification
      final record = await storageService.getChallengeResult('t1');
      expect(record, isNotNull);
      expect(record!.won, true);
      expect(record.attemptsUsed, 1);
      expect(record.type, 'team');
    });
  });
}
