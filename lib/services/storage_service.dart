import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeRecord {
  final String challengeId;
  final String type; // 'player' or 'team'
  final bool won;
  final int attemptsUsed;
  final DateTime timestamp;

  ChallengeRecord({
    required this.challengeId,
    required this.type,
    required this.won,
    required this.attemptsUsed,
    required this.timestamp,
  });

  factory ChallengeRecord.fromJson(Map<String, dynamic> json) {
    return ChallengeRecord(
      challengeId: json['challengeId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      won: json['won'] as bool? ?? false,
      attemptsUsed: (json['attemptsUsed'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'type': type,
        'won': won,
        'attemptsUsed': attemptsUsed,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() {
    return 'ChallengeRecord(challengeId: $challengeId, type: $type, won: $won, attempts: $attemptsUsed)';
  }
}

class StorageService {
  static const String _keyPrefix = 'futbole_record_';
  static const String _allIdsKey = 'futbole_all_challenge_ids';

  final SharedPreferences? _prefsInstance;

  StorageService([this._prefsInstance]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  /// Records a completed challenge attempt
  Future<void> saveChallengeResult({
    required String challengeId,
    required String type,
    required bool won,
    required int attemptsUsed,
  }) async {
    final prefs = await _getPrefs();
    final record = ChallengeRecord(
      challengeId: challengeId,
      type: type,
      won: won,
      attemptsUsed: attemptsUsed,
      timestamp: DateTime.now(),
    );

    final encoded = json.encode(record.toJson());
    await prefs.setString('$_keyPrefix$challengeId', encoded);

    // Update index of challenge IDs
    final allIds = prefs.getStringList(_allIdsKey) ?? [];
    if (!allIds.contains(challengeId)) {
      allIds.add(challengeId);
      await prefs.setStringList(_allIdsKey, allIds);
    }
  }

  /// Retrieves record for a specific challenge ID, or null if not yet attempted
  Future<ChallengeRecord?> getChallengeResult(String challengeId) async {
    final prefs = await _getPrefs();
    final data = prefs.getString('$_keyPrefix$challengeId');
    if (data == null) return null;

    try {
      final decoded = json.decode(data) as Map<String, dynamic>;
      return ChallengeRecord.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a challenge has already been completed
  Future<bool> isChallengeCompleted(String challengeId) async {
    final record = await getChallengeResult(challengeId);
    return record != null;
  }

  /// Retrieves all historical challenge attempts
  Future<List<ChallengeRecord>> getAllHistory() async {
    final prefs = await _getPrefs();
    final allIds = prefs.getStringList(_allIdsKey) ?? [];
    final List<ChallengeRecord> results = [];

    for (final id in allIds) {
      final raw = prefs.getString('$_keyPrefix$id');
      if (raw != null) {
        try {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          results.add(ChallengeRecord.fromJson(decoded));
        } catch (_) {}
      }
    }

    return results;
  }

  /// Calculates quick stats (total played, wins, losses, win rate, average attempts)
  Future<Map<String, dynamic>> getStatistics() async {
    final history = await getAllHistory();
    final total = history.length;
    final wins = history.where((r) => r.won).length;
    final losses = total - wins;
    final winRate = total > 0 ? (wins / total) * 100 : 0.0;
    final totalAttempts = history.fold<int>(0, (sum, r) => sum + r.attemptsUsed);
    final averageAttempts = total > 0 ? (totalAttempts / total) : 0.0;

    return {
      'totalPlayed': total,
      'wins': wins,
      'losses': losses,
      'winRate': winRate,
      'averageAttempts': averageAttempts,
    };
  }

  /// Resets all saved progress and attempts
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    final allIds = prefs.getStringList(_allIdsKey) ?? [];
    for (final id in allIds) {
      await prefs.remove('$_keyPrefix$id');
    }
    await prefs.remove(_allIdsKey);
  }
}
