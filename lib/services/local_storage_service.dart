import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<Directory> getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory> getImagesDirectory() async {
    final docs = await getDocumentsDirectory();
    final imagesDir = Directory(p.join(docs.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  static Future<String> saveImageFile(File source, {String? fileName}) async {
    final imagesDir = await getImagesDirectory();
    final targetName =
        fileName ?? '${DateTime.now().millisecondsSinceEpoch}${p.extension(source.path)}';
    final targetPath = p.join(imagesDir.path, targetName);
    await source.copy(targetPath);
    return targetPath;
  }

  static Future<void> deleteImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
