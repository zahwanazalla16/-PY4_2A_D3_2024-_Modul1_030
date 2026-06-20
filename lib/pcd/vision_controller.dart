import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  
  // Smart Vision Toggle & Flashlight
  bool _isFlashOn = false;
  bool get isFlashOn => _isFlashOn;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        errorMessage = "No camera";
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
      isInitialized = true;
    } catch (e) {
      errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Toggle Flash/Torch
  Future<void> toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        // Turn off flash
        await controller!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } else {
        // Turn on flash (torch mode)
        await controller!.setFlashMode(FlashMode.torch);
        _isFlashOn = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // Turn off flash when app minimized
      try {
        controller!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } catch (_) {}
      
      controller!.dispose();
      isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      controller?.setFlashMode(FlashMode.off);
    } catch (_) {}
    controller?.dispose();
    super.dispose();
  }
}