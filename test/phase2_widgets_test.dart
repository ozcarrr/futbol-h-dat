import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/player_model.dart';
import 'package:futbole/models/team_model.dart';
import 'package:futbole/screens/home_screen.dart';
import 'package:futbole/widgets/autocomplete_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPlayers = [
    Player(
      id: 'p1',
      name: 'Alexis Sánchez',
      nationality: 'Chile',
      age: 35,
      position: 'Forward',
      initialTeam: 'Cobreloa',
      currentTeam: 'Udinese',
      imageUrl: 'https://example.com/alexis.jpg',
    ),
    Player(
      id: 'p2',
      name: 'Lionel Messi',
      nationality: 'Argentina',
      age: 37,
      position: 'Forward',
      initialTeam: "Newell's Old Boys",
      currentTeam: 'Inter Miami',
      imageUrl: 'https://example.com/messi.jpg',
    ),
    Player(
      id: 'p3',
      name: 'Arturo Vidal',
      nationality: 'Chile',
      age: 37,
      position: 'Midfielder',
      initialTeam: 'Colo-Colo',
      currentTeam: 'Colo-Colo',
      imageUrl: 'https://example.com/vidal.jpg',
    ),
  ];

  const testTeams = [
    Team(
      id: 't1',
      name: 'Colo-Colo',
      country: 'Chile',
      league: 'Primera División de Chile',
      logoUrl: 'https://example.com/colocolo.png',
    ),
    Team(
      id: 't2',
      name: 'Real Madrid',
      country: 'Spain',
      league: 'La Liga',
      logoUrl: 'https://example.com/realmadrid.png',
    ),
  ];

  group('AutocompleteSearch Widget', () {
    testWidgets('filters suggestions by query and handles selection',
        (tester) async {
      Player? selectedPlayer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteSearch.forPlayers(
              players: testPlayers,
              excludedIds: const ['p3'], // Vidal excluded
              onSelected: (p) => selectedPlayer = p,
            ),
          ),
        ),
      );

      // Find the TextField and enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'alex');
      await tester.pumpAndSettle();

      // Should show 'Alexis Sánchez' but NOT 'Arturo Vidal' or 'Lionel Messi'
      expect(find.text('Alexis Sánchez'), findsOneWidget);
      expect(find.text('Lionel Messi'), findsNothing);
      expect(find.text('Arturo Vidal'), findsNothing);

      // Tap suggestion
      await tester.tap(find.text('Alexis Sánchez'));
      await tester.pumpAndSettle();

      expect(selectedPlayer, isNotNull);
      expect(selectedPlayer!.name, 'Alexis Sánchez');
    });

    testWidgets('excludes already-guessed IDs from suggestions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteSearch.forPlayers(
              players: testPlayers,
              excludedIds: const ['p1', 'p2'], // Alexis and Messi excluded
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'a');
      await tester.pumpAndSettle();

      // Alexis is excluded, so only Vidal should match 'a'
      expect(find.text('Alexis Sánchez'), findsNothing);
      expect(find.text('Arturo Vidal'), findsOneWidget);
    });

    testWidgets('supports Team suggestions', (tester) async {
      Team? selectedTeam;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteSearch.forTeams(
              teams: testTeams,
              onSelected: (t) => selectedTeam = t,
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'colo');
      await tester.pumpAndSettle();

      expect(find.text('Colo-Colo'), findsOneWidget);

      await tester.tap(find.text('Colo-Colo'));
      await tester.pumpAndSettle();

      expect(selectedTeam, isNotNull);
      expect(selectedTeam!.name, 'Colo-Colo');
    });
  });

  group('HomeScreen Challenge Hub', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders tabs, stats banner and challenge items',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Initial loading
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify branding and tabs
      expect(find.textContaining('Futbo'), findsWidgets);
      expect(find.text('Adivinar Jugador'), findsOneWidget);
      expect(find.text('Adivinar Equipo'), findsOneWidget);

      // Verify stats header
      expect(find.text('Tu Rendimiento en FutboLE'), findsOneWidget);
      expect(find.text('Reiniciar'), findsOneWidget);

      // Verify challenges list for players
      expect(find.text('Desafío Jugador #1'), findsOneWidget);
    });
  });
}
