import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:style_advisor/src/features/camera/presentation/fashion_camera_screen.dart';
import 'package:style_advisor/src/utils/image_helper.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<List<String>> _getWardrobeImages(BuildContext context) async {
    // Use the new AssetManifest API (Flutter 3.19+)
    final manifest = await AssetManifest.loadFromAssetBundle(DefaultAssetBundle.of(context));
    final assets = manifest.listAssets();
    
    // Filter assets that start with assets/images/wardrobe/
    return assets
        .where((String key) => key.startsWith('assets/images/wardrobe/') && 
               // Ensure it's not the directory itself if caught, and is an image file
               (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.webp')))
        .toList();
  }

  Future<void> _processPickedFile(XFile? rawImage) async {
     try {
      if (rawImage != null) {
        final File rawFile = File(rawImage.path);
        // ignore: avoid_print
        print("Original Wardrobe Image Size: ${(await rawFile.length()) / 1024} KB");

        // Compress using ImageHelper optimized for garments
        final File compressedFile = await ImageHelper.processImage(
          rawFile,
          type: ImageType.garment,
        );

        if (mounted) {
          // For now, we just show a snackbar and print the size
          // In a real app, you'd upload this to your backend
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image compressed to ${(await compressedFile.length()) ~/ 1024} KB')),
          );
          // ignore: avoid_print
          print("Compressed Wardrobe Image Size: ${(await compressedFile.length()) / 1024} KB");
          // ignore: avoid_print
          print("New Wardrobe Item Path: ${compressedFile.path}");
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
         final XFile? image = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FashionCameraScreen()),
        );
        _processPickedFile(image);
      } else {
        final XFile? rawImage = await _picker.pickImage(source: source);
        _processPickedFile(rawImage);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take Photo (Silhouette Mode)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _showImageSourceModal(context),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _getWardrobeImages(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final images = snapshot.data ?? [];

          if (images.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.checkroom, size: 64, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('Your wardrobe is empty.'),
                   Text('Add images to assets/images/wardrobe/'),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8, // Slightly tall for clothing items
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: Image.asset(
                  images[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
