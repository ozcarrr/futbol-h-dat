import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';

/// Displays a progressive clue item with locked/unlocked visual feedback
class ProgressiveClueCard extends StatelessWidget {
  final String title;
  final String? value;
  final IconData icon;
  final bool isUnlocked;
  final String unlockHint;
  final Color accentColor;

  const ProgressiveClueCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.isUnlocked,
    required this.unlockHint,
    this.accentColor = const Color(0xFF00E676),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? accentColor.withAlpha(20) : const Color(0xFF0D1721),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? accentColor.withAlpha(160)
              : const Color(0xFF1F2F3F),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? accentColor.withAlpha(35)
                  : const Color(0xFF14202B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? icon : Icons.lock_outline_rounded,
              size: 18,
              color: isUnlocked ? accentColor : Colors.white38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isUnlocked ? accentColor : Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked ? (value ?? '—') : unlockHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                    color: isUnlocked ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a single guess comparison row between guessed player and target player
class PlayerGuessRow extends StatelessWidget {
  final Player guessedPlayer;
  final Player targetPlayer;

  const PlayerGuessRow({
    super.key,
    required this.guessedPlayer,
    required this.targetPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final bool matchNationality = guessedPlayer.nationality.trim().toLowerCase() ==
        targetPlayer.nationality.trim().toLowerCase();

    final bool matchPosition = guessedPlayer.position.trim().toLowerCase() ==
        targetPlayer.position.trim().toLowerCase();

    final bool matchAge = guessedPlayer.age == targetPlayer.age;
    final bool isTargetOlder = targetPlayer.age > guessedPlayer.age;

    final bool matchInitial = guessedPlayer.initialTeam.trim().toLowerCase() ==
        targetPlayer.initialTeam.trim().toLowerCase();

    final bool matchCurrent = guessedPlayer.currentTeam.trim().toLowerCase() ==
        targetPlayer.currentTeam.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121D28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223545)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guessed Player Header Name
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                guessedPlayer.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (guessedPlayer.id == targetPlayer.id)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00E676)),
                  ),
                  child: const Text(
                    '¡CORRECTO!',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Comparison Attribute Cells
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: _buildAttributeCell(
                      label: 'Nacionalidad',
                      value: guessedPlayer.nationality,
                      isMatch: matchNationality,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAttributeCell(
                      label: 'Posición',
                      value: guessedPlayer.position,
                      isMatch: matchPosition,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAgeCell(
                      guessedAge: guessedPlayer.age,
                      isMatch: matchAge,
                      isTargetOlder: isTargetOlder,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAttributeCell(
                      label: 'Equipo Inicial',
                      value: guessedPlayer.initialTeam,
                      isMatch: matchInitial,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAttributeCell(
                      label: 'Equipo Actual',
                      value: guessedPlayer.currentTeam,
                      isMatch: matchCurrent,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCell({
    required String label,
    required String value,
    required bool isMatch,
  }) {
    final bgColor = isMatch ? const Color(0xFF0C2E1D) : const Color(0xFF2E1317);
    final borderColor =
        isMatch ? const Color(0xFF00E676) : const Color(0xFFFF5252).withAlpha(180);
    final textColor = isMatch ? const Color(0xFFE0FFE5) : const Color(0xFFFFCDD2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeCell({
    required int guessedAge,
    required bool isMatch,
    required bool isTargetOlder,
  }) {
    if (isMatch) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2E1D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00E676), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edad',
              style: TextStyle(fontSize: 9, color: Colors.white60),
            ),
            const SizedBox(height: 4),
            Text(
              '$guessedAge (=)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE0FFE5),
              ),
            ),
          ],
        ),
      );
    }

    final arrow = isTargetOlder ? '↑ Mayor' : '↓ Menor';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF33200B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edad',
            style: TextStyle(fontSize: 9, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            '$guessedAge $arrow',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFE082),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a single guess comparison row between guessed team and target team
class TeamGuessRow extends StatelessWidget {
  final Team guessedTeam;
  final Team targetTeam;

  const TeamGuessRow({
    super.key,
    required this.guessedTeam,
    required this.targetTeam,
  });

  @override
  Widget build(BuildContext context) {
    final bool matchCountry = guessedTeam.country.trim().toLowerCase() ==
        targetTeam.country.trim().toLowerCase();

    final bool matchLeague = guessedTeam.league.trim().toLowerCase() ==
        targetTeam.league.trim().toLowerCase();

    final bool isCorrect = guessedTeam.id == targetTeam.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121D28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223545)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, size: 16, color: Color(0xFFFFD54F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guessedTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isCorrect)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00E676)),
                  ),
                  child: const Text(
                    '¡CORRECTO!',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAttributeCell(
                  label: 'País',
                  value: guessedTeam.country,
                  isMatch: matchCountry,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttributeCell(
                  label: 'Liga',
                  value: guessedTeam.league,
                  isMatch: matchLeague,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCell({
    required String label,
    required String value,
    required bool isMatch,
  }) {
    final bgColor = isMatch ? const Color(0xFF0C2E1D) : const Color(0xFF2E1317);
    final borderColor =
        isMatch ? const Color(0xFF00E676) : const Color(0xFFFF5252).withAlpha(180);
    final textColor = isMatch ? const Color(0xFFE0FFE5) : const Color(0xFFFFCDD2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
