import 'package:go_router/go_router.dart';

import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/properties/views/properties_screen.dart';
import '../features/tenants/views/tenants_screen.dart';
import '../features/finances/views/finances_screen.dart';
import '../features/communications/views/communications_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  
  static const String dashboard = '/dashboard';
  static const String properties = '/properties';
  static const String tenants = '/tenants';
  static const String finances = '/finances';
  static const String communications = '/communications';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: properties,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: tenants,
        builder: (context, state) => const TenantsScreen(),
      ),
      GoRoute(
        path: finances,
        builder: (context, state) => const FinancesScreen(),
      ),
      GoRoute(
        path: communications,
        builder: (context, state) => const CommunicationsScreen(),
      ),
    ],
  );
}
