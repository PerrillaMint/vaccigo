// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

// Définition centralisée de toutes les couleurs utilisées dans l'application
// Cette approche garantit une cohérence visuelle dans toute l'app
class AppColors {
  // === COULEURS PRINCIPALES ===
  // Ces couleurs sont extraites du logo Vaccigo pour maintenir l'identité visuelle
  
  // Bleu marine - couleur principale de la marque, utilisée pour les éléments importants
  static const Color primary = Color(0xFF2C5F66);
  
  // Turquoise - couleur secondaire, utilisée pour les accents et boutons secondaires
  static const Color secondary = Color(0xFF7DD3D8);
  
  // Orange - couleur d'accent, utilisée pour attirer l'attention (boutons CTA, notifications)
  static const Color accent = Color(0xFFFFA726);
  
  // Turquoise clair - variante douce de la couleur secondaire
  static const Color light = Color(0xFFB8E6EA);
  
  // === COULEURS DE FOND ===
  // Arrière-plan principal - bleu très clair pour un look propre et médical
  static const Color background = Color(0xFFF8FCFD);
  
  // Surface des cartes et éléments - blanc pur pour les conteneurs
  static const Color surface = Colors.white;
  
  // Variante de surface - légèrement teintée pour créer de la profondeur
  static const Color surfaceVariant = Color(0xFFF5F9FA);
  
  // === COULEURS DE TEXTE ===
  // Texte sur couleur primaire (boutons, headers)
  static const Color onPrimary = Colors.white;
  
  // Texte sur couleur secondaire
  static const Color onSecondary = Color(0xFF2C5F66);
  
  // Texte sur surface (cartes, fond)
  static const Color onSurface = Color(0xFF2C5F66);
  
  // Texte principal - même couleur que primary pour la cohérence
  static const Color textPrimary = Color(0xFF2C5F66);
  
  // Texte secondaire - gris moyen pour les sous-titres et descriptions
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Texte atténué - gris clair pour les éléments moins importants
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // === COULEURS DE STATUS ===
  // Ces couleurs suivent les conventions universelles pour les états
  
  // Vert - succès, validation, éléments positifs
  static const Color success = Color(0xFF10B981);
  
  // Orange - attention, avertissements non critiques
  static const Color warning = Color(0xFFF59E0B);
  
  // Rouge - erreurs, actions destructives, problèmes critiques
  static const Color error = Color(0xFFEF4444);
  
  // Bleu - informations neutres, liens, éléments informatifs
  static const Color info = Color(0xFF3B82F6);
  
  // === DÉGRADÉS ===
  // Dégradé principal - utilisé pour les headers et éléments visuels importants
  // Créé avec les couleurs secondaire et light pour un effet doux
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,      // Commence en haut à gauche
    end: Alignment.bottomRight,    // Finit en bas à droite
    colors: [secondary, light],    // Transition turquoise vers turquoise clair
  );
  
  // Dégradé d'accent - utilisé pour les boutons spéciaux et call-to-action
  // Utilise l'orange avec une variante plus claire pour créer de la profondeur
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFFFB74D)], // Orange vers orange clair
  );
}