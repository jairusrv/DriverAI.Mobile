import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../presentation/providers/auth_provider.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const VerifyCodeScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isResending = false;

  String get _fullCode => _codeControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_fullCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de 6 dígitos')),
      );
      return;
    }
    final success = await ref.read(authNotifierProvider.notifier).verifyCode(
          widget.phoneNumber,
          _fullCode,
        );
    if (success && mounted) {
      context.goNamed('home');
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Código incorrecto')),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendCode(widget.phoneNumber);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nuevo código enviado a tu teléfono')),
        );
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Error al reenviar código')),
        );
      }
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Verificar código'),
          automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Hemos enviado un código SMS al número +506${widget.phoneNumber}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextFormField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24),
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            if (authState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              CustomButton(text: 'Verificar', onPressed: _verify),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isResending ? null : _resendCode,
              child: _isResending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}
