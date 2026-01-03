import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FashionCameraScreen extends StatefulWidget {
  const FashionCameraScreen({super.key});

  @override
  State<FashionCameraScreen> createState() => _FashionCameraScreenState();
}

class _FashionCameraScreenState extends State<FashionCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    // Default to back camera
    final firstCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.veryHigh, // High quality for fashion details
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      // Return the file path to the calling screen
      if (mounted) {
        Navigator.pop(context, image);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: The Camera Feed
          CameraPreview(_controller!),

          // LAYER 2: The "Ghost" Overlay
          // This darkens the corners and highlights the center
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5), 
              BlendMode.srcOut // Cuts a hole in the dark layer
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ), // Background is transparent
                  child: Center(
                    child: Container(
                      width: 300, 
                      height: 550, // Roughly human proportions (vertical)
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(200), // Oval shape
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LAYER 3: Guidance & Indicators
          Center(
            child: SizedBox(
              width: 300, 
              height: 550,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      "TOP",
                      style: TextStyle(
                        color: Colors.white, // Fully opaque
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black),
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.add, 
                    color: Colors.white70, 
                    size: 40,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black),
                    ],
                  ), // Center mark
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "BOTTOM",
                      style: TextStyle(
                        color: Colors.white, // Fully opaque
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black),
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            top: 60, 
            left: 0, 
            right: 0,
            child: Text(
              "Align within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
          
          // Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // LAYER 4: Shutter Button (Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
