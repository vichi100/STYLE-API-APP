import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

enum ImageType {
  garment,
  person,
}

class ImageHelper {
  static Future<File> processImage(
    File file, {
    required ImageType type,
  }) async {
    final settings = _settingsFor(type);
    final tempDir = await getTemporaryDirectory();
    final uniqueId = DateTime.now().microsecondsSinceEpoch.toString() + '_' + (1000 + DateTime.now().millisecond).toString(); 
    final targetPath = '${tempDir.path}/$uniqueId.jpg';

    // Native compression + Resize + Rotation in one go
    // This runs on native thread (Android/iOS), not Dart thread
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: settings.quality,
      minWidth: settings.maxSize,
      minHeight: settings.maxSize,
      autoCorrectionAngle: true, // Handles EXIF rotation natively
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      // Fallback if native compression fails
      return file;
    }

    return File(result.path);
  }

  static _ImageSettings _settingsFor(ImageType type) {
    switch (type) {
      case ImageType.garment:
        return _ImageSettings(maxSize: 1536, quality: 80);
      case ImageType.person:
        return _ImageSettings(maxSize: 2048, quality: 75);
    }
  }
}

class _ImageSettings {
  final int maxSize;
  final int quality;

  _ImageSettings({
    required this.maxSize,
    required this.quality,
  });
}
