import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_challenge_model.dart';

class SupabaseService {
  static const String _sessionEmailKey = 'futbole_supabase_session_email';
  static const String _sessionUserIdKey = 'futbole_supabase_session_user_id';
  static const String _localChallengesKey = 'futbole_custom_challenges_list';

  final String _url;
  final String _anonKey;
  bool _isRealClientActive = false;

  String? _cachedEmail;
  String? _cachedUserId;

  SupabaseService({
    String? url,
    String? anonKey,
  })  : _url = url ??
            const String.fromEnvironment('SUPABASE_URL',
                defaultValue: 'https://demo-futbole.supabase.co'),
        _anonKey = anonKey ??
            const String.fromEnvironment('SUPABASE_ANON_KEY',
                defaultValue: 'demo-anon-key');

  bool get isRealClientActive => _isRealClientActive;
  String? get currentUserEmail => _cachedEmail;
  String? get currentUserId => _cachedUserId;
  bool get isAuthenticated => _cachedEmail != null && _cachedEmail!.isNotEmpty;

  /// Initializes the Supabase client if valid credentials are provided,
  /// otherwise operates safely in resilient local mode.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedEmail = prefs.getString(_sessionEmailKey);
    _cachedUserId = prefs.getString(_sessionUserIdKey);

    final isPlaceholder = _url.contains('demo-futbole') ||
        _url.contains('placeholder') ||
        _anonKey.contains('demo-anon') ||
        _anonKey.contains('placeholder');

    if (!isPlaceholder) {
      try {
        await Supabase.initialize(
          url: _url,
          // ignore: deprecated_member_use
          anonKey: _anonKey,
          debug: kDebugMode,
        );
        _isRealClientActive = true;

        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          _cachedEmail = session.user.email;
          _cachedUserId = session.user.id;
        }
      } catch (e) {
        debugPrint('[SupabaseService] Real client init bypassed: $e');
        _isRealClientActive = false;
      }
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_isRealClientActive) {
      try {
        final res = await Supabase.instance.client.auth.signUp(
          email: cleanEmail,
          password: password,
        );
        if (res.user != null) {
          _cachedEmail = res.user!.email;
          _cachedUserId = res.user!.id;
          await _persistLocalSession(_cachedEmail!, _cachedUserId!);
          return true;
        }
      } catch (e) {
        debugPrint('[SupabaseService] Supabase signUp error: $e');
        rethrow;
      }
    }

    // Resilient local simulation fallback
    _cachedEmail = cleanEmail;
    _cachedUserId = 'local_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    await _persistLocalSession(_cachedEmail!, _cachedUserId!);
    return true;
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_isRealClientActive) {
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (res.user != null) {
          _cachedEmail = res.user!.email;
          _cachedUserId = res.user!.id;
          await _persistLocalSession(_cachedEmail!, _cachedUserId!);
          return true;
        }
      } catch (e) {
        debugPrint('[SupabaseService] Supabase signIn error: $e');
        rethrow;
      }
    }

    // Resilient local simulation fallback
    _cachedEmail = cleanEmail;
    _cachedUserId = 'local_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    await _persistLocalSession(_cachedEmail!, _cachedUserId!);
    return true;
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (_isRealClientActive) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('[SupabaseService] Supabase signOut error: $e');
      }
    }

    _cachedEmail = null;
    _cachedUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionUserIdKey);
  }

  Future<void> _persistLocalSession(String email, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, email);
    await prefs.setString(_sessionUserIdKey, userId);
  }

  // --- CRUD Operations for custom_challenges ---

  /// Fetches all custom challenges for the authenticated user (respecting RLS)
  Future<List<CustomChallenge>> fetchChallenges() async {
    if (_isRealClientActive && _cachedUserId != null) {
      try {
        final List<dynamic> data = await Supabase.instance.client
            .from('custom_challenges')
            .select()
            .order('created_at', ascending: false);

        return data
            .map((item) => CustomChallenge.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[SupabaseService] Supabase fetch error, fallback to local: $e');
      }
    }

    // Fallback to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_localChallengesKey) ?? [];
    final List<CustomChallenge> list = [];
    for (final raw in rawList) {
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        list.add(CustomChallenge.fromJson(decoded));
      } catch (_) {}
    }
    return list;
  }

  /// Inserts a new challenge into Supabase table custom_challenges
  Future<CustomChallenge> createChallenge(CustomChallenge challenge) async {
    final enriched = challenge.copyWith(
      userId: _cachedUserId ?? 'local_user',
    );

    if (_isRealClientActive && _cachedUserId != null) {
      try {
        final data = await Supabase.instance.client
            .from('custom_challenges')
            .insert(enriched.toJson())
            .select()
            .single();

        return CustomChallenge.fromJson(data);
      } catch (e) {
        debugPrint('[SupabaseService] Supabase insert error, fallback to local: $e');
      }
    }

    // Local storage fallback
    final list = await fetchChallenges();
    list.insert(0, enriched);
    await _saveLocalChallenges(list);
    return enriched;
  }

  /// Updates an existing challenge in Supabase table custom_challenges
  Future<CustomChallenge> updateChallenge(CustomChallenge challenge) async {
    if (_isRealClientActive && _cachedUserId != null) {
      try {
        final data = await Supabase.instance.client
            .from('custom_challenges')
            .update(challenge.toJson())
            .eq('id', challenge.id)
            .select()
            .single();

        return CustomChallenge.fromJson(data);
      } catch (e) {
        debugPrint('[SupabaseService] Supabase update error, fallback to local: $e');
      }
    }

    final list = await fetchChallenges();
    final index = list.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      list[index] = challenge;
      await _saveLocalChallenges(list);
    }
    return challenge;
  }

  /// Deletes a challenge in Supabase table custom_challenges
  Future<void> deleteChallenge(String id) async {
    if (_isRealClientActive && _cachedUserId != null) {
      try {
        await Supabase.instance.client
            .from('custom_challenges')
            .delete()
            .eq('id', id);
        return;
      } catch (e) {
        debugPrint('[SupabaseService] Supabase delete error, fallback to local: $e');
      }
    }

    final list = await fetchChallenges();
    list.removeWhere((c) => c.id == id);
    await _saveLocalChallenges(list);
  }

  Future<void> _saveLocalChallenges(List<CustomChallenge> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = list.map((c) => json.encode(c.toJson())).toList();
    await prefs.setStringList(_localChallengesKey, encoded);
  }
}
