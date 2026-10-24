import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_challenge_model.dart';
import '../services/storage_service.dart';

class GameProvider extends ChangeNotifier {
  static const String _customChallengesKey = 'futbole_custom_challenges_list';

  final StorageService _storageService;
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

  GameProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  StorageService get storageService => _storageService;

  /// Loads historical records, stats and custom challenges from SharedPreferences
  Future<void> loadInitialState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final history = await _storageService.getAllHistory();
      final stats = await _storageService.getStatistics();

      _recordsMap = {for (final r in history) r.challengeId: r};
      _statistics = stats;

      // Load custom challenges
      final prefs = await SharedPreferences.getInstance();
      final rawChallenges = prefs.getStringList(_customChallengesKey) ?? [];
      _customChallenges.clear();
      for (final raw in rawChallenges) {
        try {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          _customChallenges.add(CustomChallenge.fromJson(decoded));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[GameProvider] Error loading initial state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the completed challenge record if exists, or null
  ChallengeRecord? getRecord(String challengeId) => _recordsMap[challengeId];

  /// Checks if a challenge has already been completed
  bool isCompleted(String challengeId) => _recordsMap.containsKey(challengeId);

  /// Records a challenge attempt, persists to StorageService, and notifies listeners
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

  /// Clears all game progress, statistics and challenges
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customChallengesKey);
    _customChallenges.clear();

    notifyListeners();
  }

  // --- CRUD for Custom Challenges (Phase 6 readiness) ---

  Future<void> _persistCustomChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          _customChallenges.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_customChallengesKey, encoded);
    } catch (e) {
      debugPrint('[GameProvider] Error persisting custom challenges: $e');
    }
  }

  Future<void> addCustomChallenge(CustomChallenge challenge) async {
    _customChallenges.insert(0, challenge);
    await _persistCustomChallenges();
    notifyListeners();
  }

  Future<void> updateCustomChallenge(CustomChallenge challenge) async {
    final index = _customChallenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      _customChallenges[index] = challenge;
      await _persistCustomChallenges();
      notifyListeners();
    }
  }

  Future<void> deleteCustomChallenge(String id) async {
    _customChallenges.removeWhere((c) => c.id == id);
    await _persistCustomChallenges();
    notifyListeners();
  }
}
