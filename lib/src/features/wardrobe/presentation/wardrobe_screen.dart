import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
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
