// lib/main.dart - CORRECTIONS POUR MULTI-UTILISATEURS - FIXED
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import des modèles avec les nouveaux modèles améliorés
import 'models/enhanced_user.dart'; // NOUVEAU
import 'models/vaccination.dart';
import 'models/vaccine_category.dart';
import 'models/travel.dart';
import 'services/multi_user_service.dart'; // NOUVEAU

// Import des services principaux
import 'services/database_service.dart';
import 'services/camera_service.dart';

// Import du thème et des écrans
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/card_selection_screen.dart';
import 'screens/onboarding/travel_options_screen.dart';
import 'screens/onboarding/camera_scan_screen.dart';
import 'screens/onboarding/scan_preview_screen.dart';
import 'screens/vaccination/manual_entry_screen.dart';
import 'screens/profile/enhanced_user_creation_screen.dart'; // NOUVEAU
import 'screens/profile/additional_info_screen.dart';
import 'screens/vaccination/vaccination_info_screen.dart';
import 'screens/vaccination/vaccination_summary_screen.dart';
import 'screens/vaccination/vaccination_management_screen.dart';
import 'screens/family/family_management_screen.dart'; // NOUVEAU

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // === INITIALISATION DE LA CAMÉRA ===
    bool cameraInitialized = false;
    try {
      await CameraService.initialize();
      cameraInitialized = true;
      debugPrint('✅ Service caméra initialisé avec succès');
    } catch (e) {
      debugPrint('⚠️ Échec de l\'initialisation de la caméra: $e');
    }
    
    // === INITIALISATION DE LA BASE DE DONNÉES HIVE ===
    try {
      await Hive.initFlutter();
      debugPrint('✅ Base de données Hive initialisée');
    } catch (e) {
      debugPrint('❌ Échec de l\'initialisation Hive: $e');
      rethrow;
    }
    
    // === ENREGISTREMENT DES ADAPTATEURS HIVE AMÉLIORÉS ===
    try {
      // Enregistre l'adaptateur EnhancedUser (typeId: 0)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EnhancedUserAdapter());
      }
      
      // Enregistre les nouveaux adaptateurs pour les énumérations
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(UserRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(UserTypeAdapter());
      }
      
      // Enregistre l'adaptateur FamilyAccount (typeId: 4)
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(FamilyAccountAdapter());
      }
      
      // Adaptateurs existants
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VaccinationAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VaccineCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TravelAdapter());
      }
      
      debugPrint('✅ Adaptateurs Hive enregistrés avec succès');
    } catch (e) {
      debugPrint('❌ Échec de l\'enregistrement des adaptateurs: $e');
      rethrow;
    }
    
    // === INITIALISATION DES DONNÉES PAR DÉFAUT ===
    try {
      final databaseService = DatabaseService();
      await databaseService.initializeDefaultCategories();
      debugPrint('✅ Données par défaut initialisées');
    } catch (e) {
      debugPrint('⚠️ Échec de l\'initialisation des données par défaut: $e');
    }
    
    // === MIGRATION DES DONNÉES EXISTANTES ===
    // Migre les anciens utilisateurs vers le nouveau modèle si nécessaire
    try {
      await _migrateExistingUsers();
      debugPrint('✅ Migration des utilisateurs terminée');
    } catch (e) {
      debugPrint('⚠️ Échec de la migration: $e');
    }
    
    runApp(MyApp(cameraInitialized: cameraInitialized));
    
  } catch (e, stackTrace) {
    debugPrint('💥 Erreur fatale pendant l\'initialisation: $e');
    debugPrint('🔍 Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString()));
  }
}

// Migration des utilisateurs existants vers le nouveau modèle
Future<void> _migrateExistingUsers() async {
  try {
    // Ouvre l'ancienne boîte utilisateurs s'il y en a une
    final oldBox = await Hive.openBox('users_v2');
    final newBox = await Hive.openBox<EnhancedUser>('enhanced_users_v1');
    
    if (oldBox.isNotEmpty && newBox.isEmpty) {
      debugPrint('🔄 Migration de ${oldBox.length} utilisateur(s) vers le nouveau modèle...');
      
      for (final key in oldBox.keys) {
        try {
          final oldUser = oldBox.get(key);
          if (oldUser != null) {
            // Crée un nouvel utilisateur amélioré à partir de l'ancien
            final enhancedUser = EnhancedUser(
              name: oldUser.name ?? 'Utilisateur Migré',
              email: oldUser.email ?? 'migration@example.com',
              passwordHash: oldUser.passwordHash ?? '',
              dateOfBirth: oldUser.dateOfBirth ?? '01/01/1990',
              diseases: oldUser.diseases,
              treatments: oldUser.treatments,
              allergies: oldUser.allergies,
              salt: oldUser.salt,
              createdAt: oldUser.createdAt ?? DateTime.now(),
              lastLogin: oldUser.lastLogin ?? DateTime.now(),
              isActive: oldUser.isActive ?? true,
              userType: UserType.adult, // Par défaut
              role: UserRole.primary,   // Premier utilisateur = propriétaire
              emailVerified: false,
            );
            
            await newBox.add(enhancedUser);
          }
        } catch (e) {
          debugPrint('Erreur migration utilisateur $key: $e');
        }
      }
      
      debugPrint('✅ Migration terminée');
    }
  } catch (e) {
    debugPrint('Erreur lors de la migration: $e');
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
      debugPrint('✅ Ressources nettoyées avec succès');
    } catch (e) {
      debugPrint('⚠️ Erreur pendant le nettoyage des ressources: $e');
    }
  }

  Future<void> _restartCameraService() async {
    try {
      await CameraService.restart();
      debugPrint('✅ Service caméra redémarré avec succès');
    } catch (e) {
      debugPrint('⚠️ Échec du redémarrage du service caméra: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      
      initialRoute: '/',
      
      // ROUTES MISES À JOUR avec les nouveaux écrans
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
        '/user-creation': (context) => const EnhancedUserCreationScreen(), // NOUVEAU
        '/additional-info': (context) => const AdditionalInfoScreen(),
        '/vaccination-summary': (context) => const VaccinationSummaryScreen(),
        '/vaccination-management': (context) => const VaccinationManagementScreen(),
        '/family-management': (context) => const FamilyManagementScreen(), // NOUVEAU
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
        child: LayoutBuilder(
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
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                            minHeight: 48,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Force restart de l'application
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
                              backgroundColor: const Color(0xFF2C5F66),
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
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Bouton pour signaler le bug
                        TextButton(
                          onPressed: () {
                            // Dans une vraie app, on pourrait envoyer un rapport de bug
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fonctionnalité de rapport de bug à venir'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          child: const Text(
                            'Signaler ce problème',
                            style: TextStyle(
                              color: Color(0xFF2C5F66),
                              decoration: TextDecoration.underline,
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
      home: ErrorDisplay(error: error),
    );
  }
}

// Utilitaires d'interface responsive améliorés
class ResponsiveLayoutHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }
  
  static bool isShortScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) {
      return baseSize * 0.9;
    }
    if (isTablet(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(12);
    }
    if (isTablet(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }
  
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isSmallScreen(context) || isShortScreen(context)) {
      return baseSpacing * 0.75;
    }
    if (isTablet(context)) {
      return baseSpacing * 1.25;
    }
    return baseSpacing;
  }
  
  // Nouveau: support pour différentes orientations
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  static int getResponsiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }
}