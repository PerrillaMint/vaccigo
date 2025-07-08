// lib/main.dart - Point d'entrée principal de l'application Vaccigo (SPLASH SCREEN REMOVED)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import des modèles de données pour l'enregistrement Hive
import 'models/user.dart';
import 'models/vaccination.dart';
import 'models/vaccine_category.dart';
import 'models/travel.dart';

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
import 'screens/profile/user_creation_screen.dart';
import 'screens/profile/additional_info_screen.dart';
import 'screens/vaccination/vaccination_info_screen.dart';
import 'screens/vaccination/vaccination_summary_screen.dart';
import 'screens/vaccination/vaccination_management_screen.dart';
// REMOVED: splash_screen.dart import

// Point d'entrée principal de l'application
// Cette fonction initialise tous les services nécessaires avant de lancer l'app
void main() async {
  try {
    // S'assure que les widgets Flutter sont initialisés avant d'exécuter du code asynchrone
    // Obligatoire quand on fait des opérations async dans main()
    WidgetsFlutterBinding.ensureInitialized();
    
    // === INITIALISATION DE LA CAMÉRA ===
    // On tente d'initialiser le service caméra, mais on ne bloque pas l'app si ça échoue
    // Certains appareils ou émulateurs peuvent ne pas avoir de caméra
    bool cameraInitialized = false;
    try {
      await CameraService.initialize();
      cameraInitialized = true;
      debugPrint('✅ Service caméra initialisé avec succès');
    } catch (e) {
      debugPrint('⚠️ Échec de l\'initialisation de la caméra: $e');
      // On continue même si la caméra échoue - l'utilisateur pourra saisir manuellement
    }
    
    // === INITIALISATION DE LA BASE DE DONNÉES HIVE ===
    // Hive est notre base de données locale pour stocker les données utilisateur
    try {
      await Hive.initFlutter(); // Initialise Hive avec les chemins Flutter
      debugPrint('✅ Base de données Hive initialisée');
    } catch (e) {
      debugPrint('❌ Échec de l\'initialisation Hive: $e');
      rethrow; // On ne peut pas continuer sans base de données
    }
    
    // === ENREGISTREMENT DES ADAPTATEURS HIVE ===
    // Les adaptateurs permettent à Hive de sérialiser/désérialiser nos modèles personnalisés
    // Chaque modèle a un ID unique (typeId) pour éviter les conflits
    try {
      // Enregistre l'adaptateur User (typeId: 0) s'il n'est pas déjà enregistré
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      
      // Enregistre l'adaptateur Vaccination (typeId: 1)
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VaccinationAdapter());
      }
      
      // Enregistre l'adaptateur VaccineCategory (typeId: 2)
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VaccineCategoryAdapter());
      }
      
      // Enregistre l'adaptateur Travel (typeId: 3)
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TravelAdapter());
      }
      
      debugPrint('✅ Adaptateurs Hive enregistrés avec succès');
    } catch (e) {
      debugPrint('❌ Échec de l\'enregistrement des adaptateurs: $e');
      rethrow; // Critique pour le fonctionnement de l'app
    }
    
    // === INITIALISATION DES DONNÉES PAR DÉFAUT ===
    // Crée les catégories de vaccins par défaut si c'est la première utilisation
    try {
      final databaseService = DatabaseService();
      await databaseService.initializeDefaultCategories();
      debugPrint('✅ Données par défaut initialisées');
    } catch (e) {
      debugPrint('⚠️ Échec de l\'initialisation des données par défaut: $e');
      // Non critique - l'app peut fonctionner sans catégories par défaut
    }
    
    // Lance l'application avec le statut de la caméra - DIRECTLY TO WELCOME SCREEN
    runApp(MyApp(cameraInitialized: cameraInitialized));
    
  } catch (e, stackTrace) {
    // Si une erreur critique survient pendant l'initialisation
    debugPrint('💥 Erreur fatale pendant l\'initialisation: $e');
    debugPrint('🔍 Stack trace: $stackTrace');
    
    // Lance une version d'erreur de l'app pour informer l'utilisateur
    runApp(ErrorApp(error: e.toString()));
  }
}

// Widget principal de l'application
class MyApp extends StatefulWidget {
  // Indique si la caméra a pu être initialisée
  final bool cameraInitialized;
  
