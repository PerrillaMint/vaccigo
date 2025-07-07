// lib/models/vaccine_category.dart - Modèle pour organiser les vaccins par catégories
import 'package:hive/hive.dart';

// Génère automatiquement vaccine_category.g.dart avec les adaptateurs Hive
part 'vaccine_category.g.dart';

// Annotation Hive pour la sérialisation - typeId: 2 (unique dans l'app)
@HiveType(typeId: 2)
class VaccineCategory extends HiveObject {
  // Nom de la catégorie (ex: "Vaccinations obligatoires", "Vaccins de voyage")
  // Titre affiché dans l'interface utilisateur pour regrouper les vaccins
  @HiveField(0)
  String name;

  // Type d'icône pour l'affichage visuel de la catégorie
  // Valeurs possibles: 'check_circle', 'recommend', 'flight', 'vaccines'
  // Permet d'avoir des icônes différentes selon le type de catégorie
  @HiveField(1)
  String iconType;

  // Couleur hexadécimale pour l'affichage de la catégorie
  // Format: '#RRGGBB' (ex: '#4CAF50' pour vert, '#FFA726' pour orange)
  // Utilisée pour les icônes, bordures et éléments visuels
  @HiveField(2)
  String colorHex;

  // Liste des noms de vaccins appartenant à cette catégorie
  // Permet de regrouper logiquement les vaccins par thème ou usage
  // Ex: ['DTP', 'Poliomyélite', 'Coqueluche'] pour vaccins obligatoires
  @HiveField(3)
  List<String> vaccines;

  // Constructeur principal avec tous les champs obligatoires
  // Permet de créer des catégories personnalisées ou par défaut
  VaccineCategory({
    required this.name,
    required this.iconType,
    required this.colorHex,
    required this.vaccines,
  });
}