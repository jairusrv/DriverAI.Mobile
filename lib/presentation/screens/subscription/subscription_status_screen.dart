import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/subscription_provider.dart';
import '../../../data/models/subscription_info.dart';

class SubscriptionStatusScreen extends ConsumerStatefulWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  ConsumerState<SubscriptionStatusScreen> createState() =>
      _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState
    extends ConsumerState<SubscriptionStatusScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  SubscriptionInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final phoneNumber = await _storage.read(key: 'phone_number') ??
          await _storage.read(key: 'phoneNumber') ??
          await _storage.read(key: 'user_phone') ??
          await _storage.read(key: 'phone');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        setState(() {
          _error = 'No se encontró el teléfono de la sesión.';
          _isLoading = false;
        });
        return;
      }

      final api = ref.read(subscriptionApiProvider);

      final response = await api.getSubscriptionDetails(
        phoneNumber,
      );

      if (!response.success || response.data == null) {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _info = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el estado de la suscripción.';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyReferralCode(String code) async {
    await Clipboard.setData(
      ClipboardData(text: code),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Estado de suscripción'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadSubscription,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final info = _info;

    if (info == null) {
      return const Center(
        child: Text('No hay información disponible.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscription,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(info),
          const SizedBox(height: 16),
          _referralCard(info),
          const SizedBox(height: 16),
          if (info.lastReferralRewardMessage != null &&
              info.lastReferralRewardMessage!.isNotEmpty)
            _rewardCard(info.lastReferralRewardMessage!),
        ],
      ),
    );
  }

  Widget _statusCard(SubscriptionInfo info) {
    final statusText = info.hasAccess ? 'Acceso activo' : 'Suscripción vencida';

    final subtitle = info.isInTrial
        ? 'Estás usando tus 7 días gratis.'
        : info.isSubscriptionActive
            ? 'Suscripción mensual activa.'
            : 'Necesitas activar tu suscripción.';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.hasAccess ? Icons.check_circle : Icons.lock,
                color: info.hasAccess ? Colors.green : Colors.red,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${info.remainingDays}',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Center(
            child: Text(
              'días restantes',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _dateLine(
            'Fin de prueba',
            info.trialEndDate,
          ),
          _dateLine(
            'Vence suscripción',
            info.subscriptionExpiryDate,
          ),
        ],
      ),
    );
  }

  Widget _referralCard(SubscriptionInfo info) {
    final code = info.referralCode ?? '---';
    final progress = info.referralPaidCount % 5;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de referido',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comparte tu código. Cada 5 usuarios que paguen usando tu código te regalamos 30 días.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _copyReferralCode(code),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress / 5,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          Text(
            '$progress / 5 referidos pagados para ganar 30 días',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Premios recibidos: ${info.referralRewardCount}',
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard(String message) {
    return _card(
      color: Colors.green.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateLine(String label, DateTime? date) {
    final value = date == null
        ? 'No disponible'
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color color = Colors.white,
  }) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}
