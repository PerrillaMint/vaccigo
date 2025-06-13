// lib/main.dart - Fixed with missing import
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user.dart';
import 'models/vaccination.dart';
import 'models/vaccine_category.dart';
import 'models/travel.dart';  // FIXED: Added missing import
import 'services/database_service.dart';
import 'services/camera_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize camera service with error handling
  try {
    await CameraService.initialize();
  } catch (e) {
    debugPrint('Camera initialization failed: $e');
    // App can continue without camera functionality
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters with error handling
  try {
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(VaccinationAdapter());
    Hive.registerAdapter(VaccineCategoryAdapter());
    Hive.registerAdapter(TravelAdapter());  // FIXED: Now properly imported
  } catch (e) {
    debugPrint('Hive adapter registration failed: $e');
    rethrow; // This is critical, app cannot continue
  }
  
  // Initialize default categories
  try {
    final databaseService = DatabaseService();
    await databaseService.initializeDefaultCategories();
  } catch (e) {
    debugPrint('Database initialization failed: $e');
    // App can continue with empty categories
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnet de Vaccination',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5C5EDD),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Times New Roman',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C5EDD),
          primary: const Color(0xFF5C5EDD),
        ),
      ),
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
        '/user-creation': (context) => const UserCreationScreen(),
        '/additional-info': (context) => const AdditionalInfoScreen(),
        '/vaccination-summary': (context) => const VaccinationSummaryScreen(),
        '/vaccination-management': (context) => const VaccinationManagementScreen(),
      },
      // FIXED: Added error handling for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        );
      },
    );
  }
}