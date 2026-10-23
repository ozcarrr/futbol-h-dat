import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../services/storage_service.dart';
import '../widgets/autocomplete_search.dart';
import '../widgets/clue_tile.dart';

class GuessTeamScreen extends StatefulWidget {
  final Team team;
  final List<Team> allTeams;
  final StorageService? storageService;

  const GuessTeamScreen({
    super.key,
    required this.team,
    required this.allTeams,
    this.storageService,
  });

  @override
  State<GuessTeamScreen> createState() => _GuessTeamScreenState();
}

class _GuessTeamScreenState extends State<GuessTeamScreen> {
  static const int maxAttempts = 5;

  late final StorageService _storageService;
  int _attempts = 0;
  final List<Team> _guesses = [];
  bool _isGameOver = false;
  bool _isWon = false;
  bool _isInitialLoading = true;
  bool _isPracticeMode = false;
  ChallengeRecord? _previousRecord;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageService();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final record = await _storageService.getChallengeResult(widget.team.id);
    if (mounted) {
      setState(() {
        if (record != null) {
          _previousRecord = record;
          _isGameOver = true;
          _isWon = record.won;
          _attempts = record.attemptsUsed;
        }
        _isInitialLoading = false;
      });
    }
  }

  double get currentZoomScale {
    if (_isGameOver) return 1.0;
    switch (_attempts) {
      case 0:
        return 4.2;
      case 1:
        return 3.1;
      case 2:
        return 2.3;
      case 3:
        return 1.65;
      case 4:
        return 1.25;
      default:
        return 1.0;
    }
  }

  Future<void> _handleTeamGuess(Team guessedTeam) async {
    if (_isGameOver) return;

    final isCorrect = guessedTeam.id == widget.team.id;
    final newAttempts = _attempts + 1;
    final isMaxReached = newAttempts >= maxAttempts;

    setState(() {
      _guesses.insert(0, guessedTeam);
      _attempts = newAttempts;

      if (isCorrect) {
        _isWon = true;
        _isGameOver = true;
      } else if (isMaxReached) {
        _isWon = false;
        _isGameOver = true;
      }
    });

    if (isCorrect || isMaxReached) {
      if (!_isPracticeMode) {
        await _storageService.saveChallengeResult(
          challengeId: widget.team.id,
          type: 'team',
          won: isCorrect,
          attemptsUsed: newAttempts,
        );
      }
    }
  }

  Future<void> _skipAttemptForZoom() async {
    if (_isGameOver || _attempts >= maxAttempts) return;

    final newAttempts = _attempts + 1;
    final isMaxReached = newAttempts >= maxAttempts;

    setState(() {
      _attempts = newAttempts;
      if (isMaxReached) {
        _isWon = false;
        _isGameOver = true;
      }
    });

    if (isMaxReached && !_isPracticeMode) {
      await _storageService.saveChallengeResult(
        challengeId: widget.team.id,
        type: 'team',
        won: false,
        attemptsUsed: newAttempts,
      );
    }
  }

  void _resetForPractice() {
    setState(() {
      _attempts = 0;
      _guesses.clear();
      _isGameOver = false;
      _isWon = false;
      _isPracticeMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Progressive clue unlock rules
    final bool unlockCountry = _attempts >= 2 || _isGameOver;
    final bool unlockLeague = _attempts >= 3 || _isGameOver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adivina el Equipo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14212D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF223545)),
                ),
                child: Text(
                  'Intentos: $_attempts / $maxAttempts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _attempts >= maxAttempts
                        ? const Color(0xFFFF5252)
                        : const Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Attempt progress bar
                      _buildAttemptsBar(),
                      const SizedBox(height: 20),

                      // End of game Outcome Card
                      if (_isGameOver) ...[
                        _buildGameOverCard(),
                        const SizedBox(height: 20),
                      ],

                      // Progressive Logo Un-Zooming Viewport
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1A24),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isGameOver
                                      ? (_isWon
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF5252))
                                      : const Color(0xFFFFD54F).withAlpha(140),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(120),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Center(
                                  child: AnimatedScale(
                                    scale: currentZoomScale,
                                    duration:
                                        const Duration(milliseconds: 450),
                                    curve: Curves.easeOutCubic,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: widget.team.logoUrl.isNotEmpty
                                          ? Image.network(
                                              widget.team.logoUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                Icons.shield,
                                                size: 80,
                                                color: Color(0xFFFFD54F),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.shield,
                                              size: 80,
                                              color: Color(0xFFFFD54F),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14212D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF223545)),
                              ),
                              child: Text(
                                _isGameOver
                                    ? 'Zoom: 1.0x — Escudo 100% Revelado'
                                    : 'Zoom actual: ${currentZoomScale.toStringAsFixed(1)}x — Se reduce con cada intento',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progressive Text Clues (País and Liga)
                      Text(
                        'Pistas del Club',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ProgressiveClueCard(
                              title: 'País',
                              value: widget.team.country,
                              icon: Icons.public,
                              isUnlocked: unlockCountry,
                              unlockHint: 'Desbloquea en intento 2',
                              accentColor: const Color(0xFF81D4FA),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProgressiveClueCard(
                              title: 'Liga',
                              value: widget.team.league,
                              icon: Icons.emoji_events,
                              isUnlocked: unlockLeague,
                              unlockHint: 'Desbloquea en intento 3',
                              accentColor: const Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Search & Guess Input
                      if (!_isGameOver) ...[
                        Text(
                          'Haz tu intento',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AutocompleteSearch.forTeams(
                          teams: widget.allTeams,
                          excludedIds: _guesses.map((t) => t.id).toList(),
                          enabled: !_isGameOver,
                          onSelected: _handleTeamGuess,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Escribe para buscar el club.',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD54F),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                              onPressed: _skipAttemptForZoom,
                              icon: const Icon(Icons.zoom_out, size: 16),
                              label: const Text(
                                'Alejar Zoom (+1 intento)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // History of Team Guesses
                      if (_guesses.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Historial de Intentos (${_guesses.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Verde = Coincidencia exacta',
                              style: TextStyle(
                                  color: Color(0xFF00E676), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _guesses.length,
                          itemBuilder: (context, index) {
                            final guess = _guesses[index];
                            return TeamGuessRow(
                              guessedTeam: guess,
                              targetTeam: widget.team,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAttemptsBar() {
    return Row(
      children: List.generate(maxAttempts, (index) {
        final isUsed = index < _attempts;
        final isCurrent = index == _attempts && !_isGameOver;

        Color pillColor = const Color(0xFF1B2C3C);
        Border? border = Border.all(color: const Color(0xFF263F56));

        if (isUsed) {
          if (_isWon && index == _attempts - 1) {
            pillColor = const Color(0xFF00E676);
            border = Border.all(color: const Color(0xFF00E676));
          } else {
            pillColor = const Color(0xFFFF5252).withAlpha(180);
            border = Border.all(color: const Color(0xFFFF5252));
          }
        } else if (isCurrent) {
          pillColor = const Color(0xFFFFD54F).withAlpha(40);
          border = Border.all(color: const Color(0xFFFFD54F), width: 1.5);
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == maxAttempts - 1 ? 0 : 6),
            height: 8,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(4),
              border: border,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameOverCard() {
    final target = widget.team;
    final isWin = _isWon;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWin ? const Color(0xFF0C2419) : const Color(0xFF2B1216),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWin ? const Color(0xFF00E676) : const Color(0xFFFF5252),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWin
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF5252),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWin ? '¡FELICITACIONES! ACERTASTE' : 'DESAFÍO NO SUPERADO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isWin
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF8A80),
                      ),
                    ),
                    Text(
                      isWin
                          ? 'Identificaste el club en $_attempts ${_attempts == 1 ? "intento" : "intentos"}.'
                          : 'Se agotaron los 5 intentos permitidos.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2E4050), height: 1),
          const SizedBox(height: 16),

          // Team Identity Reveal
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF14212D),
                  border: Border.all(
                    color: isWin
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF5252),
                    width: 2,
                  ),
                ),
                child: target.logoUrl.isNotEmpty
                    ? Image.network(
                        target.logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.shield,
                          size: 32,
                          color: Color(0xFFFFD54F),
                        ),
                      )
                    : const Icon(
                        Icons.shield,
                        size: 32,
                        color: Color(0xFFFFD54F),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${target.country} • ${target.league}',
                      style: const TextStyle(
                          color: Color(0xFFFFD54F), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF334B61)),
                ),
                onPressed: _resetForPractice,
                icon: const Icon(Icons.replay, size: 16),
                label: Text(
                  _previousRecord != null
                      ? 'Reintentar Desafío'
                      : 'Modo Práctica',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check, size: 16),
                label: const Text(
                  'Volver al Hub',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
