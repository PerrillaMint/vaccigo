// lib/config/api_config.dart
class ApiConfig {
  // Replace with your actual Google Cloud Vision API key
  static const String googleVisionApiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';
  
  // You can get this from Google Cloud Console:
  // 1. Go to https://console.cloud.google.com/
  // 2. Create a new project or select existing
  // 3. Enable Vision API
  // 4. Create credentials (API Key)
  // 5. Restrict the API key to Vision API only for security
  
  static const String visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
}