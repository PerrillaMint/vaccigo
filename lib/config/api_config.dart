// lib/config/api_config.dart
// Configuration centralisée pour toutes les clés API de l'application
class ApiConfig {
  // Clé API Google Vision pour l'analyse d'images de carnet de vaccination
  // IMPORTANT: Remplacez par votre vraie clé API Google Cloud Vision
  // Cette clé permet d'utiliser l'API de reconnaissance de texte dans les images
  static const String googleVisionApiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';
  
  // Instructions pour obtenir votre clé API Google Vision:
  // 1. Allez sur https://console.cloud.google.com/
  // 2. Créez un nouveau projet ou sélectionnez un projet existant
  // 3. Activez l'API Vision dans la bibliothèque d'APIs
  // 4. Créez des identifiants (clé API) dans la section "Identifiants"
  // 5. Restreignez la clé API à l'API Vision uniquement pour la sécurité
  // 6. Copiez la clé et remplacez la valeur ci-dessus
  
  // URL de base pour l'API Google Vision
  // Cette URL est utilisée pour faire des requêtes de reconnaissance de texte
  static const String visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
}
