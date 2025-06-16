// lib/main.dart - FIXED with MaterialLocalizations and improved error handling
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user.dart';
import 'models/vaccination.dart';
import 'models/vaccine_category.dart';
import 'models/travel.dart';
import 'services/database_service.dart';
import 'services/camera_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/card_selection_screen.dart';
import 'screens/onboarding/travel_options_screen.dart';
import 'screens/onboarding/camera_scan_screen.dart';
import 'screens/onboarding/scan_preview_screen.dart';
import 'screens/vaccination/manual_entry_screen.dart';
import 'screens/profile/user_creation_screen.dart';
import 'screens/profile/additional_info_screen.dart';
import 'screens/vaccination/vaccination_info_screen.dart';
import 'screens/vaccination/vaccination_summary_screen.dart';
import 'screens/vaccination/vaccination_management_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  // FIXED: Add proper error handling for main initialization
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize camera service with better error handling
    bool cameraInitialized = false;
    try {
      await CameraService.initialize();
      cameraInitialized = true;
      debugPrint('Camera service initialized successfully');
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      // App can continue without camera functionality
    }
    
    // Initialize Hive with error handling
    try {
      await Hive.initFlutter();
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Hive initialization failed: $e');
      rethrow; // This is critical, app cannot continue
    }
    
    // Register adapters with error handling
    try {
      // FIXED: Check if adapters are already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VaccinationAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VaccineCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TravelAdapter());
      }
      debugPrint('Hive adapters registered successfully');
    } catch (e) {
      debugPrint('Hive adapter registration failed: $e');
      rethrow; // This is critical, app cannot continue
    }
    
    // Initialize default categories
    try {
      final databaseService = DatabaseService();
      await databaseService.initializeDefaultCategories();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      // App can continue with empty categories
    }
    
    runApp(MyApp(cameraInitialized: cameraInitialized));
  } catch (e, stackTrace) {
    debugPrint('Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // FIXED: Show error screen instead of crashing
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  final bool cameraInitialized;
  
  const MyApp({Key? key, this.cameraInitialized = false}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // FIXED: Proper cleanup when app is disposed
    _cleanupResources();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // FIXED: Handle app lifecycle changes properly
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cleanupResources();
        break;
      case AppLifecycleState.resumed:
        // FIXED: Restart camera service if needed
        if (widget.cameraInitialized && CameraService.isDisposed) {
          _restartCameraService();
        }
        break;
      case AppLifecycleState.inactive:
        // Do nothing for inactive state
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state (available in newer Flutter versions)
        break;
    }
  }

  Future<void> _cleanupResources() async {
    try {
      await CameraService.dispose();
      // FIXED: Add database cleanup if needed
      final databaseService = DatabaseService();
      await databaseService.dispose();
      debugPrint('Resources cleaned up successfully');
    } catch (e) {
      debugPrint('Error during resource cleanup: $e');
    }
  }

  Future<void> _restartCameraService() async {
    try {
      await CameraService.restart();
      debugPrint('Camera service restarted successfully');
    } catch (e) {
      debugPrint('Failed to restart camera service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccigo - Carnet de Vaccination',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // FIXED: Add proper localization support to fix MaterialLocalizations error
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // French
        Locale('en', 'US'), // English fallback
      ],
      locale: const Locale('fr', 'FR'),
      
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/card-selection': (context) => const CardSelectionScreen(),
        '/travel-options': (context) => const TravelOptionsScreen(),
        '/camera-scan': (context) => const CameraScanScreen(),
        '/scan-preview': (context) => const ScanPreviewScreen(),
        '/manual-entry': (context) => const ManualEntryScreen(),
        '/vaccination-info': (context) => const VaccinationInfoScreen(),
        '/user-creation': (context) => const UserCreationScreen(),
        '/additional-info': (context) => const AdditionalInfoScreen(),
        '/vaccination-summary': (context) => const VaccinationSummaryScreen(),
        '/vaccination-management': (context) => const VaccinationManagementScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
      // FIXED: Add global error handler
      builder: (context, widget) {
        // FIXED: Wrap with error boundary
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorDisplay(error: errorDetails.toString());
        };
        
        // FIXED: Add proper text scaling and accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// FIXED: Error app for fatal initialization errors
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccigo - Erreur',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      home: Scaffold(
        backgroundColor: Colors.white,
        body: ErrorDisplay(error: error),
      ),
    );
  }
}

// FIXED: Error display widget
class ErrorDisplay extends StatelessWidget {
  final String error;
  
  const ErrorDisplay({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Une erreur s\'est produite',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5F66),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Détails de l\'erreur:\n$error',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // FIXED: Restart the app
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F66),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Redémarrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}