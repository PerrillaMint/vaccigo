// lib/models/vaccination.dart
// Modèle pour représenter une vaccination dans le carnet numérique
import 'package:hive/hive.dart';

// Génère automatiquement vaccination.g.dart avec les adaptateurs Hive
part 'vaccination.g.dart';

// Annotation Hive pour la sérialisation - typeId: 1 (unique dans l'app)
@HiveType(typeId: 1)
class Vaccination extends HiveObject {
  // Nom du vaccin (ex: "Pfizer-BioNTech COVID-19", "Grippe saisonnière 2024")
  // Ce champ contient l'identification complète du vaccin reçu
  @HiveField(0)
  String vaccineName;

  // Numéro de lot du vaccin - traçabilité pharmaceutique
  // Format variable selon le fabricant (ex: "EW0553", "FF1234", "ABC-2024-001")
  // Permet de retrouver les détails de fabrication en cas de problème
  @HiveField(1)
  String lot;

  // Date de vaccination au format DD/MM/YYYY
  // Date à laquelle l'injection a été administrée
  @HiveField(2)
  String date;

  // Informations supplémentaires (Professionnel de Santé, notes)
  // Peut contenir: nom du médecin, pharmacien, centre de vaccination,
  // numéro de dose (1ère, 2ème, rappel), réactions observées, etc.
  @HiveField(3)
  String ps;

  // ID de l'utilisateur propriétaire de cette vaccination
  // Référence vers User.key pour lier la vaccination à son propriétaire
  // Permet de filtrer les vaccinations par utilisateur
  @HiveField(4)
  String userId;

  // Constructeur principal avec tous les champs obligatoires
  // Tous les champs sont requis pour assurer l'intégrité des données
  Vaccination({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.userId,
  });
}