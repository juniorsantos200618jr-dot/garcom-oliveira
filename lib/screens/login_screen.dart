import 'package:flutter/material.dart';
import '../services/app_store.dart';
import 'tables_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _login() async {
    final user = userCtrl.text.trim();
    final pass = passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe usuario e senha.')),
      );
      return;
    }

    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final account = AppStore.instance.authenticate(user, pass);
    if (!mounted) return;
    setState(() => loading = false);

    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario ou senha invalidos, ou acesso desativado.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TablesScreen(account: account)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.restaurant_menu, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Garcom Oliveira',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Entre com seu acesso de Administrador ou Garcom.', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  TextField(
                    controller: userCtrl,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: loading ? null : _login,
                    icon: const Icon(Icons.login),
                    label: Text(loading ? 'Entrando...' : 'Entrar'),
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
