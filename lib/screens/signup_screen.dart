import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Control de foco
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passWordFocus = FocusNode();
  final _confirmPassWordFocus = FocusNode();

  // Animación Rive del oso
  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;
  Timer? _typingdebounce;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Cuando enfoca el Nombre: manos abajo y listo para seguir la mirada
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      } else {
        _isChecking?.change(false);
      }
    });

    // Cuando enfoca el Email: manos abajo y listo para seguir el texto
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      } else {
        _isChecking?.change(false);
      }
    });

    // Cuando enfoca Contraseña: se tapa los ojos
    _passWordFocus.addListener(() {
      if (_passWordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(true);
      } else if (!_confirmPassWordFocus.hasFocus) {
        _isHandsUp?.change(false);
      }
    });

    // Cuando enfoca Confirmar Contraseña: se tapa los ojos
    _confirmPassWordFocus.addListener(() {
      if (_confirmPassWordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(true);
      } else if (!_passWordFocus.hasFocus) {
        _isHandsUp?.change(false);
      }
    });
  }

  Future<void> _signUp() async {
    // Quitar focos
    _nameFocus.unfocus();
    _emailFocus.unfocus();
    _passWordFocus.unfocus();
    _confirmPassWordFocus.unfocus();
    _isHandsUp?.change(false);
    _isChecking?.change(false);

    if (!_formKey.currentState!.validate()) {
      _trigFail?.fire();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;

      // 2. Guardar datos en Cloud Firestore (resiliente)
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'nombre': _nameController.text.trim(),
            'email': user.email,
            'fecha_registro': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('Firestore aviso: $e');
        }
      }

      // 3. Osito sonríe y celebra éxito
      _trigSuccess?.fire();
      await Future.delayed(const Duration(milliseconds: 1800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      _trigFail?.fire();
      String mensajeError = 'Ocurrió un error al registrarse';
      if (e.code == 'email-already-in-use') {
        mensajeError = 'Este correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        mensajeError = 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'El formato del correo es inválido.';
      } else if (e.message != null) {
        mensajeError = e.message!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passWordFocus.dispose();
    _confirmPassWordFocus.dispose();
    _typingdebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animación Rive del osito en la pantalla de Registro
                SizedBox(
                  width: size.width,
                  height: 200,
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
                const SizedBox(height: 12),
                const Text(
                  'Registro de Usuario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Nombre con seguimiento de mirada del osito
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  onChanged: (value) {
                    if (_isHandsUp != null) _isHandsUp!.change(false);
                    if (_isChecking != null) {
                      _isChecking!.change(true);
                      final look = (value.length / 50 * 100).clamp(0, 100);
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
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Email con seguimiento de mirada del oso
                TextFormField(
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Contraseña (manos arriba)
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passWordFocus,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    _isChecking?.change(false);
                    _isHandsUp?.change(true);
                  },
                  decoration: InputDecoration(
                    labelText: 'Contraseña (mínimo 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 14),

                // Confirmar Contraseña (manos arriba)
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPassWordFocus,
                  obscureText: _obscureConfirm,
                  onChanged: (value) {
                    _isChecking?.change(false);
                    _isHandsUp?.change(true);
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Botón Registrarse
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
