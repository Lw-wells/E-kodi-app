import 'package:go_router/go_router.dart';

import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/properties/views/properties_screen.dart';
import '../features/properties/views/add_property_screen.dart';
import '../features/properties/views/property_detail_screen.dart';
import '../features/tenants/views/assign_tenant_screen.dart';
import '../features/tenants/views/tenants_screen.dart';
import '../features/finances/views/finances_screen.dart';
import '../features/finances/views/add_utility_screen.dart';
import '../features/communications/views/communications_screen.dart';

class AppRoutes {
  static const String splash        = '/';
  static const String onboarding    = '/onboarding';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String dashboard     = '/dashboard';
  static const String properties    = '/properties';
  static const String addProperty   = '/properties/add';
  static const String propertyDetail = '/properties/:id';
  static const String tenants       = '/tenants';
  static const String addUtility    = '/finances/add-utility';
  static const String finances      = '/finances';
  static const String communications = '/communications';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash,      builder: (context, state) => const SplashScreen()),
      GoRoute(path: onboarding,  builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: login,       builder: (context, state) => const LoginScreen()),
      GoRoute(path: register,    builder: (context, state) => const RegisterScreen()),
      GoRoute(path: dashboard,   builder: (context, state) => const DashboardScreen()),
      GoRoute(path: properties,  builder: (context, state) => const PropertiesScreen()),

      // ✅ /properties/add BEFORE /properties/:id
      GoRoute(path: addProperty, builder: (context, state) => const AddPropertyScreen()),
      GoRoute(
        path: propertyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/properties/:propertyId/units/:unitId/assign',
        builder: (context, state) {
          final propertyId = state.pathParameters['propertyId']!;
          final unitId     = state.pathParameters['unitId']!;
          final unitName   = state.uri.queryParameters['unitName'] ?? 'Unit';
          return AssignTenantScreen(
              propertyId: propertyId, unitId: unitId, unitName: unitName);
        },
      ),

      GoRoute(path: tenants,        builder: (context, state) => const TenantsScreen()),

      // ✅ /finances/add-utility BEFORE /finances
      GoRoute(path: addUtility,     builder: (context, state) => const AddUtilityScreen()),
      GoRoute(path: finances,       builder: (context, state) => const FinancesScreen()),

      GoRoute(path: communications, builder: (context, state) => const CommunicationsScreen()),
    ],
  );
}