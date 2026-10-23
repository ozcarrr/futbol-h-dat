import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futbole/models/player_model.dart';
import 'package:futbole/models/team_model.dart';

/// Resolves a network URL for safe web rendering by using wsrv.nl proxy
/// when necessary to bypass browser CORS blocking on Flutter Web CanvasKit.
String resolveSafeWebUrl(String url) {
  if (url.isEmpty) return '';
  if (kIsWeb && (url.contains('thesportsdb.com') || url.contains('r2.thesportsdb.com'))) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
  }
  return url;
}

/// Returns an [ImageProvider] for a [Team] shield.
/// Prefers high-resolution bundled local asset if available (t1-t25),
/// otherwise falls back to a CORS-safe network image.
ImageProvider? getTeamBadgeProvider(Team team) {
  final numMatch = RegExp(r'^t(\d+)$').firstMatch(team.id);
  if (numMatch != null) {
    final idx = int.tryParse(numMatch.group(1)!);
    if (idx != null && idx >= 1 && idx <= 25) {
      return AssetImage('assets/badges/${team.id}.png');
    }
  }
  if (team.logoUrl.isNotEmpty) {
    return NetworkImage(resolveSafeWebUrl(team.logoUrl));
  }
  return null;
}

/// Returns an [ImageProvider] for a [Player] photo.
/// Prefers bundled local asset if available (p1-p10),
/// otherwise falls back to a CORS-safe network image if not empty.
ImageProvider? getPlayerImageProvider(Player player) {
  final numMatch = RegExp(r'^p(\d+)$').firstMatch(player.id);
  if (numMatch != null) {
    final idx = int.tryParse(numMatch.group(1)!);
    if (idx != null && idx >= 1 && idx <= 10) {
      return AssetImage('assets/players/${player.id}.jpg');
    }
  }
  if (player.imageUrl.isNotEmpty) {
    return NetworkImage(resolveSafeWebUrl(player.imageUrl));
  }
  return null;
}

/// A dedicated, fail-safe widget for rendering club crests / shields.
/// Automatically handles local assets (t1-t25), web CORS proxying,
/// smooth scaling in CanvasKit, and a stylish fallback icon.
class TeamBadge extends StatelessWidget {
  final Team team;
  final double? width;
  final double? height;
  final BoxFit fit;

  const TeamBadge({
    super.key,
    required this.team,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final numMatch = RegExp(r'^t(\d+)$').firstMatch(team.id);
    if (numMatch != null) {
      final idx = int.tryParse(numMatch.group(1)!);
      if (idx != null && idx >= 1 && idx <= 25) {
        return Image.asset(
          'assets/badges/${team.id}.png',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      }
    }

    if (team.logoUrl.isNotEmpty) {
      return Image.network(
        resolveSafeWebUrl(team.logoUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final iconSize = (width != null && height != null) ? (width! * 0.45) : 70.0;
    return Icon(
      Icons.shield,
      size: iconSize,
      color: const Color(0xFFFFD54F),
    );
  }
}

/// A dedicated, fail-safe widget for rendering player photos.
/// Automatically handles local assets (p1-p10), web CORS proxying,
/// and graceful fallback for players with blank image URLs.
class PlayerPhoto extends StatelessWidget {
  final Player player;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PlayerPhoto({
    super.key,
    required this.player,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final numMatch = RegExp(r'^p(\d+)$').firstMatch(player.id);
    if (numMatch != null) {
      final idx = int.tryParse(numMatch.group(1)!);
      if (idx != null && idx >= 1 && idx <= 10) {
        return Image.asset(
          'assets/players/${player.id}.jpg',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      }
    }

    if (player.imageUrl.isNotEmpty) {
      return Image.network(
        resolveSafeWebUrl(player.imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final iconSize = (width != null && height != null) ? (width! * 0.5) : 36.0;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF14212D),
      child: Center(
        child: Icon(Icons.person, size: iconSize, color: Colors.white60),
      ),
    );
  }
}

