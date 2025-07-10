// lib/models/scanned_vaccination_data.dart - Modèle amélioré avec lot optionnel
class ScannedVaccinationData {
  final String vaccineName;
  final String lot; // Peut être vide - optionnel
  final String date;
  final String ps;
  final double confidence;
  
  // Métadonnées supplémentaires pour l'analyse
  final List<String> alternativeNames;
  final String originalText;
  final bool isMultipleDetection;

  ScannedVaccinationData({
    required this.vaccineName,
    this.lot = '', // Par défaut vide - lot optionnel
    required this.date,
    this.ps = '',
    this.confidence = 0.5,
    this.alternativeNames = const [],
    this.originalText = '',
    this.isMultipleDetection = false,
  });

  // Constructeur pour créer depuis les données de vision IA
  factory ScannedVaccinationData.fromAI({
    required String vaccineName,
    String? lot,
    required String date,
    String? ps,
    double? confidence,
    String? originalText,
  }) {
    return ScannedVaccinationData(
      vaccineName: vaccineName.isNotEmpty ? vaccineName : 'Vaccination détectée',
      lot: lot ?? '', // Lot optionnel
      date: date,
      ps: ps ?? 'Extrait automatiquement',
      confidence: (confidence ?? 0.5).clamp(0.0, 1.0),
      originalText: originalText ?? '',
    );
  }

  // Constructeur de fallback pour erreurs
  factory ScannedVaccinationData.fallback({
    String? vaccineName,
    String? date,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    final currentDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    return ScannedVaccinationData(
      vaccineName: vaccineName ?? 'Vaccination',
      lot: '', // Pas de lot en cas d'erreur
      date: date ?? currentDate,
      ps: errorMessage ?? 'Données à vérifier',
      confidence: 0.2,
    );
  }

  // Validation des données
  bool get isValid {
    return vaccineName.isNotEmpty && 
           date.isNotEmpty && 
           _isValidDate(date);
  }

  // Vérifie si la date est dans un format valide
  bool _isValidDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year + 1) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Vérifie si les données semblent fiables
  bool get isReliable => confidence >= 0.6 && isValid;

  // Vérifie si un lot a été détecté
  bool get hasLot => lot.isNotEmpty;

  // Retourne un score de qualité de 0 à 100
  int get qualityScore {
    int score = 0;
    
    // Score basé sur la confiance (40 points max)
    score += (confidence * 40).round();
    
    // Score basé sur le nom du vaccin (30 points max)
    if (vaccineName.length > 5) score += 30;
    else if (vaccineName.length > 2) score += 20;
    else score += 10;
    
    // Score pour le lot (15 points max)
    if (hasLot && lot.length >= 3) score += 15;
    
    // Score pour la date (15 points max)
    if (isValid) score += 15;
    
    return score.clamp(0, 100);
  }

  // Niveau de qualité sous forme de texte
  String get qualityLevel {
    final score = qualityScore;
    if (score >= 80) return 'Excellente';
    if (score >= 60) return 'Bonne';
    if (score >= 40) return 'Correcte';
    return 'À vérifier';
  }

  // Couleur associée au niveau de qualité
  String get qualityColorHex {
    final score = qualityScore;
    if (score >= 80) return '#4CAF50'; // Vert
    if (score >= 60) return '#FFA726'; // Orange
    if (score >= 40) return '#FF9800'; // Orange foncé
    return '#F44336'; // Rouge
  }

  // Copie avec modifications
  ScannedVaccinationData copyWith({
    String? vaccineName,
    String? lot,
    String? date,
    String? ps,
    double? confidence,
    List<String>? alternativeNames,
    String? originalText,
    bool? isMultipleDetection,
  }) {
    return ScannedVaccinationData(
      vaccineName: vaccineName ?? this.vaccineName,
      lot: lot ?? this.lot, // Préserve le lot optionnel
      date: date ?? this.date,
      ps: ps ?? this.ps,
      confidence: confidence ?? this.confidence,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      originalText: originalText ?? this.originalText,
      isMultipleDetection: isMultipleDetection ?? this.isMultipleDetection,
    );
  }

