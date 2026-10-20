import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/player_model.dart';
import 'package:futbole/screens/guess_player_screen.dart';
import 'package:futbole/services/storage_service.dart';
import 'package:futbole/widgets/clue_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const targetPlayer = Player(
    id: 'p1',
    name: 'Alexis Sánchez',
    nationality: 'Chile',
    age: 35,
    position: 'Forward',
    initialTeam: 'Cobreloa',
    currentTeam: 'Udinese',
    imageUrl: 'https://example.com/alexis.jpg',
  );

  const guessYounger = Player(
    id: 'p6',
    name: 'Kylian Mbappé',
    nationality: 'France',
    age: 25,
    position: 'Forward',
    initialTeam: 'AS Monaco',
    currentTeam: 'Real Madrid',
    imageUrl: 'https://example.com/mbappe.jpg',
  );

  const guessOlder = Player(
    id: 'p3',
    name: 'Cristiano Ronaldo',
    nationality: 'Portugal',
    age: 39,
    position: 'Forward',
    initialTeam: 'Sporting CP',
    currentTeam: 'Al-Nassr',
    imageUrl: 'https://example.com/ronaldo.jpg',
  );

  final allTestPlayers = [targetPlayer, guessYounger, guessOlder];

  group('GuessPlayerScreen Game Engine', () {
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
    });

    testWidgets('renders initial state with 0/6 attempts and position clue unlocked',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuessPlayerScreen(
            player: targetPlayer,
            allPlayers: allTestPlayers,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check attempts badge
      expect(find.text('Intentos: 0 / 6'), findsOneWidget);

      // Check starting clue (Posición) is unlocked
      expect(find.text('Forward'), findsOneWidget);

      // Other clues should be in locked state
      expect(find.text('Intento 1'), findsOneWidget);
      expect(find.text('Intento 2'), findsOneWidget);
      expect(find.text('Intento 3'), findsOneWidget);
      expect(find.text('Intento 4'), findsOneWidget);
    });

    testWidgets(
        'incorrect guess increments attempts, unlocks next clue, and shows directional age indicator',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuessPlayerScreen(
            player: targetPlayer,
            allPlayers: allTestPlayers,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Make incorrect guess: Mbappé (age 25, target is 35 -> older)
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Kylian');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kylian Mbappé'));
      await tester.pumpAndSettle();

      // Attempt incremented to 1/6
      expect(find.text('Intentos: 1 / 6'), findsOneWidget);

      // Next progressive clue (Nacionalidad: Chile) is now unlocked!
      expect(find.text('Chile'), findsWidgets);

      // PlayerGuessRow is rendered with age directional feedback
      expect(find.byType(PlayerGuessRow), findsOneWidget);
      expect(find.text('25 ↑ Mayor'), findsOneWidget);
    });

    testWidgets('correct guess triggers victory state and persists to storage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuessPlayerScreen(
            player: targetPlayer,
            allPlayers: allTestPlayers,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Make correct guess
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Alexis');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alexis Sánchez'));
      await tester.pumpAndSettle();

      // Victory banner appears
      expect(find.text('¡FELICITACIONES! ACERTASTE'), findsOneWidget);
      expect(find.text('Volver al Hub'), findsOneWidget);

      // Storage verification
      final record = await storageService.getChallengeResult('p1');
      expect(record, isNotNull);
      expect(record!.won, true);
      expect(record.attemptsUsed, 1);
    });

    testWidgets('skip clue button increments attempt and unlocks clue',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuessPlayerScreen(
            player: targetPlayer,
            allPlayers: allTestPlayers,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intentos: 0 / 6'), findsOneWidget);
      expect(find.text('Intento 1'), findsOneWidget);

      await tester.tap(find.text('Pedir Pista (+1 intento)'));
      await tester.pumpAndSettle();

      // Attempts incremented to 1/6 and Nacionalidad unlocked
      expect(find.text('Intentos: 1 / 6'), findsOneWidget);
      expect(find.text('Chile'), findsOneWidget);
    });
  });
}
