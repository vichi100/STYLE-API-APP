import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
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
    final Uint8List bytes = await file.readAsBytes();

    // Decode (handles HEIC → RGB on iOS)
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    // Fix EXIF rotation (VERY important for iOS)
    decoded = img.bakeOrientation(decoded);

    // Choose settings based on image type
    final settings = _settingsFor(type);

    // Resize while keeping aspect ratio
    if (decoded.width > settings.maxSize ||
        decoded.height > settings.maxSize) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? settings.maxSize : null,
        height: decoded.height >= decoded.width ? settings.maxSize : null,
      );
    }

    // Encode JPEG
    final jpgBytes = img.encodeJpg(
      decoded,
      quality: settings.quality,
    );

    final tempDir = await getTemporaryDirectory();
    final output = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Final compression pass (safe + small)
    final compressed = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(jpgBytes),
      quality: settings.quality,
      format: CompressFormat.jpeg,
    );

    await output.writeAsBytes(compressed);
    return output;
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
