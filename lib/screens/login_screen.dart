import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar libreria para temporizador

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Control para mostrar u ocultar la contraseña
  bool _obscure = true;

  //1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;
  //SMT: State Machine Input / Entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  //3.2 VARIABLE PARA EL TEMPORIZADOR DE MIRADA
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada al escribir 
  Timer? _typingdebounce;

  //2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode(); //Se llama node por un foco de cosas que puede hacer
  final _passWordFocus = FocusNode();

  //2.2 Listeners (Oyentes/chismosos) para saber cuando el usuario esta escribiendo en el campo de texto
  @override
  void initState() {
    super.initState();
    
    _emailFocus.addListener((){
      if (_emailFocus.hasFocus) {
        //Verificar que no sea nulo
        if (_isHandsUp != null) {
          //Manos abajo en el email
          _isHandsUp!.change(false);
          //3.4 Mirada neutra
          _numLook?.value = 50.0;
        }
      }
    });
    
    _passWordFocus.addListener((){
      //Manos arriba en el password
      _isHandsUp!.change(_passWordFocus.hasFocus);
      //3.5 Detener la mirada al escribir
      _typingdebounce?.cancel();
      _typingdebounce = Timer(const Duration(milliseconds: 500), (){
        _numLook?.value = 50.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',
                  stateMachines: const ['Login Machine'],
                  //1.2 Vincular Animacion
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard, 'Login Machine'
                    );

                    //1.3 Verificar que el controlador no sea nulo
                    if (_controller == null) return;
                    //Agrega el controlador al escenario/tablero
                    artboard.addController(_controller!);
                    //Vinculamos variables
                    _isChecking = _controller?.findSMI('isChecking');
                    _isHandsUp = _controller?.findSMI('isHandsUp');
                    _trigSuccess = _controller?.findSMI('trigSuccess');
                    _trigFail = _controller?.findSMI('trigFail');
                    //3.6 Vincular la variable de mirada
                    _numLook = _controller?.findSMI('numLook');
                  }
                )
              ),
              //Sizedbox para separar espacios
              const SizedBox(height: 10),
              //Campo de texto para el correo
              TextField(
                focusNode: _emailFocus,
                onChanged: (value){
                  if (_isHandsUp != null) {
                    //No tapes los ojos al ver email
                    //_isHandsUp!.change(false);
                  }
                  //Si isChecking no es nulo, cambiar el valor de la variable
                  if (_isChecking != null) {
                    //Activar modo chismoso
                    _isChecking!.change(true);
                    //implementar el numLook
                    //80 es la medida de calibración
                    final look = (value.length / 80 * 100).clamp(0, 100);
                    //clamp es el rango abrazadera
                    _numLook?.value = look.toDouble();
                    
                    //3.7 Detener la mirada al escribir
                    _typingdebounce?.cancel();
                    _typingdebounce = Timer(const Duration(seconds: 3),
                      () {
                        //si se cierra la pantalla se cierra el contador
                        if (!mounted) return;
                        
                        //3.8 Mirada neutra y dejar de chequear
                        _numLook?.value = 50.0; // Resetea la posición horizontal de los ojos al centro
                        _isChecking?.change(false); // Detiene el modo de seguimiento
                      }
                    );
                  }
                },
                //para mostrar el tipo de teclado
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //Redondeo de bordes
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
              const SizedBox(height: 10),
              //Campo de texto para la contraseña
              TextField(
                //2.3 Asigna el foco al campo de texto
                focusNode: _passWordFocus,
                onChanged: (value){
                  if (_isChecking != null) {
                    //No tapes los ojos al ver email
                    _isChecking!.change(false);
                  }
                  //Si isChecking no es nulo, cambiar el valor de la variable
                  if (_isHandsUp != null) {
                    //Activar modo chismoso
                    _isHandsUp!.change(true);
                  }
                },
                obscureText: _obscure,
                //para mostrar el tipo de teclado
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  //Operador ternario
                  suffixIcon: IconButton(
                    //If ternario
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //Refrescar el estado del widget
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    //Redondeo de bordes
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //2.4 Liberar memoria al salir de la pantalla para liberar el foco
    _emailFocus.dispose();
    _passWordFocus.dispose();
    _typingdebounce?.cancel(); //eliminar el timmer
    super.dispose();
  }
}