import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<GameProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegisterMode) {
        await provider.register(email, password);
      } else {
        await provider.login(email, password);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF102820),
            content: Text(
              _isRegisterMode
                  ? '✅ ¡Cuenta creada e iniciada con éxito!'
                  : '✅ ¡Bienvenido a FutboLE!',
              style: const TextStyle(color: Color(0xFF00E676)),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseAuthError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseAuthError(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('invalid login credentials') ||
        str.contains('invalid_credentials')) {
      return 'Credenciales inválidas o la cuenta no existe. Si es una cuenta nueva, cambia abajo a "Crear Cuenta". Si ya la creaste antes, desactiva "Confirm email" en Supabase.';
    }
    if (str.contains('email rate limit') ||
        str.contains('over_email_send_rate_limit')) {
      return 'Límite de correos de Supabase alcanzado. En tu panel de Supabase ve a Authentication -> Providers -> Email y desactiva la casilla "Confirm email".';
    }
    if (str.contains('email not confirmed') ||
        str.contains('email_not_confirmed')) {
      return 'El correo no ha sido confirmado. En tu panel de Supabase (Authentication -> Providers -> Email) desactiva la casilla "Confirm email" para entrar directamente.';
    }
    if (str.contains('user already registered') ||
        str.contains('user_already_exists')) {
      return 'Este correo ya está registrado en Supabase. Cambia abajo a "Iniciar Sesión" e ingresa tu contraseña.';
    }
    if (str.contains('email address') && str.contains('invalid')) {
      return 'Dirección de correo rechazada por el servidor de Supabase. Usa un formato estándar como usuario@gmail.com.';
    }
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('AuthApiException: ', '')
        .replaceFirst('AuthUnknownException: ', '');
  }

  Future<void> _loginDemoMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<GameProvider>();
    try {
      await provider.login('demo.futbol@udd.cl', 'password123');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF102820),
            content: Text(
              '⚽ Sesión Demo iniciada correctamente.',
              style: TextStyle(color: Color(0xFF00E676)),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _parseAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Crear Cuenta' : 'Iniciar Sesión'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: const Color(0xFF14212D),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFF223545)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer,
                              color: Color(0xFF00E676), size: 32),
                          SizedBox(width: 10),
                          Text(
                            'FutboLE Auth',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Regístrate con Supabase para gestionar tus desafíos personalizados con políticas RLS.'
                            : 'Inicia sesión para sincronizar tu historial y desafíos.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E1719),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF5252)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFFF8A80), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field with Validation
                      TextFormField(
                        key: const Key('auth_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Color(0xFF00E676)),
                          filled: true,
                          fillColor: const Color(0xFF0E1721),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF223545)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF223545)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF00E676)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          final email = value.trim();
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Ingresa un correo electrónico válido (ej: usuario@correo.cl)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field with Validation
                      TextFormField(
                        key: const Key('auth_password_field'),
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFF00E676)),
                          filled: true,
                          fillColor: const Color(0xFF0E1721),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF223545)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF223545)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF00E676)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        key: const Key('auth_submit_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isRegisterMode
                                    ? 'Crear Cuenta en Supabase'
                                    : 'Iniciar Sesión',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Switch Register / Login Mode
                      TextButton(
                        key: const Key('auth_toggle_mode_button'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF81D4FA),
                        ),
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isRegisterMode
                              ? '¿Ya tienes cuenta? Inicia sesión aquí'
                              : '¿No tienes cuenta? Regístrate aquí',
                        ),
                      ),
                      const Divider(color: Color(0xFF223545), height: 28),

                      // Quick Demo Mode Button
                      OutlinedButton.icon(
                        key: const Key('auth_demo_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD54F),
                          side: const BorderSide(color: Color(0xFFFFD54F)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _loginDemoMode,
                        icon: const Icon(Icons.bolt, color: Color(0xFFFFD54F)),
                        label: const Text(
                          'Entrar en Modo Demo Rápido',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
