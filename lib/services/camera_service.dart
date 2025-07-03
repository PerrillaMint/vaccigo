// lib/services/camera_service.dart - Service de gestion de la caméra avec sécurité renforcée
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Service centralisé pour toutes les opérations liées à la caméra
// Gère l'initialisation, la capture d'images, et la sélection depuis la galerie
// Implémente une gestion robuste des erreurs et de la mémoire
class CameraService {
  // === VARIABLES STATIQUES DE GESTION ===
  // Contrôleur principal de la caméra - null si pas initialisé
  static CameraController? _controller;
  
  // Liste des caméras disponibles sur l'appareil
  static List<CameraDescription>? _cameras;
  
  // Indicateur d'état d'initialisation du service
  static bool _isInitialized = false;
  
  // Indicateur si le service a été volontairement fermé
  static bool _isDisposed = false;
  
  // === INITIALISATION DU SERVICE ===
  // Initialise le service caméra et détecte les caméras disponibles
  static Future<void> initialize() async {
    try {
      _isDisposed = false; // Réinitialise l'état de fermeture
      
      // Récupère la liste de toutes les caméras disponibles sur l'appareil
      // Peut inclure: caméra arrière, avant, zoom, ultra-grand-angle, etc.
      _cameras = await availableCameras();
      
      // Marque comme initialisé seulement si on a au moins une caméra
      _isInitialized = _cameras != null && _cameras!.isNotEmpty;
    } catch (e) {
      print('Échec de l\'initialisation des caméras: $e');
      _isInitialized = false;
      _cameras = null;
      rethrow; // Propage l'erreur pour gestion par l'appelant
    }
  }

