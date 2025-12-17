import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_code_screen.dart';
import '../screens/customer/customer_main_screen.dart';
import '../screens/customer/subscriptions_screen.dart';
import '../screens/technician/technician_main_screen.dart';
import '../screens/technician/technician_profile_screen.dart';
import '../services/cart_service.dart';
import '../providers/settings_provider.dart';

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
        ChangeNotifierProvider(
          create: (_) {
            final cartService = CartService();
            cartService.loadCart();
            return cartService;
          },
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
                background: const Color(0xFF121212),
                error: const Color(0xFFcf6679),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: const Color(0xFFe1e1e1),
                onBackground: const Color(0xFFe1e1e1),
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
              '/technician/profile': (context) =>
                  const TechnicianProfileScreen(),
              '/subscriptions': (context) => const SubscriptionsScreen(),
            },
          );
        },
      ),
    );
  }
}
