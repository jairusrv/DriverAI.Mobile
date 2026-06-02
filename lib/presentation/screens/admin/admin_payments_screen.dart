import 'package:flutter/material.dart';

import '../../../data/datasources/remote/admin_payments_api.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final AdminPaymentsApi _api = AdminPaymentsApi();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payments = await _api.getPayments();

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los pagos.';
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePayment(int paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aprobar pago'),
        content: const Text(
          '¿Confirmas que este pago SINPE fue recibido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.approvePayment(paymentId);
      await _loadPayments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago aprobado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error aprobando pago: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _payments
        .where(
          (p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING',
        )
        .toList();

    final approved = _payments
        .where(
          (p) => (p['status'] ?? '').toString().toUpperCase() == 'APPROVED',
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos SINPE'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(pending, approved),
    );
  }

  Widget _buildBody(
    List<dynamic> pending,
    List<dynamic> approved,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Pendientes', pending.length),
          const SizedBox(height: 8),
          if (pending.isEmpty) const Text('No hay pagos pendientes.'),
          ...pending.map(_paymentCard),
          const SizedBox(height: 22),
          _sectionTitle('Aprobados', approved.length),
          const SizedBox(height: 8),
          ...approved.take(30).map(_paymentCard),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Text(
      '$title ($count)',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _paymentCard(dynamic raw) {
    final payment = Map<String, dynamic>.from(raw as Map);
    final id = payment['id'] as int;
    final status = payment['status']?.toString() ?? '';
    final isPending = status.toUpperCase() == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pago #$id',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _line('Usuario', '${payment['userId']}'),
            _line('Monto', '₡${payment['amount']}'),
            _line('Estado', status),
            _line('Proveedor', '${payment['provider']}'),
            _line('Referencia', '${payment['providerReference']}'),
            _line('SINPE', '${payment['sinpeReferenceNumber'] ?? '-'}'),
            _line('Desde', _formatDate(payment['paidFrom'])),
            _line('Hasta', _formatDate(payment['paidUntil'])),
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _approvePayment(id),
                  icon: const Icon(Icons.check),
                  label: const Text('Aprobar pago'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