  // === OBTENTION DU CONTRÔLEUR CAMÉRA ===
  // Crée et configure un contrôleur de caméra prêt à l'usage
  static Future<CameraController?> getCameraController() async {
    if (_isDisposed) {
      throw Exception('Le service caméra a été fermé');
    }

    // Vérifie si les caméras sont disponibles
    if (!_isInitialized || _cameras == null || _cameras!.isEmpty) {
      await initialize(); // Tente une réinitialisation
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('Aucune caméra disponible sur cet appareil');
    }

    // Ferme le contrôleur existant s'il y en a un
    if (_controller != null) {
      try {
        await _controller!.dispose();
      } catch (e) {
        print('Erreur lors de la fermeture du contrôleur précédent: $e');
      }
      _controller = null;
    }

    try {
      // Crée un nouveau contrôleur avec la première caméra (généralement l'arrière)
      _controller = CameraController(
        _cameras!.first,                    // Utilise la première caméra disponible
        ResolutionPreset.high,              // Qualité élevée pour meilleure reconnaissance
        enableAudio: false,                 // Pas besoin d'audio pour les photos
        imageFormatGroup: ImageFormatGroup.jpeg, // Format JPEG pour compatibilité
      );

      // Initialise le contrôleur de manière asynchrone
      await _controller!.initialize();
      
      // Vérifie si le service n'a pas été fermé pendant l'initialisation
      if (_isDisposed) {
        await _controller!.dispose();
        _controller = null;
        throw Exception('Le service caméra a été fermé pendant l\'initialisation');
      }
      
      return _controller;
    } catch (e) {
      print('Échec de l\'initialisation du contrôleur caméra: $e');
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (disposeError) {
          print('Erreur lors de la fermeture du contrôleur après échec: $disposeError');
        }
      }
      _controller = null;
      rethrow;
    }
  }

  // === CAPTURE D'IMAGE ===
  // Prend une photo avec la caméra et retourne le chemin du fichier
  static Future<String?> captureImage() async {
    if (_isDisposed) {
      throw Exception('Le service caméra a été fermé');
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Caméra non initialisée');
    }

    try {
      // Vérifie que la caméra est prête pour la capture
      if (!_controller!.value.isInitialized || 
          _controller!.value.isTakingPicture ||
          _controller!.value.isStreamingImages) {
        throw Exception('La caméra n\'est pas prête pour la capture');
      }

      // Prend la photo
      final XFile image = await _controller!.takePicture();
      
      // Valide que le fichier image existe et est valide
      final File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('Fichier image capturé introuvable');
      }
      
      // Vérifie la taille du fichier
      final stat = await imageFile.stat();
      if (stat.size == 0) {
        await imageFile.delete(); // Nettoie le fichier vide
        throw Exception('L\'image capturée est vide');
      }
      
      // Vérifie une taille de fichier raisonnable (limite: 50MB)
      if (stat.size > 50 * 1024 * 1024) {
        await imageFile.delete(); // Nettoie le fichier trop volumineux
        throw Exception('L\'image capturée est trop volumineuse');
      }
      
      return image.path;
    } catch (e) {
      print('Erreur lors de la capture d\'image: $e');
      rethrow;
    }
  }

  // === SÉLECTION DEPUIS LA GALERIE ===
  // Permet à l'utilisateur de sélectionner une image depuis sa galerie
  static Future<String?> pickImageFromGallery() async {
    if (_isDisposed) {
      throw Exception('Le service caméra a été fermé');
    }

    final ImagePicker picker = ImagePicker();
    
    try {
      // Gestion complète des permissions pour la galerie
      bool hasPermission = await _checkGalleryPermission();
      if (!hasPermission) {
        hasPermission = await _requestGalleryPermission();
        if (!hasPermission) {
          throw Exception('Permission d\'accès à la galerie requise pour sélectionner des images');
        }
      }
      
      // Sélectionne l'image avec optimisations
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,     // Qualité légèrement réduite pour performance
        maxWidth: 2048,       // Taille maximale raisonnable
        maxHeight: 2048,
        requestFullMetadata: false, // Pas besoin des métadonnées complètes
      );
      
      if (image != null) {
        // Valide l'image sélectionnée
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          throw Exception('Fichier image sélectionné introuvable');
        }
        
        final stat = await imageFile.stat();
        if (stat.size == 0) {
          throw Exception('L\'image sélectionnée est vide');
        }
        
        // Limite de taille pour la galerie (20MB)
        if (stat.size > 20 * 1024 * 1024) {
          throw Exception('Image trop volumineuse. Veuillez sélectionner une image de moins de 20MB');
        }
      }
      
      return image?.path;
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
      rethrow;
    }
  }

  // === GESTION DES PERMISSIONS ===
  
  // Vérifie les permissions d'accès à la galerie
  static Future<bool> _checkGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ utilise des permissions différentes
        if (await _isAndroid13OrHigher()) {
          final status = await Permission.photos.status;
          return status.isGranted;
        } else {
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status.isGranted;
      }
      return true; // Autres plateformes assumées comme autorisées
    } catch (e) {
      print('Erreur lors de la vérification des permissions galerie: $e');
      return false;
    }
  }

  // Demande les permissions d'accès à la galerie
  static Future<bool> _requestGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final status = await Permission.photos.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return true; // Autres plateformes
    } catch (e) {
      print('Erreur lors de la demande de permissions galerie: $e');
      return false;
    }
  }

  // Détecte si l'appareil Android est version 13 ou supérieure
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      // Vérification simple - dans une vraie app vous pourriez utiliser device_info_plus
      return true; // Assume Android moderne pour la sécurité
    } catch (e) {
      return true; // Assume Android moderne si la vérification échoue
    }
  }

  // Demande les permissions caméra (utilisé lors de l'initialisation)
  static Future<bool> requestPermissions() async {
    try {
      // Demande les permissions séparément avec meilleure gestion d'erreur
      final Map<Permission, PermissionStatus> permissions = await [
        Permission.camera,
      ].request();
      
      final cameraGranted = permissions[Permission.camera]?.isGranted ?? false;
      
      if (!cameraGranted) {
        print('Permission caméra refusée');
        return false;
      }
      
      // Permission galerie gérée séparément quand nécessaire
      return true;
    } catch (e) {
      print('Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  // Vérifie que les permissions nécessaires sont accordées
  static Future<bool> hasPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      return cameraStatus.isGranted;
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  // === GESTION DU CYCLE DE VIE ===
  
  // Ferme proprement le service et libère toutes les ressources
  static Future<void> dispose() async {
    _isDisposed = true; // Marque comme fermé
    
    if (_controller != null) {
      try {
        if (_controller!.value.isInitialized) {
          await _controller!.dispose();
        }
      } catch (e) {
        print('Erreur lors de la fermeture du contrôleur caméra: $e');
      } finally {
        _controller = null;
      }
    }
    
    // Réinitialise les variables d'état
    _isInitialized = false;
    _cameras = null;
  }

  // === MÉTHODES DE STATUT ===
  
  // Vérifie si la caméra est disponible et fonctionnelle
  static bool get isAvailable => !_isDisposed && _isInitialized && _cameras != null && _cameras!.isNotEmpty;
  
  // Vérifie si le contrôleur est initialisé et prêt
  static bool get isControllerInitialized => !_isDisposed && _controller?.value.isInitialized == true;
  
  // Retourne le nombre de caméras disponibles
  static int get cameraCount => _isDisposed ? 0 : (_cameras?.length ?? 0);

  // Vérifie si le service a été fermé
  static bool get isDisposed => _isDisposed;

  // === REDÉMARRAGE DU SERVICE ===
  // Redémarre complètement le service (utile après mise en arrière-plan)
  static Future<void> restart() async {
    await dispose();                                      // Ferme tout proprement
    await Future.delayed(const Duration(milliseconds: 100)); // Petit délai
    await initialize();                                   // Réinitialise
  }
}