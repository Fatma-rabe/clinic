import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/doctor/presentation/doctor_shell_screen.dart';
import '../../features/finance/presentation/financial_dashboard_screen.dart';
import '../../features/reception/presentation/reception_shell_screen.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final user = authAsync.valueOrNull;

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return user.isDoctor ? '/doctor' : '/reception';
      }

      if (user.isDoctor &&
          state.matchedLocation.startsWith('/reception')) {
        return '/doctor';
      }
      if (user.isReceptionist && state.matchedLocation.startsWith('/doctor')) {
        return '/reception';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/reception',
        builder: (context, state) => const ReceptionShellScreen(),
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorShellScreen(),
      ),
      GoRoute(
        path: '/doctor/finance',
        builder: (context, state) => const FinancialDashboardScreen(),
      ),
    ],
  );
});

/// Bridges Firebase auth stream to GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
