import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Control para mostrar u ocultar la contraseña
  bool _obscure = true;
  bool _isLoading = false;
  bool _showCelebration = false;

  // Cerebro de la animación Rive
  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  // Controladores de animación para resaltar la sonrisa del oso
  late AnimationController _bearScaleController;
  late Animation<double> _bearScaleAnimation;

  // Timer para mirada de Rive
  Timer? _typingdebounce;

  // FocusNodes
  final _emailFocus = FocusNode();
  final _passWordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _bearScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bearScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_bearScaleController);

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);
          _numLook?.value = 50.0;
        }
      } else {
        _isChecking?.change(false);
      }
    });

    _passWordFocus.addListener(() {
      _isHandsUp?.change(_passWordFocus.hasFocus);
      _typingdebounce?.cancel();
      _typingdebounce = Timer(const Duration(milliseconds: 500), () {
        _numLook?.value = 50.0;
      });
    });
  }

  // Lógica de inicio de sesión con Firebase Auth y reacción de Rive
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Quitar focos para bajar las manos si estaban arriba
    _emailFocus.unfocus();
    _passWordFocus.unfocus();
    _isHandsUp?.change(false);
    _isChecking?.change(false);

    if (email.isEmpty || password.isEmpty) {
      _trigFail?.fire();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa ambos campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Éxito: El osito sonríe y celebra (trigSuccess)
      _trigSuccess?.fire();
      if (mounted) {
        setState(() => _showCelebration = true);
        _bearScaleController.forward();
      }

      // Dejamos 2.2 segundos para ver completamente la sonrisa y efecto alegre del osito
      await Future.delayed(const Duration(milliseconds: 2200));

      // El AuthGate en main.dart detectará el cambio y pasará a HomeScreen automáticamente
    } on FirebaseAuthException catch (e) {
      // Error: Trigger de fallo del osito (sacudida de cabeza)
      _trigFail?.fire();

      String errorMsg = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMsg = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Formato de correo inválido.';
      } else if (e.message != null) {
        errorMsg = e.message!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _trigFail?.fire();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Diálogo para recuperación de contraseña (Fase 4)
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Recuperar Contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ingresa tu correo para recibir las instrucciones de restablecimiento:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa un correo válido')),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Correo de recuperación enviado. Revisa tu bandeja de entrada.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.message ?? 'Error al enviar correo'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) setDialogState(() => isSending = false);
                          }
                        },
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Indicador visual discreto de conexión exitosa con Firebase (Fase 1)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade400, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Firebase Conectado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Animación de Rive del oso con zoom y resplandor al sonreír
              AnimatedBuilder(
                animation: _bearScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bearScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _showCelebration
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.45),
                                  blurRadius: 35,
                                  spreadRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: size.width,
                  height: 220,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(artboard, 'Login Machine');
                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking = _controller?.findSMI('isChecking');
                      _isHandsUp = _controller?.findSMI('isHandsUp');
                      _trigSuccess = _controller?.findSMI('trigSuccess');
                      _trigFail = _controller?.findSMI('trigFail');
                      _numLook = _controller?.findSMI('numLook');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Email
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (_isHandsUp != null) _isHandsUp!.change(false);
                  if (_isChecking != null) {
                    _isChecking!.change(true);
                    final look = (value.length / 80 * 100).clamp(0, 100);
                    _numLook?.value = look.toDouble();

                    _typingdebounce?.cancel();
                    _typingdebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _numLook?.value = 50.0;
                      _isChecking?.change(false);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              // Campo Contraseña
              TextField(
                controller: _passwordController,
                focusNode: _passWordFocus,
                obscureText: _obscure,
                onChanged: (value) {
                  _isChecking?.change(false);
                  _isHandsUp?.change(true);
                },
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() => _obscure = !_obscure);
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),

              // Enlace Olvidé mi contraseña (Fase 4)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 8),

              // Botón Iniciar Sesión (Fase 2)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Enlace a Registro (Fase 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes una cuenta?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Regístrate aquí',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bearScaleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passWordFocus.dispose();
    _typingdebounce?.cancel();
    super.dispose();
  }
}
