import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../../services/device_id_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  final DeviceIdService _deviceIdService = DeviceIdService();

  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    _deviceId = await _deviceIdService.getDeviceId();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error obteniendo identificador del dispositivo',
          ),
        ),
      );
      return;
    }

    final referralCode =
        _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim().toUpperCase();

    final result =
        await ref.read(authNotifierProvider.notifier).register(
              phoneNumber: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              imei: _deviceId,
              referralCode: referralCode,
            );

    if (!mounted) return;

    if (result != null) {
      context.goNamed('home');
      return;
    }

    final error = ref.read(authNotifierProvider).errorMessage;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    }
  }

  String? _validateReferralCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final clean = value.trim();

    if (clean.length != 6) {
      return 'El código debe tener 6 caracteres';
    }

    final regex = RegExp(r'^[a-zA-Z0-9]+$');

    if (!regex.hasMatch(clean)) {
      return 'Solo se permiten letras y números';
    }

    return null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                controller: _phoneController,
                label: 'Teléfono (8 dígitos)',
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _usernameController,
                label: 'Nombre de usuario',
                validator: Validators.username,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _referralCodeController,
                label: 'Código referido opcional',
                //textCapitalization: TextCapitalization.characters,
                validator: _validateReferralCode,
              ),
              const SizedBox(height: 8),
              const Text(
                'Si alguien te invitó a DriverAI, ingresa aquí su código de 6 caracteres.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              if (authState.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                CustomButton(
                  text: 'Registrarse',
                  onPressed: _handleRegister,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}