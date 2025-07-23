import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import des modèles
import 'models/enhanced_user.dart';
import 'models/vaccination.dart';
import 'models/vaccine_category.dart';
import 'models/travel.dart';
import 'services/multi_user_service.dart';

// Import des services
import 'services/database_service.dart';
import 'services/camera_service.dart';
import 'services/enhanced_french_vaccination_parser_with_fuzzy.dart';
import 'services/vaccine_name_corrector.dart';

// Import des constantes de couleurs
import 'constants/app_colors.dart';

// Import des écrans
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/card_selection_screen.dart';
import 'screens/onboarding/travel_options_screen.dart';
import 'screens/onboarding/camera_scan_screen.dart';
import 'screens/onboarding/scan_preview_screen.dart';
import 'screens/onboarding/multi_vaccination_scan_screen.dart';
import 'screens/vaccination/manual_entry_screen.dart';
import 'screens/profile/enhanced_user_creation_screen.dart';
import 'screens/profile/additional_info_screen.dart';
import 'screens/vaccination/vaccination_info_screen.dart';
import 'screens/vaccination/vaccination_summary_screen.dart';
import 'screens/vaccination/vaccination_management_screen.dart';
import 'screens/family/family_management_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('🚀 Démarrage de Vaccigo...');
    
    // === INITIALISATION CAMÉRA ===
    bool cameraInitialized = false;
    try {
      await CameraService.initialize();
      cameraInitialized = true;
      print('✅ Service caméra initialisé');
    } catch (e) {
      print('⚠️ Caméra non disponible: $e');
    }
    
    // === INITIALISATION HIVE ===
    try {
      await Hive.initFlutter();
      print('✅ Hive initialisé');
    } catch (e) {
      print('❌ Erreur Hive: $e');
      rethrow;
    }
    
    // === NETTOYAGE DES ANCIENNES VERSIONS ===
    await _cleanupOldVersions();
    
    // === ENREGISTREMENT DES ADAPTATEURS ===
    await _registerAdapters();
    
    // === INITIALISATION BASE DE DONNÉES ===
    try {
      final databaseService = DatabaseService();
      await databaseService.initializeDatabase();
      await databaseService.initializeDefaultCategories();
      print('✅ Base de données initialisée');
    } catch (e) {
      print('❌ Erreur initialisation DB: $e');
      // Continue quand même pour permettre la création manuelle
    }
    
    // === PRÉPARATION DU FUZZY MATCHING ===
    // Test du service de correction automatique des noms de vaccins
    try {
      final testResult = VaccineNameCorrector.correctVaccineName('pentalog');
      print('✅ Service de correction automatique des noms de vaccins prêt');
      print('   Test: "pentalog" → "${testResult.standardizedName}" (confiance: ${(testResult.confidence * 100).toStringAsFixed(1)}%)');
      
      // Test du parser amélioré
      final enhancedParser = EnhancedFrenchVaccinationParser();
      print('✅ Parser français amélioré avec fuzzy matching prêt');
      print('   Base de données: ${VaccineNameCorrector.getAllVaccineNames().length} vaccins référencés');
    } catch (e) {
      print('⚠️ Erreur initialisation fuzzy matching: $e');
    }
    
    runApp(MyApp(cameraInitialized: cameraInitialized));
    
  } catch (e, stackTrace) {
    print('💥 Erreur fatale: $e');
    print('📍 Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString()));
  }
}

// Nettoyage des anciennes versions de boîtes
Future<void> _cleanupOldVersions() async {
  final oldBoxes = [
    'users_v2',
    'enhanced_users_v1',
    'vaccinations_v2',
    'vaccine_categories_v2', 
    'session_v2',
  ];
  
  for (final boxName in oldBoxes) {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      if (await Hive.boxExists(boxName)) {
        await Hive.deleteBoxFromDisk(boxName);
        print('🧹 Ancienne boîte supprimée: $boxName');
      }
    } catch (e) {
      print('⚠️ Erreur nettoyage $boxName: $e');
    }
  }
}

