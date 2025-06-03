// lib/services/camera_service.dart
//import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  
  static Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  static Future<CameraController?> getCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      return null;
    }

    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    return _controller;
  }

  static Future<String?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      return image?.path;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}