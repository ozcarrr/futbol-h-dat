import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../services/football_api_service.dart';
import '../services/storage_service.dart';
import 'guess_player_screen.dart';
import 'guess_team_screen.dart';

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

  List<Player> _players = [];
  List<Team> _teams = [];
  Map<String, ChallengeRecord> _recordsMap = {};
  Map<String, dynamic> _stats = {
    'totalPlayed': 0,
    'wins': 0,
    'losses': 0,
    'winRate': 0.0,
    'averageAttempts': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? FootballApiService();
    _storageService = widget.storageService ?? StorageService();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final players = await _apiService.getPlayers();
      final teams = await _apiService.getTeams();
      final history = await _storageService.getAllHistory();
      final stats = await _storageService.getStatistics();

      final recordsMap = <String, ChallengeRecord>{};
      for (final rec in history) {
        recordsMap[rec.challengeId] = rec;
      }

      if (mounted) {
        setState(() {
          _players = players;
          _teams = teams;
          _recordsMap = recordsMap;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
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
            child: const Text('Reiniciar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearAll();
      await _loadAllData();
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
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 16),
                    Text('Cargando Hub de Desafíos...',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      // Stats Header Banner
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildStatsBanner(),
                      ),
                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPlayersList(),
                            _buildTeamsList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final totalPlayed = _stats['totalPlayed'] ?? 0;
    final wins = _stats['wins'] ?? 0;
    final winRate = (_stats['winRate'] as num?)?.toStringAsFixed(0) ?? '0';
    final avgAttempts =
        (_stats['averageAttempts'] as num?)?.toStringAsFixed(1) ?? '0.0';

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

  Widget _buildPlayersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final record = _recordsMap[player.id];
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
                  ),
                ),
              );
              await _loadAllData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar / Lock status
                  Container(
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
                            child: player.imageUrl.isNotEmpty
                                ? Image.network(
                                    player.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      record.won ? Icons.check : Icons.close,
                                      color: record.won
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF5252),
                                    ),
                                  )
                                : Icon(
                                    record.won ? Icons.check : Icons.close,
                                    color: record.won
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF5252),
                                  ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.question_mark_rounded,
                              color: Color(0xFF00E676),
                              size: 24,
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
                              ? '${player.nationality} • ${player.position} • Actual: ${player.currentTeam}'
                              : 'Descubre al jugador mediante pistas de trayectoria y atributos',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.white70
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Trailing status badge
                  _buildStatusChip(
                    isCompleted: isCompleted,
                    won: record?.won ?? false,
                    attempts: record?.attemptsUsed ?? 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final record = _recordsMap[team.id];
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
                  ),
                ),
              );
              await _loadAllData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Team Crest / Locked Crest
                  Container(
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
                        ? Image.network(
                            team.logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              record.won ? Icons.check : Icons.close,
                              color: record.won
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFFF5252),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              color: Color(0xFFFFD54F),
                              size: 24,
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
                              : 'Desafío Club #${index + 1}',
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
                              : 'Identifica el club a partir de su escudo pixelado/recortado',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.white70
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status chip
                  _buildStatusChip(
                    isCompleted: isCompleted,
                    won: record?.won ?? false,
                    attempts: record?.attemptsUsed ?? 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip({
    required bool isCompleted,
    required bool won,
    required int attempts,
  }) {
    if (!isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D3A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C4356)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Jugar',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: Colors.white70),
          ],
        ),
      );
    }

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
  bool _isSearching = false;
  Map<String, dynamic>? _lastResult;
  String? _errorMessage;
  String _targetType = 'team'; // 'team' or 'player'

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: widget.apiService.apiKey);
  }

  Future<void> _executeSearch(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    // Sync any user-modified API key
    if (_apiKeyController.text.trim().isNotEmpty) {
      widget.apiService.apiKey = _apiKeyController.text.trim();
    }

    setState(() {
      _isSearching = true;
      _lastResult = null;
      _errorMessage = null;
    });

    try {
      if (_targetType == 'team') {
        final res = await widget.apiService.fetchLiveTeamInfo(text);
        if (mounted) {
          setState(() {
            _lastResult = res;
            if (res == null) {
              _errorMessage = 'No se encontraron resultados para "$text".';
            }
          });
        }
      } else {
        final res = await widget.apiService.fetchLivePlayerInfo(text);
        if (mounted) {
          setState(() {
            _lastResult = res;
            if (res == null) {
              _errorMessage = 'No se encontraron resultados para "$text".';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Excepción: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
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
                'Consulta TheSportsDB REST API con capa de fallback y enriquecimiento CORS seguro:',
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
                    onPressed: _isSearching
                        ? null
                        : () => _executeSearch(_queryController.text),
                    child: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Consultar',
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

              // Results box
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1719),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF5252)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFF8A80)),
                  ),
                ),

              if (_lastResult != null) ...[
                Container(
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
                            'Origen: ${_lastResult!["source"] ?? "TheSportsDB Free API"}',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if ((_lastResult!['strBadge'] ??
                              _lastResult!['strThumb'] ??
                              _lastResult!['strLogo']) !=
                          null) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            height: 90,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14212D),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFF223545)),
                            ),
                            child: Image.network(
                              (_lastResult!['strBadge'] ??
                                      _lastResult!['strThumb'] ??
                                      _lastResult!['strLogo'])
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
                        const JsonEncoder.withIndent('  ')
                            .convert(_lastResult),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF81D4FA),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
