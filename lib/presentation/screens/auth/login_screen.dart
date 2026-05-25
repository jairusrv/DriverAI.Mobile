import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authNotifierProvider.notifier).login(
            _phoneController.text.trim(),
            _passwordController.text,
          );
      if (success && mounted) {
        context.goNamed('home');
      } else if (mounted) {
        final error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Error al iniciar sesión')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('DriverAI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              CustomTextField(
                controller: _phoneController,
                label: 'Teléfono (8 dígitos)',
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 24),
              if (authState.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                CustomButton(text: 'Iniciar sesión', onPressed: _handleLogin),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pushNamed('register'),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}