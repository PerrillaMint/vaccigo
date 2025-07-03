// lib/models/scanned_vaccination_data.dart
// Modèle pour représenter les données extraites d'un carnet de vaccination scanné
// Cette classe encapsule les informations détectées par l'IA lors du scan d'image

class ScannedVaccinationData {
  // Nom du vaccin détecté (ex: "Pfizer-BioNTech COVID-19", "Grippe saisonnière")
  final String vaccineName;
  
  // Numéro de lot du vaccin - identifiant unique pour traçabilité
  // Format typique: lettres + chiffres (ex: "EW0553", "FF1234")
  final String lot;
  
  // Date de vaccination au format DD/MM/YYYY
  // Cette date est extraite du carnet puis normalisée
  final String date;
  
  // Informations supplémentaires (Professionnel de Santé, notes, etc.)
  // Peut contenir: nom du médecin, lieu de vaccination, numéro de dose
  final String ps;
  
  // Niveau de confiance de l'IA (0.0 = aucune confiance, 1.0 = certitude absolue)
  // Utilisé pour déterminer si une vérification manuelle est nécessaire
  final double confidence;

  // Constructeur principal avec tous les champs requis
  ScannedVaccinationData({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.confidence,
  });

  // Factory constructor pour créer une instance à partir des résultats de l'IA
  // Utilisé après le traitement par Google Vision API ou ML Kit
  factory ScannedVaccinationData.fromAI(Map<String, dynamic> aiResult) {
    return ScannedVaccinationData(
      // Extrait le nom du vaccin ou utilise une chaîne vide par défaut
      vaccineName: aiResult['vaccine_name'] ?? '',
      
      // Extrait le numéro de lot ou utilise une chaîne vide par défaut
      lot: aiResult['lot_number'] ?? '',
      
      // Extrait la date ou utilise une chaîne vide par défaut
      date: aiResult['date'] ?? '',
      
      // Extrait les infos supplémentaires ou utilise une chaîne vide par défaut
      ps: aiResult['additional_info'] ?? '',
      
      // Extrait la confiance et s'assure que c'est un double (0.0 par défaut)
      confidence: (aiResult['confidence'] ?? 0.0).toDouble(),
    );
  }
}