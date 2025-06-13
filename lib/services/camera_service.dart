// lib/services/camera_service.dart - Fixed memory leaks and permission handling
import 'dart:io';  // FIXED: Uncommented needed import
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';  // FIXED: Uncommented needed import
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize cameras: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static Future<CameraController?> getCameraController() async {
    // Check if cameras are available
    if (!_isInitialized || _cameras == null || _cameras!.isEmpty) {
      await initialize();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    // Dispose existing controller if any
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    try {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return _controller;
    } catch (e) {
      print('Failed to initialize camera controller: $e');
      _controller = null;
      rethrow;
    }
  }

  static Future<String?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile image = await _controller!.takePicture();
      
      // FIXED: Ensure the image file exists and is valid
      final File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('Captured image file not found');
      }
      
      // FIXED: Validate image size
      final stat = await imageFile.stat();
      if (stat.size == 0) {
        throw Exception('Captured image is empty');
      }
      
      return image.path;
    } catch (e) {
      print('Error capturing image: $e');
      rethrow;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // FIXED: Request storage permission before picking
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        throw Exception('Storage permission required to select images');
      }
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,  // FIXED: Add image size limits
        maxHeight: 1080,
      );
      
      if (image != null) {
        // FIXED: Validate selected image
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          throw Exception('Selected image file not found');
        }
        
        final stat = await imageFile.stat();
        if (stat.size == 0) {
          throw Exception('Selected image is empty');
        }
        
        // FIXED: Check file size limit (10MB)
        if (stat.size > 10 * 1024 * 1024) {
          throw Exception('Image too large. Please select an image smaller than 10MB');
        }
      }
      
      return image?.path;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      // FIXED: Request multiple permissions with better error handling
      final Map<Permission, PermissionStatus> permissions = await [
        Permission.camera,
        Permission.storage,
      ].request();
      
      final cameraGranted = permissions[Permission.camera]?.isGranted ?? false;
      final storageGranted = permissions[Permission.storage]?.isGranted ?? false;
      
      if (!cameraGranted) {
        print('Camera permission denied');
      }
      if (!storageGranted) {
        print('Storage permission denied');
      }
      
      return cameraGranted && storageGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // FIXED: Enhanced permission checking
  static Future<bool> hasPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.storage.status;
      
      return cameraStatus.isGranted && storageStatus.isGranted;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  // FIXED: Improved disposal with null safety
  static Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Error disposing camera controller: $e');
    }
  }

  // FIXED: Add method to check if camera is available
  static bool get isAvailable => _isInitialized && _cameras != null && _cameras!.isNotEmpty;
  
  // FIXED: Add method to get camera status
  static bool get isControllerInitialized => _controller?.value.isInitialized ?? false;
  
  // FIXED: Add method to safely get camera count
  static int get cameraCount => _cameras?.length ?? 0;
}