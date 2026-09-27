import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error = await ref.read(authServiceProvider).loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Hero(
                    tag: 'app_logo',
                    child: Icon(Icons.brush_rounded, size: 100, color: Color(0xFF7C4DFF)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'KROKI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dessinez. Devinez. Gagnez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                  ),
                  const SizedBox(height: 50),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('SE CONNECTER'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      context.push('/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Pas encore de compte ? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        children: const [
                          TextSpan(
                            text: "S'inscrire",
                            style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
