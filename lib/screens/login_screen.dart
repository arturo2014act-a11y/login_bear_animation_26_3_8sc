import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; // 3.1 Importar libreria para temporizador

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> { // <- Se agregó la llave { aquí
  // Control para mostrar u ocultar la contraseña
  bool _obscure = true;

  // 1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;
  // SMT: State Machine Input / Entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  // 3.2 VARIABLE PARA EL TEMPORIZADOR DE MIRADA
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al escribir 
  Timer? _typingdebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passWordFocus = FocusNode();

  // 4.1 Controles que sirven para validar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 4.2 Mostrar los errores de validacion
  String? _emailError;
  String? _passwordError;

  // 4.3 Funcion para validar el email y password
  final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  
  bool isValidEmail(String email) {
    return re.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final rePass = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return rePass.hasMatch(password);
  }

  // 4.4 Dar accion al boton
  void _login() {
    // De lo que escribio el usuario quitamos los espacios en blanco
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Evaluar los valores de email y password
    final errorEmail = isValidEmail(email) ? null : 'Invalid email format';
    final errorPassword = isValidPassword(password)
        ? null
        : 'Password invalid';

    // 4.7 Actualizar el estado de los errores
    setState(() {
      _emailError = errorEmail;
      _passwordError = errorPassword;
    });

    // 4.8 Cerrar el teclado y bajar las manos del oso
    FocusScope.of(context).unfocus();
    _typingdebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // 4.9 Si no hay errores, mostrar el trigger de exito
    if (errorEmail == null && errorPassword == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  } // <- Se agregó la llave de cierre de _login() aquí

  // 2.2 Listeners para saber cuando el usuario esta escribiendo en el campo de texto
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);
          _numLook?.value = 50.0;
        }
      }
    });

    _passWordFocus.addListener(() {
      _isHandsUp!.change(_passWordFocus.hasFocus);
      _typingdebounce?.cancel();
      _typingdebounce = Timer(const Duration(milliseconds: 500), () {
        _numLook?.value = 50.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

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
                const SizedBox(height: 10),

                // Campo de texto para el correo
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  onChanged: (value) {
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
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: _emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Campo de texto para la contraseña
                TextField(
                  controller: _passwordController,
                  focusNode: _passWordFocus,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                    if (_isHandsUp != null) {
                      _isHandsUp!.change(true);
                    }
                  },
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    errorText: _passwordError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4.12 Olvide mi contraseña
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ), // <- Paréntesis corregido
                const SizedBox(height: 10), // <- Coma agregada

                // 4.13 Botón de login
                MaterialButton(
                  onPressed: _login,
                  minWidth: size.width,
                  height: 50,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ), // <- Estructura del shape corregida
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 18),

                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Sign Up'),
                          style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                          color: Color.fromARGB(255, 5, 5, 5),
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //4.15 Liberar los controladores
    _emailFocus.dispose();
    _passWordFocus.dispose();
    //2.4 Liberar espacio de memoria 
    _emailController.dispose();
    _passwordController.dispose();
    _typingdebounce?.cancel();
    _controller?.dispose(); //3.9 eliminar el timer
    super.dispose();
  }
}