  // Conversion vers Map pour stockage/transmission
  Map<String, dynamic> toMap() {
    return {
      'vaccineName': vaccineName,
      'lot': lot, // Peut être vide
      'date': date,
      'ps': ps,
      'confidence': confidence,
      'alternativeNames': alternativeNames,
      'originalText': originalText,
      'isMultipleDetection': isMultipleDetection,
      'qualityScore': qualityScore,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Création depuis Map
  factory ScannedVaccinationData.fromMap(Map<String, dynamic> map) {
    return ScannedVaccinationData(
      vaccineName: map['vaccineName'] ?? '',
      lot: map['lot'] ?? '', // Lot optionnel
      date: map['date'] ?? '',
      ps: map['ps'] ?? '',
      confidence: (map['confidence'] ?? 0.5).toDouble(),
      alternativeNames: List<String>.from(map['alternativeNames'] ?? []),
      originalText: map['originalText'] ?? '',
      isMultipleDetection: map['isMultipleDetection'] ?? false,
    );
  }

  // Représentation JSON
  String toJson() {
    return '''
{
  "vaccineName": "$vaccineName",
  "lot": "$lot",
  "date": "$date",
  "ps": "$ps",
  "confidence": $confidence,
  "qualityScore": $qualityScore,
  "qualityLevel": "$qualityLevel",
  "hasLot": $hasLot,
  "isValid": $isValid,
  "isReliable": $isReliable
}''';
  }

  // Représentation pour debug
  @override
  String toString() {
    return 'ScannedVaccinationData('
        'vaccin: $vaccineName, '
        'lot: ${lot.isNotEmpty ? lot : 'aucun'}, '
        'date: $date, '
        'confiance: ${(confidence * 100).toStringAsFixed(1)}%, '
        'qualité: $qualityLevel'
        ')';
  }

  // Égalité
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedVaccinationData &&
        other.vaccineName == vaccineName &&
        other.lot == lot &&
        other.date == date &&
        other.ps == ps;
  }

  @override
  int get hashCode {
    return vaccineName.hashCode ^
        lot.hashCode ^
        date.hashCode ^
        ps.hashCode;
  }

  // Méthodes utilitaires pour l'interface

  // Retourne une description lisible du vaccin
  String get displayName {
    if (vaccineName.toLowerCase().contains('covid')) {
      return '🦠 $vaccineName';
    } else if (vaccineName.toLowerCase().contains('grippe')) {
      return '🤧 $vaccineName';
    } else if (vaccineName.toLowerCase().contains('ror') || 
               vaccineName.toLowerCase().contains('mmr')) {
      return '👶 $vaccineName';
    } else if (vaccineName.toLowerCase().contains('dtp') || 
               vaccineName.toLowerCase().contains('tétanos')) {
      return '💉 $vaccineName';
    }
    return '💉 $vaccineName';
  }

  // Retourne une description de la date formatée
  String get formattedDate {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        final months = [
          '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        
        return '$day ${months[month]} $year';
      }
    } catch (e) {
      // Ignore et retourne la date originale
    }
    return date;
  }

  // Retourne des suggestions d'amélioration
  List<String> get improvementSuggestions {
    final suggestions = <String>[];
    
    if (confidence < 0.6) {
      suggestions.add('Reprendre la photo avec un meilleur éclairage');
    }
    
    if (vaccineName.length < 5) {
      suggestions.add('Vérifier le nom du vaccin');
    }
    
    if (!hasLot) {
      suggestions.add('Le numéro de lot n\'a pas été détecté (optionnel)');
    }
    
    if (!_isValidDate(date)) {
      suggestions.add('Vérifier le format de la date');
    }
    
    if (ps.isEmpty) {
      suggestions.add('Ajouter des informations supplémentaires si nécessaire');
    }
    
    return suggestions;
  }
}