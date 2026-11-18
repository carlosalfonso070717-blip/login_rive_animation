import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _domain = '@tecdesoftware.edu.mx';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  // Reglas de la contraseña (se muestran en pantalla)
  bool get _hasLength => _passCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passCtrl.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_passCtrl.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_passCtrl.text);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_passCtrl.text);

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'El correo es obligatorio';
    final basic = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!basic.hasMatch(email)) return 'Escribe un correo válido';
    if (!email.endsWith(_domain)) {
      return 'Usa tu correo institucional ($_domain)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) return 'La contraseña es obligatoria';
    if (!(_hasLength && _hasUpper && _hasLower && _hasDigit && _hasSymbol)) {
      return 'La contraseña no cumple todas las reglas';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
    if (value != _passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // Firebase inicia sesión solo al crear la cuenta; cerramos para volver al Login
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada correctamente. Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // regresa al Login
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp error: ${e.code}');
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Ese correo ya está registrado.';
          break;
        case 'weak-password':
          msg = 'La contraseña es muy débil.';
          break;
        case 'invalid-email':
          msg = 'El correo no es válido.';
          break;
        default:
          msg = 'No se pudo crear la cuenta. Inténtalo de nuevo.';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('SignUp error: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo crear la cuenta. Inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: ok ? Colors.green : Colors.black54),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Correo institucional',
                    hintText: 'usuario$_domain',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _rule('Mínimo 8 caracteres', _hasLength),
                _rule('Una letra mayúscula', _hasUpper),
                _rule('Una letra minúscula', _hasLower),
                _rule('Un número', _hasDigit),
                _rule('Un símbolo (por ejemplo ! . # \$)', _hasSymbol),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    height: 50,
                    color: Colors.blue,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: _isLoading ? null : _onRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign up'),
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