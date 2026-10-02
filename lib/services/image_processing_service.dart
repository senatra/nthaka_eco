import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:nthaka_eco/services/local_storage_service.dart';
import 'package:path/path.dart' as p;

/// Keeps inference and UI preview images small to reduce anonymous RSS / swap.
class ImageProcessingService {
  ImageProcessingService._();

  static const int maxInferenceLongEdge = 512;
  static const int maxPreviewCacheLongEdge = 384;

  static Uint8List? _previewBytes;

  static void clearPreviewCache() {
    _previewBytes = null;
  }

  static Future<File> prepareForInference(File source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return source;
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxInferenceLongEdge : null,
      height: decoded.height > decoded.width ? maxInferenceLongEdge : null,
    );

    final encoded = img.encodeJpg(resized, quality: 85);
    final imagesDir = await LocalStorageService.getImagesDirectory();
    final outPath = p.join(
      imagesDir.path,
      'infer_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded, flush: true);
    return outFile;
  }

  static Future<Uint8List> previewBytes(File source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _previewBytes = bytes;
      return bytes;
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxPreviewCacheLongEdge : null,
      height: decoded.height > decoded.width ? maxPreviewCacheLongEdge : null,
    );
    _previewBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    return _previewBytes!;
  }
}
