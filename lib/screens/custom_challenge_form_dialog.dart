import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_challenge_model.dart';
import '../providers/game_provider.dart';

class CustomChallengeFormDialog extends StatefulWidget {
  final CustomChallenge? challenge;

  const CustomChallengeFormDialog({
    super.key,
    this.challenge,
  });

  @override
  State<CustomChallengeFormDialog> createState() =>
      _CustomChallengeFormDialogState();
}

class _CustomChallengeFormDialogState extends State<CustomChallengeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _targetNameController;
  late final TextEditingController _clue1Controller;
  late final TextEditingController _clue2Controller;
  late final TextEditingController _clue3Controller;

  String _category = 'player';
  bool _isLoading = false;

  bool get _isEditMode => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _titleController = TextEditingController(text: c?.title ?? '');
    _targetNameController = TextEditingController(text: c?.targetName ?? '');
    _clue1Controller = TextEditingController(text: c?.clue1 ?? '');
    _clue2Controller = TextEditingController(text: c?.clue2 ?? '');
    _clue3Controller = TextEditingController(text: c?.clue3 ?? '');
    _category = c?.category ?? 'player';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetNameController.dispose();
    _clue1Controller.dispose();
    _clue2Controller.dispose();
    _clue3Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<GameProvider>();

    try {
      if (_isEditMode) {
        final updated = widget.challenge!.copyWith(
          title: _titleController.text.trim(),
          targetName: _targetNameController.text.trim(),
          category: _category,
          clue1: _clue1Controller.text.trim(),
          clue2: _clue2Controller.text.trim(),
          clue3: _clue3Controller.text.trim(),
        );
        await provider.updateCustomChallenge(updated);
      } else {
        final newChallenge = CustomChallenge(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          title: _titleController.text.trim(),
          targetName: _targetNameController.text.trim(),
          category: _category,
          clue1: _clue1Controller.text.trim(),
          clue2: _clue2Controller.text.trim(),
          clue3: _clue3Controller.text.trim(),
        );
        await provider.addCustomChallenge(newChallenge);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF102820),
            content: Text(
              _isEditMode
                  ? '✅ Desafío editado con éxito.'
                  : '✅ Nuevo desafío creado con éxito.',
              style: const TextStyle(color: Color(0xFF00E676)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E1719),
            content: Text('Error al guardar: $e',
                style: const TextStyle(color: Color(0xFFFF8A80))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF14212D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF223545)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Icon(
                        _isEditMode ? Icons.edit_note : Icons.add_circle_outline,
                        color: const Color(0xFF00E676),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Editar Desafío'
                              : 'Crear Desafío Personalizado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Define un desafío personalizado para ti o tu grupo. Se sincronizará con la tabla Supabase con RLS.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      const Text(
                        'Categoría: ',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      ChoiceChip(
                        label: const Text('Jugador'),
                        selected: _category == 'player',
                        selectedColor: const Color(0xFF00E676),
                        onSelected: (val) {
                          if (val) setState(() => _category = 'player');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Equipo'),
                        selected: _category == 'team',
                        selectedColor: const Color(0xFFFFD54F),
                        onSelected: (val) {
                          if (val) setState(() => _category = 'team');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Trivia'),
                        selected: _category == 'trivia',
                        selectedColor: const Color(0xFF81D4FA),
                        onSelected: (val) {
                          if (val) setState(() => _category = 'trivia');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Field 1: Title
                  TextFormField(
                    key: const Key('challenge_title_field'),
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Título del Desafío',
                      hint: 'Ej: El Rey Arturo, El Matador, La Máquina...',
                      icon: Icons.title,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El título es obligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'El título debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Field 2: Target Name (Secret answer)
                  TextFormField(
                    key: const Key('challenge_target_name_field'),
                    controller: _targetNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Nombre Secreto (Respuesta correcta)',
                      hint: 'Ej: Arturo Vidal, Colo-Colo, Lionel Messi...',
                      icon: Icons.vpn_key_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre secreto es obligatorio';
                      }
                      if (value.trim().length < 2) {
                        return 'Debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Field 3: Clue 1
                  TextFormField(
                    key: const Key('challenge_clue1_field'),
                    controller: _clue1Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Pista 1 (ej: Nacionalidad / País de origen)',
                      hint: 'Ej: Chile, Argentina, Inglaterra...',
                      icon: Icons.public,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La pista 1 es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Field 4: Clue 2
                  TextFormField(
                    key: const Key('challenge_clue2_field'),
                    controller: _clue2Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Pista 2 (ej: Posición / Liga)',
                      hint: 'Ej: Mediocampista, Delantero, Serie A...',
                      icon: Icons.sports,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La pista 2 es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Field 5: Clue 3
                  TextFormField(
                    key: const Key('challenge_clue3_field'),
                    controller: _clue3Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Pista 3 (ej: Club actual / Trayectoria)',
                      hint: 'Ej: Debut en Cobreloa, Colo-Colo 2006...',
                      icon: Icons.military_tech_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La pista 3 es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        key: const Key('challenge_save_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isEditMode ? 'Guardar Cambios' : 'Crear Desafío',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF00E676), size: 20),
      filled: true,
      fillColor: const Color(0xFF0E1721),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF223545)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF223545)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00E676)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF5252)),
      ),
    );
  }
}

/// Modal dialog to view and play a custom challenge
class CustomChallengeDetailDialog extends StatelessWidget {
  final CustomChallenge challenge;

  const CustomChallengeDetailDialog({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF14212D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF223545)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_soccer,
                      color: Color(0xFF00E676), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF223545), height: 20),
              _buildClueRow('Categoría', challenge.category.toUpperCase(),
                  Icons.category, const Color(0xFF81D4FA)),
              const SizedBox(height: 10),
              _buildClueRow('Pista 1', challenge.clue1, Icons.public,
                  const Color(0xFF00E676)),
              const SizedBox(height: 10),
              _buildClueRow('Pista 2', challenge.clue2, Icons.sports,
                  const Color(0xFFFFD54F)),
              const SizedBox(height: 10),
              _buildClueRow('Pista 3', challenge.clue3, Icons.military_tech,
                  const Color(0xFFFFAB91)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1721),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Respuesta:',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      challenge.targetName,
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar',
                      style: TextStyle(color: Color(0xFF00E676))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClueRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
