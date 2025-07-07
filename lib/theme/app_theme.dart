// lib/theme/app_theme.dart - Thème global de l'application avec Material Design 3
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// Classe de configuration du thème global de l'application
// Utilise Material Design 3 avec personnalisation complète des couleurs et composants
// Assure une cohérence visuelle dans toute l'application
class AppTheme {
  // Thème clair principal de l'application
  static ThemeData get lightTheme {
    return ThemeData(
      // Active Material Design 3 pour les dernières spécifications
      useMaterial3: true,
      
      // Couleur primaire de l'application (bleu marine Vaccigo)
      primaryColor: AppColors.primary,
      
      // Couleur d'arrière-plan des Scaffold (écrans principaux)
      scaffoldBackgroundColor: AppColors.background,
      
      // Police moderne et lisible pour toute l'application
      fontFamily: 'Inter',
      
      // === PALETTE DE COULEURS COMPLÈTE ===
      // Définit toutes les couleurs utilisées par les composants Material
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,           // Couleur principale (boutons, headers)
        secondary: AppColors.secondary,       // Couleur secondaire (accents, liens)
        surface: AppColors.surface,           // Couleur des cartes et conteneurs
        background: AppColors.background,     // Arrière-plan général
        error: AppColors.error,               // Couleur d'erreur
        onPrimary: AppColors.onPrimary,       // Texte sur couleur primaire
        onSecondary: AppColors.onSecondary,   // Texte sur couleur secondaire
        onSurface: AppColors.onSurface,       // Texte sur surfaces
        onBackground: AppColors.textPrimary,  // Texte sur arrière-plan
      ),
      
      // === STYLE DE LA BARRE D'APPLICATION ===
      // AppBar moderne sans ombre avec couleurs cohérentes
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,  // Arrière-plan transparent
        elevation: 0,                        // Pas d'ombre par défaut
        scrolledUnderElevation: 0,           // Pas d'ombre au scroll
        foregroundColor: AppColors.primary,  // Couleur du texte et icônes
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
      
      // === STYLE DES BOUTONS ÉLEVÉS ===
      // Boutons principaux avec ombre et couleurs de marque
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,                                    // Ombre subtile
          shadowColor: AppColors.primary.withOpacity(0.3), // Couleur d'ombre
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),       // Coins arrondis modernes
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // === STYLE DES BOUTONS CONTOURS ===
      // Boutons secondaires avec bordure et sans remplissage
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // === STYLE DES BOUTONS TEXTE ===
      // Boutons tertiaires sans arrière-plan
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // === STYLE DES CARTES ===
      // Cartes avec ombre moderne et coins arrondis
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 4,                                      // Ombre pour la profondeur
        shadowColor: Colors.black.withOpacity(0.1),       // Ombre subtile
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),         // Coins très arrondis
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // === STYLE DES CHAMPS DE SAISIE ===
      // Design moderne avec remplissage et validation visuelle
      inputDecorationTheme: InputDecorationTheme(
        filled: true,                                      // Arrière-plan rempli
        fillColor: AppColors.surface,
        
        // Bordure par défaut (état normal)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        
        // Bordure quand le champ est activé mais pas en focus
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        
        // Bordure quand le champ est en focus
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        
        // Bordure en cas d'erreur
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        
        // Espacement interne du contenu
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        
        // Style du texte d'aide (placeholder)
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        
        // Style des labels
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // === STYLE DES SNACKBARS ===
      // Notifications temporaires avec design moderne
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,               // Flottant au-dessus du contenu
      ),
      
      // === STYLE DES BOTTOM SHEETS ===
      // Feuilles modales avec coins arrondis
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}