import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_code_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/subscription/subscription_status_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-code',
      name: 'verify-code',
      builder: (context, state) {
        final phoneNumber = state.extra as String;
        return VerifyCodeScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/subscription',
      name: 'subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/subscription-status',
      name: 'subscription-status',
      builder: (context, state) => const SubscriptionStatusScreen(),
    ),
  ],
);
