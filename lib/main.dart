import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/sync_service.dart';
import 'services/offline_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializovať offline service (iba na mobile/desktop, nie na web)
  final offlineService = OfflineService();
  if (!offlineService.isWeb) {
    await offlineService.database;
  }
  
  // Spustiť automatickú synchronizáciu
  final syncService = SyncService();
  
  // Sledovať zmeny connectivity a synchronizovať
  offlineService.connectivityStream.listen((isOnline) async {
    if (isOnline) {
      await syncService.syncAll();
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuth(),
      child: MaterialApp(
        title: 'Picí Pas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.amber,
          primaryColor: const Color(0xFFFF6B35), // Orange-red theme
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            primary: const Color(0xFFFF6B35),
            secondary: const Color(0xFFF7931E),
            tertiary: const Color(0xFFFFC107),
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark background
          cardColor: const Color(0xFF2D2D2D),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white),
            displayMedium: TextStyle(color: Colors.white),
            displaySmall: TextStyle(color: Colors.white),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            headlineSmall: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white70),
            bodyMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.white60),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF2D2D2D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        final user = authProvider.user!;

        if (user.isAdmin) {
          return const AdminHomeScreen();
        } else if (user.isObsluha) {
          return const StaffHomeScreen();
        } else {
          return const CustomerHomeScreen();
        }
      },
    );
  }
}
