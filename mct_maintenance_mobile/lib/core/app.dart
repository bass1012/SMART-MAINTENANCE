import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/screens/splash_screen.dart';
import 'package:mct_maintenance_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mct_maintenance_mobile/features/auth/presentation/screens/reset_password_code_screen.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/customer_main_screen.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/subscriptions_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/technician_main_screen.dart';
import 'package:mct_maintenance_mobile/features/technician/presentation/screens/technician_profile_screen.dart';
import 'package:mct_maintenance_mobile/features/manager/presentation/screens/manager_main_screen.dart';
import 'package:mct_maintenance_mobile/features/common/presentation/screens/notification_settings_screen.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mct_maintenance_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/interventions/domain/repositories/intervention_repository.dart';
import 'package:mct_maintenance_mobile/features/interventions/data/repositories/intervention_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/common/domain/repositories/notification_repository.dart';
import 'package:mct_maintenance_mobile/features/common/data/repositories/notification_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/subscription_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/subscription_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/service_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/service_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/complaint_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/complaint_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/shop_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/shop_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/payment_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/payment_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/equipment_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/equipment_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/contract_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/contract_repository_impl.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/notification_repository.dart';
import 'package:mct_maintenance_mobile/features/customer/data/repositories/notification_repository_impl.dart';
import 'package:mct_maintenance_mobile/services/cart_service.dart';
import 'package:mct_maintenance_mobile/providers/settings_provider.dart';
import 'package:mct_maintenance_mobile/providers/notification_preferences_provider.dart';
import 'package:mct_maintenance_mobile/providers/sync_provider.dart';
import 'package:mct_maintenance_mobile/services/payment_service.dart';

// Initialiser la locale par défaut
void initializeDateFormatting() {
  Intl.defaultLocale = 'fr_FR';
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BaseApiService>(create: (_) => BaseApiService()),
        ProxyProvider<BaseApiService, AuthRepository>(
          update: (_, apiService, __) => AuthRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, InterventionRepository>(
          update: (_, apiService, __) => InterventionRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, NotificationRepository>(
          update: (_, apiService, __) => NotificationRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, SubscriptionRepository>(
          update: (_, apiService, __) => SubscriptionRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, ServiceRepository>(
          update: (_, apiService, __) => ServiceRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, ComplaintRepository>(
          update: (_, apiService, __) => ComplaintRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, ShopRepository>(
          update: (_, apiService, __) => ShopRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, PaymentRepository>(
          update: (_, apiService, __) => PaymentRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, EquipmentRepository>(
          update: (_, apiService, __) => EquipmentRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, ContractRepository>(
          update: (_, apiService, __) => ContractRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, CustomerNotificationRepository>(
          update: (_, apiService, __) => CustomerNotificationRepositoryImpl(apiService),
        ),
        ProxyProvider<BaseApiService, PaymentService>(
          update: (_, apiService, __) => PaymentService(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final cartService = CartService();
            cartService.loadCart();
            return cartService;
          },
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationPreferencesProvider()..loadPreferences(),
        ),
        // Provider pour le mode offline et synchronisation
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Smart Maintenance',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: const Color(0xFF0a543d),
              scaffoldBackgroundColor: const Color(0xFFe6ffe6),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0a543d),
                primary: const Color(0xFF0a543d),
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.nunitoSansTextTheme(
                ThemeData.light().textTheme,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF0a543d),
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a543d),
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF0a543d), width: 2),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF2d9370),
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF2d9370),
                secondary: const Color(0xFF4db88c),
                surface: const Color(0xFF1e1e1e),
                error: const Color(0xFFcf6679),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: const Color(0xFFe1e1e1),
                onError: Colors.black,
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1e1e1e),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textTheme: GoogleFonts.nunitoSansTextTheme(
                ThemeData.dark().textTheme.copyWith(
                      bodyLarge: const TextStyle(color: Color(0xFFe1e1e1)),
                      bodyMedium: const TextStyle(color: Color(0xFFe1e1e1)),
                      bodySmall: const TextStyle(color: Color(0xFFb0b0b0)),
                      titleLarge: const TextStyle(color: Color(0xFFffffff)),
                      titleMedium: const TextStyle(color: Color(0xFFffffff)),
                      titleSmall: const TextStyle(color: Color(0xFFe1e1e1)),
                      labelLarge: const TextStyle(color: Color(0xFFe1e1e1)),
                      labelMedium: const TextStyle(color: Color(0xFFb0b0b0)),
                      labelSmall: const TextStyle(color: Color(0xFF909090)),
                    ),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1e1e1e),
                foregroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1e1e1e),
                selectedItemColor: Color(0xFF2d9370),
                unselectedItemColor: Color(0xFF909090),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2d9370),
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF2a2a2a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF2d9370), width: 2),
                ),
                labelStyle: const TextStyle(color: Color(0xFFb0b0b0)),
                hintStyle: const TextStyle(color: Color(0xFF707070)),
              ),
              iconTheme: const IconThemeData(color: Color(0xFFe1e1e1)),
              dividerColor: const Color(0xFF3a3a3a),
              listTileTheme: const ListTileThemeData(
                textColor: Color(0xFFe1e1e1),
                iconColor: Color(0xFFb0b0b0),
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/reset-password-code': (context) {
                final email =
                    ModalRoute.of(context)!.settings.arguments as String?;
                return ResetPasswordCodeScreen(email: email);
              },
              '/client': (context) => const CustomerMainScreen(),
              '/technician': (context) => const TechnicianMainScreen(),
              '/manager': (context) => const ManagerMainScreen(),
              '/technician/profile': (context) =>
                  const TechnicianProfileScreen(),
              '/subscriptions': (context) => const SubscriptionsScreen(),
              '/notification-settings': (context) =>
                  const NotificationSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
