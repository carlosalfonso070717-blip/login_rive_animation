import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; // Importar el timer

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

  // Timer para detener el recorrido de la mirada después de 3 segundos
  Timer? typingDebounce;
  

  //Crear variables para FocusNode (Examen: que es un FocusNode (para que un campo de texto esté resaltado) y el ciclo de vida de un widget)
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //4.1 Controles para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para mostrar al usuario
  String? emailError;
  String? passError;

   // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Acción del botón de login
  void _onLogin(){
    //Recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalcular errores
    final emailTypedError = isValidEmail(email) ? null : 'Email inválido';
    final passTypedError = isValidPassword(pass) ? null : 'Contraseña inválida';

    //4.5 Para mostrar el cambio
    setState(() {
      emailError = emailTypedError;
      passError = passTypedError;
    });

    //4.6 Cerrar el teclado y oso neutro
    FocusScope.of(context).unfocus();
    typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.7 Activar triggers
    if(emailTypedError == null && passTypedError == null){
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  @override
  void initState() {
    super.initState();
  
    // Agregar listeners a los FocusNode
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        // El campo de email tiene el foco
        if (_isHandsUp != null) {
          _isHandsUp!.change(false);

          //Mirada neutral
          _numLook?.value = 50.0;
        }
        if (_isChecking != null) {
          _isChecking!.change(true);
        }
      } else {
        // El campo de email perdió el foco
        if (_isChecking != null) {
          _isChecking!.change(false);
        }
      }
    });

    _passwordFocusNode.addListener(() {
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }




  /// Controladores para leer el texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                  controller: emailCtrl,
                  //Agregar el FocusNode al TextField
                  focusNode: _emailFocusNode,
                  onChanged: (value){
                    if(_isHandsUp != null){
                      // No tapes los ojos al ver el email
                      //_isHandsUp!.change(false);
                    }
                    // Si isHandsUp es nulo, no hacemos nada
                    if(_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);

                    //Implementar recorrido de mirada
                    //Ajuste de límites del 0 al 100
                    //80 medida de calibración. Clamp es una función que limita un valor a un rango específico
                    final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);

                    _numLook?.value = look;

                    //Debounce: si vuelve a teclear antes de 3 segundos, reinicia el timer
                    typingDebounce?.cancel();

                    //Crear nuevo timer
                    typingDebounce = Timer(const Duration(seconds: 3), () {
                      if(!mounted) return;

                      // Mirada neutra
                      _isChecking?.change(false);

                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    errorText: emailError,
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
                  controller: passCtrl,
                  //Agregar el FocusNode al TextField
                  focusNode: _passwordFocusNode,
                  onChanged: (value){
                    if(_isChecking != null){
                      // No actives el modo chismoso mientras escribes la contraseña
                      //_isChecking!.change(false);
                    }
                    if(_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    errorText: passError,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot Password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),

                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  onPressed: _onLogin,
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: const Text('Login'),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Don't have an account?"),
                      SizedBox(width: 5),
                      Text(
                        "Sign Up",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                  ),
              ],

            ),
          ),
        ),
      ),
    );
  } 
  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    typingDebounce?.cancel();

    // Liberar memoria de los FocusNode
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }
}
