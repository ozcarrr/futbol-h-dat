import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';

class AutocompleteSearch<T extends Object> extends StatelessWidget {
  final List<T> items;
  final String hintText;
  final List<String> excludedIds;
  final String Function(T item) itemId;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final ValueChanged<T> onSelected;
  final bool enabled;

  const AutocompleteSearch({
    super.key,
    required this.items,
    required this.hintText,
    required this.itemId,
    required this.itemLabel,
    required this.onSelected,
    this.itemSubtitle,
    this.excludedIds = const [],
    this.enabled = true,
  });

  /// Factory helper for Player searching
  static AutocompleteSearch<Player> forPlayers({
    Key? key,
    required List<Player> players,
    required ValueChanged<Player> onSelected,
    String hintText = 'Escribe el nombre del jugador...',
    List<String> excludedIds = const [],
    bool enabled = true,
  }) {
    return AutocompleteSearch<Player>(
      key: key,
      items: players,
      hintText: hintText,
      excludedIds: excludedIds,
      itemId: (p) => p.id,
      itemLabel: (p) => p.name,
      itemSubtitle: (p) =>
          '${p.nationality} • ${p.position} • ${p.currentTeam}',
      onSelected: onSelected,
      enabled: enabled,
    );
  }

  /// Factory helper for Team searching
  static AutocompleteSearch<Team> forTeams({
    Key? key,
    required List<Team> teams,
    required ValueChanged<Team> onSelected,
    String hintText = 'Escribe el nombre del equipo...',
    List<String> excludedIds = const [],
    bool enabled = true,
  }) {
    return AutocompleteSearch<Team>(
      key: key,
      items: teams,
      hintText: hintText,
      excludedIds: excludedIds,
      itemId: (t) => t.id,
      itemLabel: (t) => t.name,
      itemSubtitle: (t) => '${t.country} • ${t.league}',
      onSelected: onSelected,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      displayStringForOption: itemLabel,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!enabled || textEditingValue.text.trim().isEmpty) {
          return const Iterable.empty();
        }

        final query = textEditingValue.text.toLowerCase().trim();
        return items.where((item) {
          final id = itemId(item);
          if (excludedIds.contains(id)) return false;
          final label = itemLabel(item).toLowerCase();
          return label.contains(query);
        });
      },
      onSelected: (T selection) {
        onSelected(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: enabled,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00E676)),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: textEditingController,
              builder: (context, value, _) {
                if (value.text.isNotEmpty && enabled) {
                  return IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white54),
                    onPressed: () {
                      textEditingController.clear();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            filled: true,
            fillColor: const Color(0xFF14212D),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF223545)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF223545)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF00E676), width: 1.8),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<T> onSelectedCallback,
        Iterable<T> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF14212D),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 280, maxWidth: 550),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Color(0xFF223545), height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final T option = options.elementAt(index);
                  final label = itemLabel(option);
                  final subtitle =
                      itemSubtitle != null ? itemSubtitle!(option) : null;

                  return InkWell(
                    onTap: () {
                      onSelectedCallback(option);
                    },
                    hoverColor: const Color(0xFF1E3A2F),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              size: 16,
                              color: Color(0xFF00E676),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: Colors.white30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
