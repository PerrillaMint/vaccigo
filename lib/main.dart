// lib/main.dart - App title removed from MaterialApp
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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    bool cameraInitialized = false;
    try {
      await CameraService.initialize();
      cameraInitialized = true;
      debugPrint('Camera service initialized successfully');
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
    }
    
    try {
      await Hive.initFlutter();
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Hive initialization failed: $e');
      rethrow;
    }
    
    try {
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
      rethrow;
    }
    
    try {
      final databaseService = DatabaseService();
      await databaseService.initializeDefaultCategories();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Database initialization failed: $e');
    }
    
    runApp(MyApp(cameraInitialized: cameraInitialized));
  } catch (e, stackTrace) {
    debugPrint('Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
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
    _cleanupResources();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cleanupResources();
        break;
      case AppLifecycleState.resumed:
        if (widget.cameraInitialized && CameraService.isDisposed) {
          _restartCameraService();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _cleanupResources() async {
    try {
      await CameraService.dispose();
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
      // REMOVED: App name/title removed from MaterialApp
      title: 'Carnet de Vaccination',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
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
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorDisplay(error: errorDetails.toString());
        };
        
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

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erreur',
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

class ErrorDisplay extends StatelessWidget {
  final String error;
  
  const ErrorDisplay({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth < 400 ? constraints.maxWidth - 32 : 400,
              ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth < 400 ? constraints.maxWidth - 64 : 320,
                      ),
                      child: Text(
                        'Détails de l\'erreur:\n$error',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 200,
                        minHeight: 48,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Redémarrer',
                          style: TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Additional responsive layout utilities
class ResponsiveLayoutHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }
  
  static bool isShortScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) {
      return baseSize * 0.9;
    }
    return baseSize;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(12);
    }
    return const EdgeInsets.all(16);
  }
  
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isSmallScreen(context) || isShortScreen(context)) {
      return baseSpacing * 0.75;
    }
    return baseSpacing;
  }
}