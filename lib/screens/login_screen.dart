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
      body: SafeArea(
        // Permite hacer scroll cuando aparece el teclado (evita overflow)
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              SizedBox(
                width: screenSize.width,
                height: 200,
                child: const RiveAnimation.asset(
                  'assets/carlos.riv',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),

              // Email
              TextField(
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
    );
  }
}