import 'package:flutter/material.dart';

import '../../../data/datasources/remote/sinpe_payment_api.dart';

class ReportSinpePaymentScreen extends StatefulWidget {
  const ReportSinpePaymentScreen({super.key});

  @override
  State<ReportSinpePaymentScreen> createState() =>
      _ReportSinpePaymentScreenState();
}

class _ReportSinpePaymentScreenState
    extends State<ReportSinpePaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController(text: '3000');
  final _phoneController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  final _api = SinpePaymentApi();

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _api.reportSinpePayment(
        amount: double.parse(_amountController.text.trim()),
        sinpeSenderPhone: _phoneController.text.trim(),
        sinpeReferenceNumber: _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pago reportado. Quedará pendiente de aprobación.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reportando pago: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requerido';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    final required = _required(value);
    if (required != null) return required;

    final amount = double.tryParse(value!.trim());

    if (amount == null || amount <= 0) {
      return 'Monto inválido';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final required = _required(value);
    if (required != null) return required;

    final clean = value!.trim();

    if (clean.length != 8 || int.tryParse(clean) == null) {
      return 'Debe tener 8 dígitos';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Reportar pago SINPE'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            _formCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSaving ? 'Enviando...' : 'Reportar pago',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pago por SINPE Móvil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Después de hacer el SINPE, completa este formulario. '
              'Tu pago quedará pendiente hasta que sea confirmado.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'SINPE: 8888-8888',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto pagado',
                prefixText: '₡ ',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono desde donde enviaste el SINPE',
                border: OutlineInputBorder(),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Número de comprobante o referencia',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas opcionales',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}