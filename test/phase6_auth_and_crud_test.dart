import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futbole/models/custom_challenge_model.dart';
import 'package:futbole/providers/game_provider.dart';
import 'package:futbole/screens/auth_screen.dart';
import 'package:futbole/screens/custom_challenge_form_dialog.dart';
import 'package:futbole/screens/home_screen.dart';
import 'package:futbole/services/storage_service.dart';
import 'package:futbole/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 — AuthScreen Form Validation', () {
    late StorageService storageService;
    late SupabaseService supabaseService;
    late GameProvider gameProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      supabaseService = SupabaseService();
      gameProvider = GameProvider(
        storageService: storageService,
        supabaseService: supabaseService,
      );
      await gameProvider.loadInitialState();
    });

    testWidgets('shows validation errors on empty submission', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      // Tap submit without typing anything
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('shows validation errors on invalid email and short password',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'correo_invalido');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), '123');

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(
          find.text('Ingresa un correo electrónico válido (ej: usuario@correo.cl)'),
          findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres'),
          findsOneWidget);
    });

    testWidgets('quick demo button authenticates user and updates provider',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('auth_demo_button')));
      await tester.pumpAndSettle();

      expect(gameProvider.isAuthenticated, true);
      expect(gameProvider.currentUserEmail, 'demo.futbol@udd.cl');
    });
  });

  group('Phase 6 — CustomChallengeFormDialog Form Validation & CRUD', () {
    late StorageService storageService;
    late SupabaseService supabaseService;
    late GameProvider gameProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      supabaseService = SupabaseService();
      gameProvider = GameProvider(
        storageService: storageService,
        supabaseService: supabaseService,
      );
      await gameProvider.loadInitialState();
    });

    testWidgets('validates required fields on create challenge submission',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomChallengeFormDialog(),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('challenge_save_button')));
      await tester.tap(find.byKey(const Key('challenge_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('El título es obligatorio'), findsOneWidget);
      expect(find.text('El nombre secreto es obligatorio'), findsOneWidget);
      expect(find.text('La pista 1 es requerida'), findsOneWidget);
      expect(find.text('La pista 2 es requerida'), findsOneWidget);
      expect(find.text('La pista 3 es requerida'), findsOneWidget);
    });

    testWidgets('creates a valid challenge and adds to GameProvider',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomChallengeFormDialog(),
            ),
          ),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('challenge_title_field')), 'El Matador');
      await tester.enterText(
          find.byKey(const Key('challenge_target_name_field')), 'Marcelo Salas');
      await tester.enterText(
          find.byKey(const Key('challenge_clue1_field')), 'Chile');
      await tester.enterText(
          find.byKey(const Key('challenge_clue2_field')), 'Delantero Histórico');
      await tester.enterText(
          find.byKey(const Key('challenge_clue3_field')), 'River Plate / Lazio');

      await tester.ensureVisible(find.byKey(const Key('challenge_save_button')));
      await tester.tap(find.byKey(const Key('challenge_save_button')));
      await tester.pumpAndSettle();

      expect(gameProvider.customChallenges.length, 1);
      final created = gameProvider.customChallenges.first;
      expect(created.title, 'El Matador');
      expect(created.targetName, 'Marcelo Salas');
      expect(created.clue1, 'Chile');
      expect(created.clue2, 'Delantero Histórico');
      expect(created.clue3, 'River Plate / Lazio');
    });

    testWidgets('detail dialog renders secret and clues properly',
        (tester) async {
      final challenge = CustomChallenge(
        id: 'test_c1',
        title: 'El Mago',
        targetName: 'Jorge Valdivia',
        clue1: 'Chile',
        clue2: 'Mediocampista Creativo',
        clue3: 'Colo-Colo / Palmeiras',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomChallengeDetailDialog(challenge: challenge),
          ),
        ),
      );

      expect(find.text('El Mago'), findsOneWidget);
      expect(find.text('Jorge Valdivia'), findsOneWidget);
      expect(find.text('Chile'), findsOneWidget);
      expect(find.text('Mediocampista Creativo'), findsOneWidget);
      expect(find.text('Colo-Colo / Palmeiras'), findsOneWidget);
    });
  });

  group('Phase 6 — HomeScreen 3 Tabs & CRUD Integration', () {
    late StorageService storageService;
    late SupabaseService supabaseService;
    late GameProvider gameProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      supabaseService = SupabaseService();
      gameProvider = GameProvider(
        storageService: storageService,
        supabaseService: supabaseService,
      );
      await gameProvider.loadInitialState();
    });

    testWidgets('HomeScreen renders 3 tabs including Mis Desafíos (CRUD)',
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

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify all 3 tabs are rendered
      expect(find.text('Adivinar Jugador'), findsOneWidget);
      expect(find.text('Adivinar Equipo'), findsOneWidget);
      expect(find.text('Mis Desafíos (CRUD)'), findsOneWidget);

      // Tap tab 3
      await tester.tap(find.text('Mis Desafíos (CRUD)'));
      await tester.pumpAndSettle();

      expect(find.text('Desafíos Supabase con RLS'), findsOneWidget);
      expect(find.byKey(const Key('create_challenge_button')), findsOneWidget);
    });
  });
}
