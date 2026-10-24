import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../providers/game_provider.dart';
import '../services/football_api_service.dart';
import '../services/storage_service.dart';
import 'guess_player_screen.dart';
import 'guess_team_screen.dart';
import '../widgets/app_image.dart';

class FootballData {
  final List<Player> players;
  final List<Team> teams;

  const FootballData({
    required this.players,
    required this.teams,
  });
}

class HomeScreen extends StatefulWidget {
  final FootballApiService? apiService;
  final StorageService? storageService;

  const HomeScreen({
    super.key,
    this.apiService,
    this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FootballApiService _apiService;
  late final StorageService _storageService;
  late Future<FootballData> _footballDataFuture;

  List<Player> _players = [];
  List<Team> _teams = [];
  Map<String, ChallengeRecord> _fallbackRecordsMap = {};
  Map<String, dynamic> _fallbackStats = {
    'totalPlayed': 0,
    'wins': 0,
    'losses': 0,
    'winRate': 0.0,
    'averageAttempts': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? FootballApiService();
    _storageService = widget.storageService ?? StorageService();
    _footballDataFuture = _fetchFootballData();
    _loadFallbackStorage();
  }

  Future<FootballData> _fetchFootballData() async {
    final players = await _apiService.getPlayers();
    final teams = await _apiService.getTeams();
    return FootballData(players: players, teams: teams);
  }

  Future<void> _loadFallbackStorage() async {
    try {
      final history = await _storageService.getAllHistory();
      final stats = await _storageService.getStatistics();
      if (mounted) {
        setState(() {
          _fallbackRecordsMap = {for (final r in history) r.challengeId: r};
          _fallbackStats = stats;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading fallback storage: $e');
    }
  }

  void _loadAllData() {
    setState(() {
      _footballDataFuture = _fetchFootballData();
    });
    _loadFallbackStorage();
    _getGameProvider()?.loadInitialState();
  }

  GameProvider? _getGameProvider() {
    try {
      return Provider.of<GameProvider>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14212D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF223545)),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Color(0xFFFF5252)),
            SizedBox(width: 8),
            Text('Reiniciar Progreso',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas borrar todas las partidas registradas y volver a bloquear todos los desafíos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, Reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = _getGameProvider();
      if (provider != null) {
        await provider.resetAllProgress();
      } else {
        await _storageService.clearAll();
        setState(() {
          _fallbackRecordsMap.clear();
          _fallbackStats = {
            'totalPlayed': 0,
            'wins': 0,
            'losses': 0,
            'winRate': 0.0,
            'averageAttempts': 0.0,
          };
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF102820),
            content: Text(
              '✅ Progreso reiniciado con éxito.',
              style: TextStyle(color: Color(0xFF00E676)),
            ),
          ),
        );
      }
    }
  }

  void _showApiInspector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1721),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ApiInspectorSheet(apiService: _apiService),
    );
  }

  @override
  Widget build(BuildContext context) {
    GameProvider? provider;
    try {
      provider = context.watch<GameProvider>();
    } catch (_) {
      provider = null;
    }

    final currentStats = provider?.statistics ?? _fallbackStats;
    final currentRecords = provider?.recordsMap ?? _fallbackRecordsMap;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_soccer,
                  color: Color(0xFF00E676), size: 26),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1),
                  children: [
                    TextSpan(
                        text: 'Futbo', style: TextStyle(color: Colors.white)),
                    TextSpan(
                        text: 'LE',
                        style: TextStyle(color: Color(0xFF00E676))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar datos',
              onPressed: _loadAllData,
            ),
            IconButton(
              icon: const Icon(Icons.api_rounded, color: Color(0xFF00E676)),
              tooltip: 'Inspector de API REST en Vivo',
              onPressed: _showApiInspector,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF00E676),
            indicatorWeight: 3,
            labelColor: Color(0xFF00E676),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                icon: Icon(Icons.person_pin),
                text: 'Adivinar Jugador',
              ),
              Tab(
                icon: Icon(Icons.shield),
                text: 'Adivinar Equipo',
              ),
            ],
          ),
        ),
        body: FutureBuilder<FootballData>(
          future: _footballDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 16),
                    Text('Cargando Hub de Desafíos desde la API...',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Color(0xFFFF5252)),
                      const SizedBox(height: 12),
                      Text(
                        'Error al consultar la API: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _loadAllData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data =
                snapshot.data ?? const FootballData(players: [], teams: []);
            _players = data.players;
            _teams = data.teams;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    // Stats Header Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildStatsBanner(currentStats),
                    ),
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPlayersList(currentRecords),
                          _buildTeamsList(currentRecords),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsBanner(Map<String, dynamic> stats) {
    final totalPlayed = stats['totalPlayed'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final winRate = (stats['winRate'] as num?)?.toStringAsFixed(0) ?? '0';
    final avgAttempts =
        (stats['averageAttempts'] as num?)?.toStringAsFixed(1) ?? '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14212D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223545)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard,
                  color: Color(0xFFFFD54F), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tu Rendimiento en FutboLE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8A80),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _confirmResetProgress,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reiniciar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('Completados', '$totalPlayed', Icons.task_alt,
                  const Color(0xFF81D4FA)),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Victorias', '$wins', Icons.emoji_events, const Color(0xFF00E676)),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Efectividad', '$winRate%', Icons.percent, const Color(0xFFFFD54F)),
              const SizedBox(width: 8),
              _buildStatChip('Prom. Intentos', avgAttempts, Icons.speed,
                  const Color(0xFFFFAB91)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B141C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1B2C3C)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList(Map<String, ChallengeRecord> recordsMap) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final record = recordsMap[player.id];
        final isCompleted = record != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuessPlayerScreen(
                    player: player,
                    allPlayers: _players,
                    storageService: _storageService,
                  ),
                ),
              );
              _loadAllData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Hero Avatar / Lock status
                  Hero(
                    tag: 'player_hero_${player.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? (record.won
                                  ? const Color(0xFF00E676).withAlpha(30)
                                  : const Color(0xFFFF5252).withAlpha(30))
                              : const Color(0xFF1E3A2F),
                          border: Border.all(
                            color: isCompleted
                                ? (record.won
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF5252))
                                : const Color(0xFF00E676).withAlpha(100),
                            width: 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? ClipOval(
                                child: PlayerPhoto(player: player),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.question_mark_rounded,
                                  color: Color(0xFF00E676),
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Challenge Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted
                              ? player.name
                              : 'Desafío Jugador #${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.white
                                : const Color(0xFF00E676),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? '${player.position} • ${player.currentTeam}'
                              : 'Adivina al futbolista según pistas progresivas',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  _buildStatusBadge(record),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsList(Map<String, ChallengeRecord> recordsMap) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final record = recordsMap[team.id];
        final isCompleted = record != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuessTeamScreen(
                    team: team,
                    allTeams: _teams,
                    storageService: _storageService,
                  ),
                ),
              );
              _loadAllData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Hero Team Crest / Locked Crest
                  Hero(
                    tag: 'team_hero_${team.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? (record.won
                                  ? const Color(0xFFFFD54F).withAlpha(30)
                                  : const Color(0xFFFF5252).withAlpha(30))
                              : const Color(0xFF272517),
                          border: Border.all(
                            color: isCompleted
                                ? (record.won
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFFF5252))
                                : const Color(0xFFFFD54F).withAlpha(100),
                            width: 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? Padding(
                                padding: const EdgeInsets.all(4),
                                child:
                                    TeamBadge(team: team, fit: BoxFit.contain),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFFFD54F),
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Challenge Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted
                              ? team.name
                              : 'Desafío Escudo #${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.white
                                : const Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? '${team.country} • ${team.league}'
                              : 'Reconoce el club ampliando progresivamente su escudo',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  _buildStatusBadge(record),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ChallengeRecord? record) {
    if (record == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF14212D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF223545)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 14, color: Colors.white60),
            SizedBox(width: 4),
            Text(
              'Pendiente',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final won = record.won;
    final attempts = record.attemptsUsed;

    if (won) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF102820),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                size: 14, color: Color(0xFF00E676)),
            const SizedBox(width: 4),
            Text(
              '$attempts ${attempts == 1 ? "intento" : "intentos"}',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF331518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5252)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, size: 14, color: Color(0xFFFF5252)),
          SizedBox(width: 4),
          Text(
            'Fallado',
            style: TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiInspectorSheet extends StatefulWidget {
  final FootballApiService apiService;

  const _ApiInspectorSheet({required this.apiService});

  @override
  State<_ApiInspectorSheet> createState() => _ApiInspectorSheetState();
}

class _ApiInspectorSheetState extends State<_ApiInspectorSheet> {
  final TextEditingController _queryController = TextEditingController();
  late final TextEditingController _apiKeyController;
  Future<Map<String, dynamic>?>? _searchFuture;
  String _targetType = 'team'; // 'team' or 'player'

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: widget.apiService.apiKey);
  }

  void _executeSearch(String query) {
    final text = query.trim();
    if (text.isEmpty) return;

    if (_apiKeyController.text.trim().isNotEmpty) {
      widget.apiService.apiKey = _apiKeyController.text.trim();
    }

    setState(() {
      _searchFuture = _targetType == 'team'
          ? widget.apiService.fetchLiveTeamInfo(text)
          : widget.apiService.fetchLivePlayerInfo(text);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 650),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  const Text(
                    'Inspector REST API en Vivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Consulta TheSportsDB REST API con FutureBuilder y capa de enriquecimiento segura:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // API Key Configuration row
              Row(
                children: [
                  const Text('API Key:',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    height: 36,
                    child: TextField(
                      controller: _apiKeyController,
                      style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 12,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        hintText: '123 o tu API Key',
                        hintStyle: const TextStyle(
                            color: Colors.white30, fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF14212D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF223545)),
                        ),
                      ),
                      onChanged: (val) {
                        widget.apiService.apiKey = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Usa "123" (prueba) o tu clave gratuita de TheSportsDB',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selector Team / Player
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Equipos / Clubes'),
                    selected: _targetType == 'team',
                    selectedColor: const Color(0xFF00E676),
                    onSelected: (val) {
                      if (val) setState(() => _targetType = 'team');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Jugadores'),
                    selected: _targetType == 'player',
                    selectedColor: const Color(0xFF00E676),
                    onSelected: (val) {
                      if (val) setState(() => _targetType = 'player');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _targetType == 'team'
                            ? 'Ej: Arsenal, Real Madrid, Colo-Colo...'
                            : 'Ej: Alexis Sanchez, Messi, Vidal...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF14212D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF223545)),
                        ),
                      ),
                      onSubmitted: _executeSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    onPressed: () => _executeSearch(_queryController.text),
                    child: const Text('Consultar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick preset buttons
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (_targetType == 'team'
                        ? ['Arsenal', 'Colo-Colo', 'Real Madrid', 'Juventus']
                        : ['Alexis Sanchez', 'Lionel Messi', 'Arturo Vidal'])
                    .map((preset) => ActionChip(
                          backgroundColor: const Color(0xFF15222E),
                          label: Text(preset,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          onPressed: () {
                            _queryController.text = preset;
                            _executeSearch(preset);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Live FutureBuilder for REST API search
              if (_searchFuture != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _searchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            CircularProgressIndicator(
                                color: Color(0xFF00E676)),
                            SizedBox(height: 12),
                            Text(
                              'Consultando TheSportsDB REST API...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E1719),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF5252)),
                        ),
                        child: Text(
                          'Error en la consulta: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFFFF8A80)),
                        ),
                      );
                    }

                    final result = snapshot.data;
                    if (result == null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2833),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Text(
                          'No se encontraron resultados para "${_queryController.text.trim()}".',
                          style: const TextStyle(color: Color(0xFFFFD54F)),
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070E14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00E676)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Color(0xFF00E676)),
                              const SizedBox(width: 6),
                              Text(
                                'Origen: ${result["source"] ?? "TheSportsDB REST API"}',
                                style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if ((result['strBadge'] ??
                                  result['strThumb'] ??
                                  result['strLogo']) !=
                              null) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                height: 90,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14212D),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF223545)),
                                ),
                                child: Image.network(
                                  (result['strBadge'] ??
                                          result['strThumb'] ??
                                          result['strLogo'])
                                      .toString(),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            const JsonEncoder.withIndent('  ').convert(result),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF81D4FA),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