// Enregistrement sécurisé des adaptateurs
Future<void> _registerAdapters() async {
  try {
    // Adaptateur EnhancedUser (typeId: 0)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EnhancedUserAdapter());
      print('📝 Adaptateur EnhancedUser enregistré');
    }
    
    // Adaptateurs pour les énumérations (typeId: 10, 11)
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(UserRoleAdapter());
      print('📝 Adaptateur UserRole enregistré');
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(UserTypeAdapter());
      print('📝 Adaptateur UserType enregistré');
    }
    
    // Adaptateur FamilyAccount (typeId: 4)
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(FamilyAccountAdapter());
      print('📝 Adaptateur FamilyAccount enregistré');
    }
    
    // Adaptateurs existants (typeId: 1, 2, 3)
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VaccinationAdapter());
      print('📝 Adaptateur Vaccination enregistré');
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(VaccineCategoryAdapter());
      print('📝 Adaptateur VaccineCategory enregistré');
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TravelAdapter());
      print('📝 Adaptateur Travel enregistré');
    }
    
    print('✅ Tous les adaptateurs Hive enregistrés');
  } catch (e) {
    print('❌ Erreur enregistrement adaptateurs: $e');
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  final bool cameraInitialized;
  
  const MyApp({super.key, this.cameraInitialized = false});

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
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _cleanupResources() async {
    try {
      await CameraService.dispose();
      final databaseService = DatabaseService();
      await databaseService.dispose();
      print('✅ Ressources nettoyées');
    } catch (e) {
      print('⚠️ Erreur nettoyage: $e');
    }
  }

  Future<void> _restartCameraService() async {
    try {
      await CameraService.restart();
      print('✅ Service caméra redémarré');
    } catch (e) {
      print('⚠️ Erreur redémarrage caméra: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccigo - Carnet de Vaccination',
      debugShowCheckedModeBanner: false,
      
      // Basic theme configuration using AppColors directly
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.error,
          onPrimary: AppColors.onPrimary,
          onSecondary: AppColors.onSecondary,
          onSurface: AppColors.onSurface,
          onBackground: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AppColors.primary,
          titleTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
      
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
      
      initialRoute: '/',
      
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/card-selection': (context) => const CardSelectionScreen(),
        '/travel-options': (context) => const TravelOptionsScreen(),
        '/camera-scan': (context) => const CameraScanScreen(),
        '/scan-preview': (context) => const ScanPreviewScreen(),
        '/manual-entry': (context) => const ManualEntryScreen(),
        '/vaccination-info': (context) => const VaccinationInfoScreen(),
        '/user-creation': (context) => const EnhancedUserCreationScreen(),
        '/additional-info': (context) => const AdditionalInfoScreen(),
        '/vaccination-summary': (context) => const VaccinationSummaryScreen(),
        '/vaccination-management': (context) => const VaccinationManagementScreen(),
        '/family-management': (context) => const FamilyManagementScreen(),
      },
      
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/multi-vaccination-scan':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && 
                args.containsKey('imagePath') && 
                args.containsKey('userId')) {
              return MaterialPageRoute(
                builder: (context) => MultiVaccinationScanScreen(
                  imagePath: args['imagePath'] as String,
                  userId: args['userId'] as String,
                ),
              );
            }
            break;
        }
        return null;
      },
      
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        );
      },
      
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorDisplay(error: errorDetails.toString());
        };
        
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8, 
              maxScaleFactor: 1.2
            ),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// Widget d'affichage d'erreur amélioré
class ErrorDisplay extends StatelessWidget {
  final String error;
  
  const ErrorDisplay({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      'Détails: ${error.length > 200 ? error.substring(0, 200) + "..." : error}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Redémarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccigo - Erreur',
      home: ErrorDisplay(error: error),
    );
  }
}