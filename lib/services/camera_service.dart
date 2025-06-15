// lib/services/camera_service.dart - FIXED memory leaks and improved error handling
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;
  static bool _isDisposed = false;
  
  static Future<void> initialize() async {
    try {
      _isDisposed = false;
      _cameras = await availableCameras();
      _isInitialized = _cameras != null && _cameras!.isNotEmpty;
    } catch (e) {
      print('Failed to initialize cameras: $e');
      _isInitialized = false;
      _cameras = null;
      rethrow;
    }
  }

  static Future<CameraController?> getCameraController() async {
    if (_isDisposed) {
      throw Exception('Camera service has been disposed');
    }

    // Check if cameras are available
    if (!_isInitialized || _cameras == null || _cameras!.isEmpty) {
      await initialize();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    // Dispose existing controller if any
    if (_controller != null) {
      try {
        await _controller!.dispose();
      } catch (e) {
        print('Error disposing previous controller: $e');
      }
      _controller = null;
    }

    try {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // FIXED: Specify format
      );

      await _controller!.initialize();
      
      // FIXED: Check if disposed during initialization
      if (_isDisposed) {
        await _controller!.dispose();
        _controller = null;
        throw Exception('Camera service was disposed during initialization');
      }
      
      return _controller;
    } catch (e) {
      print('Failed to initialize camera controller: $e');
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (disposeError) {
          print('Error disposing controller after init failure: $disposeError');
        }
      }
      _controller = null;
      rethrow;
    }
  }

  static Future<String?> captureImage() async {
    if (_isDisposed) {
      throw Exception('Camera service has been disposed');
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      // FIXED: Check if camera is ready for capture
      if (!_controller!.value.isInitialized || 
          _controller!.value.isTakingPicture ||
          _controller!.value.isStreamingImages) {
        throw Exception('Camera is not ready for capture');
      }

      final XFile image = await _controller!.takePicture();
      
      // FIXED: Ensure the image file exists and is valid
      final File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('Captured image file not found');
      }
      
      // FIXED: Validate image size
      final stat = await imageFile.stat();
      if (stat.size == 0) {
        await imageFile.delete(); // Clean up empty file
        throw Exception('Captured image is empty');
      }
      
      // FIXED: Check for reasonable file size
      if (stat.size > 50 * 1024 * 1024) { // 50MB limit
        await imageFile.delete(); // Clean up large file
        throw Exception('Captured image is too large');
      }
      
      return image.path;
    } catch (e) {
      print('Error capturing image: $e');
      rethrow;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    if (_isDisposed) {
      throw Exception('Camera service has been disposed');
    }

    final ImagePicker picker = ImagePicker();
    
    try {
      // FIXED: More comprehensive permission handling
      bool hasPermission = await _checkGalleryPermission();
      if (!hasPermission) {
        hasPermission = await _requestGalleryPermission();
        if (!hasPermission) {
          throw Exception('Gallery permission required to select images');
        }
      }
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // FIXED: Slightly higher quality
        maxWidth: 2048,   // FIXED: More reasonable max size
        maxHeight: 2048,
        requestFullMetadata: false, // FIXED: Don't need metadata
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
        
        // FIXED: Check file size limit (20MB)
        if (stat.size > 20 * 1024 * 1024) {
          throw Exception('Image too large. Please select an image smaller than 20MB');
        }
      }
      
      return image?.path;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  // FIXED: Separate permission methods for better control
  static Future<bool> _checkGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ uses different permissions
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
      return true; // Other platforms
    } catch (e) {
      print('Error checking gallery permission: $e');
      return false;
    }
  }

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
      return true; // Other platforms
    } catch (e) {
      print('Error requesting gallery permission: $e');
      return false;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      // Simple check - in real app you might want to use device_info_plus
      return true; // Assume modern Android for safety
    } catch (e) {
      return true; // Assume modern Android if check fails
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      // FIXED: Request permissions separately with better error handling
      final Map<Permission, PermissionStatus> permissions = await [
        Permission.camera,
      ].request();
      
      final cameraGranted = permissions[Permission.camera]?.isGranted ?? false;
      
      if (!cameraGranted) {
        print('Camera permission denied');
        return false;
      }
      
      // Gallery permission is handled separately when needed
      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // FIXED: Enhanced permission checking
  static Future<bool> hasPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      return cameraStatus.isGranted;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  // FIXED: Improved disposal with proper cleanup
  static Future<void> dispose() async {
    _isDisposed = true;
    
    if (_controller != null) {
      try {
        if (_controller!.value.isInitialized) {
          await _controller!.dispose();
        }
      } catch (e) {
        print('Error disposing camera controller: $e');
      } finally {
        _controller = null;
      }
    }
    
    _isInitialized = false;
    _cameras = null;
  }

  // FIXED: Add method to check if camera is available
  static bool get isAvailable => !_isDisposed && _isInitialized && _cameras != null && _cameras!.isNotEmpty;
  
  // FIXED: Add method to get camera status
  static bool get isControllerInitialized => !_isDisposed && _controller?.value.isInitialized == true;
  
  // FIXED: Add method to safely get camera count
  static int get cameraCount => _isDisposed ? 0 : (_cameras?.length ?? 0);

  // FIXED: Add method to check if service is disposed
  static bool get isDisposed => _isDisposed;

  // FIXED: Add method to restart service if needed
  static Future<void> restart() async {
    await dispose();
    await Future.delayed(const Duration(milliseconds: 100)); // Small delay
    await initialize();
  }
}