  const MyApp({Key? key, this.cameraInitialized = false}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Écoute les changements du cycle de vie de l'application
    // Permet de gérer la caméra quand l'app passe en arrière-plan
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Nettoie les observateurs et ressources avant la destruction
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  // Gère les changements d'état de l'application (premier plan/arrière-plan)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:    // App en arrière-plan
      case AppLifecycleState.detached:  // App fermée par l'OS
        _cleanupResources(); // Libère les ressources pour économiser la mémoire
        break;
        
      case AppLifecycleState.resumed:   // App revenue au premier plan
        // Redémarre la caméra si elle était initialisée et qu'elle s'est fermée
        if (widget.cameraInitialized && CameraService.isDisposed) {
          _restartCameraService();
        }
        break;
        
      case AppLifecycleState.inactive:  // App inactive (appel entrant, etc.)
      case AppLifecycleState.hidden:    // App cachée mais pas fermée
        break; // Pas d'action spéciale requise
    }
  }

  // Nettoie proprement toutes les ressources de l'application
  Future<void> _cleanupResources() async {
    try {
      // Ferme le service caméra pour libérer la ressource
      await CameraService.dispose();
      
      // Ferme les connexions de base de données
      final databaseService = DatabaseService();
      await databaseService.dispose();
      
      debugPrint('✅ Ressources nettoyées avec succès');
    } catch (e) {
      debugPrint('⚠️ Erreur pendant le nettoyage des ressources: $e');
    }
  }

  // Redémarre le service caméra après une mise en arrière-plan
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
      // Configuration de base de l'application
      title: 'Carnet de Vaccination', // Titre affiché dans le gestionnaire de tâches
      debugShowCheckedModeBanner: false, // Cache le banner "Debug" en mode développement
      theme: AppTheme.lightTheme, // Applique notre thème personnalisé
      
      // === CONFIGURATION DE LOCALISATION ===
      // Support des langues françaises et anglaises
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,  // Textes Material Design
        GlobalWidgetsLocalizations.delegate,   // Widgets Flutter de base
        GlobalCupertinoLocalizations.delegate, // Widgets iOS
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français France
        Locale('en', 'US'), // Anglais États-Unis
      ],
      locale: const Locale('fr', 'FR'), // Langue par défaut: français
      
      // === CONFIGURATION DE NAVIGATION ===
      // CHANGED: App now starts directly at welcome screen instead of splash
      initialRoute: '/', // Start directly at welcome screen
      
      // Définition de toutes les routes de navigation
      routes: {
        // REMOVED: '/splash' route completely
        '/': (context) => const WelcomeScreen(),                            // Écran d'accueil (now initial)
        '/login': (context) => const LoginScreen(),                         // Connexion
        '/forgot-password': (context) => const ForgotPasswordScreen(),      // Mot de passe oublié
        '/card-selection': (context) => const CardSelectionScreen(),        // Choix du type de carnet
        '/travel-options': (context) => const TravelOptionsScreen(),        // Options de voyage
        '/camera-scan': (context) => const CameraScanScreen(),              // Scan par caméra
        '/scan-preview': (context) => const ScanPreviewScreen(),            // Aperçu du scan
        '/manual-entry': (context) => const ManualEntryScreen(),            // Saisie manuelle
        '/vaccination-info': (context) => const VaccinationInfoScreen(),    // Info vaccinations
        '/user-creation': (context) => const UserCreationScreen(),          // Création d'utilisateur
        '/additional-info': (context) => const AdditionalInfoScreen(),      // Infos supplémentaires
        '/vaccination-summary': (context) => const VaccinationSummaryScreen(), // Résumé
        '/vaccination-management': (context) => const VaccinationManagementScreen(), // Gestion
      },
      
      // Gestion des routes inconnues - redirige vers welcome au lieu de splash
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const WelcomeScreen(), // CHANGED: from SplashScreen to WelcomeScreen
        );
      },
      
      // === CONFIGURATION GLOBALE DE L'INTERFACE ===
      builder: (context, widget) {
        // Gestion globale des erreurs d'interface
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return ErrorDisplay(error: errorDetails.toString());
        };
        
        // Configuration globale de l'affichage
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Limite la taille du texte entre 80% et 120% pour la lisibilité
            // Évite que l'interface soit cassée par des tailles de police extrêmes
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// Application d'erreur affichée en cas de problème critique à l'initialisation
class ErrorApp extends StatelessWidget {
  final String error; // Message d'erreur à afficher
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erreur',
      // Même configuration de localisation que l'app principale
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

// Widget d'affichage d'erreur avec interface utilisateur claire
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
                // Adapte la largeur selon la taille de l'écran
                maxWidth: constraints.maxWidth < 400 ? constraints.maxWidth - 32 : 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône d'erreur
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    
                    // Titre de l'erreur
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
                    
                    // Détails de l'erreur avec limite de taille pour éviter l'overflow
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
                    
                    // Bouton de redémarrage
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 200,
                        minHeight: 48,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.mounted) {
                            // Redémarre l'app en retournant au welcome au lieu de splash
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/', // CHANGED: from '/splash' to '/'
                              (route) => false, // Supprime toutes les routes précédentes
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

// === UTILITAIRES D'INTERFACE RESPONSIVE ===
// Ces fonctions aident à adapter l'interface selon la taille de l'écran
class ResponsiveLayoutHelper {
  // Détermine si l'écran est petit (largeur < 400px)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }
  
  // Détermine si l'écran est court (hauteur < 600px)
  static bool isShortScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }
  
  // Ajuste la taille de police selon la taille de l'écran
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) {
      return baseSize * 0.9; // Réduit de 10% sur petit écran
    }
    return baseSize;
  }
  
  // Ajuste le padding selon la taille de l'écran
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(12); // Padding réduit sur petit écran
    }
    return const EdgeInsets.all(16); // Padding standard
  }
  
  // Ajuste l'espacement selon la taille de l'écran
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isSmallScreen(context) || isShortScreen(context)) {
      return baseSpacing * 0.75; // Réduit l'espacement sur petits écrans
    }
    return baseSpacing;
  }
}