import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  static Future<String?> saveImage(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'item_images'));
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      final id = const Uuid().v4();
      final destPath = p.join(imagesDir.path, '$id.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        destPath,
        quality: 82,
        format: CompressFormat.jpeg,
      );

      return result?.path;
    } catch (_) {
      return null;
    }
  }

  static void deleteImage(String? imagePath) {
    if (imagePath == null) return;
    try {
      final file = File(imagePath);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
