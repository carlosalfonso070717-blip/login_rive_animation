import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controla si la contraseña se muestra u oculta
  bool _isObscure = true;

  //1.1 Máquina estado de la animación
  StateMachineController? _controller;

  //StateMachineInput
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  /// Controladores para leer el texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Obtiene el tamaño de la pantalla del dispositivo
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          // Permite hacer scroll cuando aparece el teclado (evita overflow)
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/carlos.riv',
                    stateMachines: ['Login Machine'],
                    //1.2 vincular la animación con la máquina de estado
                    onInit: (artboard){
                      _controller = StateMachineController.fromArtboard(
                        artboard, 
                        'Login Machine'
                      );

                      //1.3 Verificar que inició bien
                      if(_controller == null) return;
                      //Agregar el controlador al artboard
                      artboard.addController(_controller!);
                      //Vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },


                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
        
                // Email
                TextField(
                  onChanged: (value){
                    if(_isHandsUp != null){
                      // No tapes los ojos al ver el email
                      _isHandsUp!.change(false);
                    }
                    // Si isHandsUp es nulo, no hacemos nada
                    if(_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                  },
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
        
                // Contraseña
                TextField(
                  onChanged: (value){
                    if(_isChecking != null){
                      // No actives el modo chismoso mientras escribes la contraseña
                      _isChecking!.change(false);
                    }
                    if(_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  controller: _passwordController,
                  obscureText: _isObscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
        
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
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