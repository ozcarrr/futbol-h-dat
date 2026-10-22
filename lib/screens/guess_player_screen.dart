import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../services/storage_service.dart';
import '../widgets/autocomplete_search.dart';
import '../widgets/clue_tile.dart';

class GuessPlayerScreen extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final StorageService? storageService;

  const GuessPlayerScreen({
    super.key,
    required this.player,
    required this.allPlayers,
    this.storageService,
  });

  @override
  State<GuessPlayerScreen> createState() => _GuessPlayerScreenState();
}

class _GuessPlayerScreenState extends State<GuessPlayerScreen> {
  static const int maxAttempts = 6;

  late final StorageService _storageService;
  int _attempts = 0;
  final List<Player> _guesses = [];
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
    final record = await _storageService.getChallengeResult(widget.player.id);
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

  Future<void> _handlePlayerGuess(Player guessedPlayer) async {
    if (_isGameOver) return;

    final isCorrect = guessedPlayer.id == widget.player.id;
    final newAttempts = _attempts + 1;
    final isMaxReached = newAttempts >= maxAttempts;

    setState(() {
      _guesses.insert(0, guessedPlayer);
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
          challengeId: widget.player.id,
          type: 'player',
          won: isCorrect,
          attemptsUsed: newAttempts,
        );
      }
    }
  }

  Future<void> _skipAttemptForClue() async {
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
        challengeId: widget.player.id,
        type: 'player',
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

    // Clue unlock rules
    final bool unlockPosition = true; // Always unlocked initially
    final bool unlockNationality = _attempts >= 1 || _isGameOver;
    final bool unlockInitialTeam = _attempts >= 2 || _isGameOver;
    final bool unlockAge = _attempts >= 3 || _isGameOver;
    final bool unlockCurrentTeam = _attempts >= 4 || _isGameOver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adivina el Jugador'),
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
                        : const Color(0xFF00E676),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Attempt progress indicators
                      _buildAttemptsBar(),
                      const SizedBox(height: 16),

                      // End of game Banner / Reveal Card
                      if (_isGameOver) ...[
                        _buildGameOverCard(),
                        const SizedBox(height: 20),
                      ],

                      // Progressive Clues Panel
                      Text(
                        'Pistas Progresivas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCluesGrid(
                        unlockPosition: unlockPosition,
                        unlockNationality: unlockNationality,
                        unlockInitialTeam: unlockInitialTeam,
                        unlockAge: unlockAge,
                        unlockCurrentTeam: unlockCurrentTeam,
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
                        AutocompleteSearch.forPlayers(
                          players: widget.allPlayers,
                          excludedIds: _guesses.map((p) => p.id).toList(),
                          enabled: !_isGameOver,
                          onSelected: _handlePlayerGuess,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Escribe para buscar y comparar atributos.',
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
                              onPressed: _skipAttemptForClue,
                              icon: const Icon(Icons.lightbulb_outline,
                                  size: 16),
                              label: const Text(
                                'Pedir Pista (+1 intento)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Comparison Rows of Guesses
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
                            return PlayerGuessRow(
                              guessedPlayer: guess,
                              targetPlayer: widget.player,
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
          pillColor = const Color(0xFF00E676).withAlpha(40);
          border = Border.all(color: const Color(0xFF00E676), width: 1.5);
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
    final target = widget.player;
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
                          ? 'Descubriste al jugador en $_attempts ${_attempts == 1 ? "intento" : "intentos"}.'
                          : 'Se agotaron los 6 intentos permitidos.',
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

          // Player Reveal Profile
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWin
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF5252),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    target.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF14212D),
                      child: const Icon(Icons.person,
                          size: 36, color: Colors.white60),
                    ),
                  ),
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
                      '${target.nationality} • ${target.position} • ${target.age} años',
                      style: const TextStyle(
                          color: Color(0xFFFFD54F), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Debut: ${target.initialTeam}  ➔  Actual: ${target.currentTeam}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
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

  Widget _buildCluesGrid({
    required bool unlockPosition,
    required bool unlockNationality,
    required bool unlockInitialTeam,
    required bool unlockAge,
    required bool unlockCurrentTeam,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth > 550
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: ProgressiveClueCard(
                title: 'Posición',
                value: widget.player.position,
                icon: Icons.sports,
                isUnlocked: unlockPosition,
                unlockHint: 'Pista Inicial',
                accentColor: const Color(0xFF00E676),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ProgressiveClueCard(
                title: 'Nacionalidad',
                value: widget.player.nationality,
                icon: Icons.public,
                isUnlocked: unlockNationality,
                unlockHint: 'Intento 1',
                accentColor: const Color(0xFF81D4FA),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ProgressiveClueCard(
                title: 'Equipo Inicial',
                value: widget.player.initialTeam,
                icon: Icons.history,
                isUnlocked: unlockInitialTeam,
                unlockHint: 'Intento 2',
                accentColor: const Color(0xFFFFD54F),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ProgressiveClueCard(
                title: 'Edad',
                value: '${widget.player.age} años',
                icon: Icons.cake,
                isUnlocked: unlockAge,
                unlockHint: 'Intento 3',
                accentColor: const Color(0xFFFFAB91),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: ProgressiveClueCard(
                title: 'Equipo Actual',
                value: widget.player.currentTeam,
                icon: Icons.shield,
                isUnlocked: unlockCurrentTeam,
                unlockHint: 'Intento 4',
                accentColor: const Color(0xFFCE93D8),
              ),
            ),
          ],
        );
      },
    );
  }
}
