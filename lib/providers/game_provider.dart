import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/custom_challenge_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storageService;
  final SupabaseService _supabaseService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Map<String, ChallengeRecord> _recordsMap = {};
  UnmodifiableMapView<String, ChallengeRecord> get recordsMap =>
      UnmodifiableMapView(_recordsMap);

  Map<String, dynamic> _statistics = {
    'totalPlayed': 0,
    'wins': 0,
    'losses': 0,
    'winRate': 0.0,
    'averageAttempts': 0.0,
  };
  Map<String, dynamic> get statistics => Map.unmodifiable(_statistics);

  final List<CustomChallenge> _customChallenges = [];
  UnmodifiableListView<CustomChallenge> get customChallenges =>
      UnmodifiableListView(_customChallenges);

  GameProvider({
    StorageService? storageService,
    SupabaseService? supabaseService,
  })  : _storageService = storageService ?? StorageService(),
        _supabaseService = supabaseService ?? SupabaseService();

  StorageService get storageService => _storageService;
  SupabaseService get supabaseService => _supabaseService;

  bool get isAuthenticated => _supabaseService.isAuthenticated;
  String? get currentUserEmail => _supabaseService.currentUserEmail;

  /// Loads historical records, stats and custom challenges from Supabase / Storage
  Future<void> loadInitialState() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.initialize();

      final history = await _storageService.getAllHistory();
      final stats = await _storageService.getStatistics();

      _recordsMap = {for (final r in history) r.challengeId: r};
      _statistics = stats;

      // Load custom challenges via Supabase service (with local fallback)
      final challenges = await _supabaseService.fetchChallenges();
      _customChallenges.clear();
      _customChallenges.addAll(challenges);
    } catch (e) {
      debugPrint('[GameProvider] Error loading initial state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Auth Operations ---

  Future<bool> login(String email, String password) async {
    final success =
        await _supabaseService.signIn(email: email, password: password);
    if (success) {
      final challenges = await _supabaseService.fetchChallenges();
      _customChallenges.clear();
      _customChallenges.addAll(challenges);
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(String email, String password) async {
    final success =
        await _supabaseService.signUp(email: email, password: password);
    if (success) {
      final challenges = await _supabaseService.fetchChallenges();
      _customChallenges.clear();
      _customChallenges.addAll(challenges);
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _supabaseService.signOut();
    final challenges = await _supabaseService.fetchChallenges();
    _customChallenges.clear();
    _customChallenges.addAll(challenges);
    notifyListeners();
  }

  // --- Challenge Records Operations ---

  ChallengeRecord? getRecord(String challengeId) => _recordsMap[challengeId];

  bool isCompleted(String challengeId) => _recordsMap.containsKey(challengeId);

  Future<void> recordChallengeAttempt({
    required String challengeId,
    required String type,
    required bool won,
    required int attemptsUsed,
  }) async {
    await _storageService.saveChallengeResult(
      challengeId: challengeId,
      type: type,
      won: won,
      attemptsUsed: attemptsUsed,
    );

    final updatedRecord = await _storageService.getChallengeResult(challengeId);
    if (updatedRecord != null) {
      _recordsMap[challengeId] = updatedRecord;
    }

    _statistics = await _storageService.getStatistics();
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    await _storageService.clearAll();
    _recordsMap.clear();
    _statistics = {
      'totalPlayed': 0,
      'wins': 0,
      'losses': 0,
      'winRate': 0.0,
      'averageAttempts': 0.0,
    };
    _customChallenges.clear();

    notifyListeners();
  }

  // --- CRUD for Custom Challenges ---

  Future<void> addCustomChallenge(CustomChallenge challenge) async {
    final created = await _supabaseService.createChallenge(challenge);
    _customChallenges.removeWhere((c) => c.id == created.id);
    _customChallenges.insert(0, created);
    notifyListeners();
  }

  Future<void> updateCustomChallenge(CustomChallenge challenge) async {
    final updated = await _supabaseService.updateChallenge(challenge);
    final index = _customChallenges.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _customChallenges[index] = updated;
    }
    notifyListeners();
  }

  Future<void> deleteCustomChallenge(String id) async {
    await _supabaseService.deleteChallenge(id);
    _customChallenges.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
