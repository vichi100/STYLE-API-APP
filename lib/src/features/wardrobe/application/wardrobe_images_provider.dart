import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'; // For AssetManifest if needed, but services handles rootBundle
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wardrobe_images_provider.g.dart';

@riverpod
Future<List<String>> wardrobeImages(WardrobeImagesRef ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets();

  return assets
      .where((String key) =>
          key.startsWith('assets/images/wardrobe/') &&
          (key.endsWith('.png') ||
              key.endsWith('.jpg') ||
              key.endsWith('.jpeg') ||
              key.endsWith('.webp')))
      .toList();
}
